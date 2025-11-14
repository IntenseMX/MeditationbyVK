import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'progress_service.dart';

/// AppAudioHandler bridges just_audio with audio_service and Firestore resume.
class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  AppAudioHandler({
    AudioPlayer? player,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _player = player ?? AudioPlayer(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _initAudioSession();
    _initStreams();
  }

  final AudioPlayer _player;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ProgressService _progress = ProgressService();

  String? _currentMeditationId;
  String? _currentMeditationTitle;
  String? _currentMeditationImageUrl;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _completionSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  int? _playStartMsUtc; // when playback first started for current item
  bool _sessionRecorded = false; // guard to avoid duplicate writes per item
  int? _lastWrittenMinute; // last whole minute written for progressive updates
  int? _lastLoggedSecond; // last second we logged (to avoid spam)

  void _initStreams() {
    // Map just_audio state to audio_service PlaybackState
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      final processingState = const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });

    // Periodic resume writes while playing
    _positionSub = _player.positionStream.listen((pos) async {
      final id = _currentMeditationId;
      if (id == null) return;
      if (!_player.playing) return;

      // Only log when second changes (avoid spam from multiple updates per second)
      final currentSecond = pos.inSeconds;
      if (_lastLoggedSecond == null || currentSecond != _lastLoggedSecond) {
        _lastLoggedSecond = currentSecond;
        debugPrint('[AudioService] ${pos.inSeconds}s');
      }

      // Progressive minute upsert
      final dur = _player.duration;
      if (dur != null && dur.inSeconds > 0) {
        final startedMs = _playStartMsUtc;
        if (startedMs != null && !_sessionRecorded) {
          final minute = pos.inSeconds ~/ 60;
          if (_lastWrittenMinute == null || minute > _lastWrittenMinute!) {
            _lastWrittenMinute = minute;
            debugPrint('[AudioService] 📊 Minute $minute rollover - writing session update...');
            try {
              await _progress.upsertSession(
                meditationId: id,
                meditationTitle: _currentMeditationTitle,
                meditationImageUrl: _currentMeditationImageUrl,
                startedAtUtc: DateTime.fromMillisecondsSinceEpoch(startedMs, isUtc: true),
                durationSec: pos.inSeconds,
                completed: false,
              );
              debugPrint('[AudioService] ✅ Minute $minute write SUCCESS');
            } catch (e, st) {
              debugPrint('[AudioService] ❌ Minute write FAILED: $e');
              debugPrint('[AudioService] Stack: $st');
            }
          }
        }
      }
      // 80% completion threshold check while playing
      _maybeRecordSession(forceComplete: false);
    });

    // Track first playing transition and finalize on complete
    _completionSub = _player.playerStateStream.listen((state) async {
      // Capture start time on first transition to playing for current item
      if (state.playing && _playStartMsUtc == null && !_sessionRecorded) {
        _playStartMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
      }
      if (state.processingState == ProcessingState.completed) {
        // Record as completed when playback naturally completes
        _maybeRecordSession(forceComplete: true);
      }
    });
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // React to audio focus/interruptions
      _interruptionSub = session.interruptionEventStream.listen((event) async {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Temporarily lower volume during transient interruptions
              await _player.setVolume(0.3);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              await pause();
              break;
          }
        } else {
          // Interruption ended
          if (event.type == AudioInterruptionType.duck) {
            await _player.setVolume(1.0);
          }
          // Do not auto-resume to avoid surprise playback; UI can resume
        }
      });

      // Pause when audio becomes noisy (e.g., headphones unplugged)
      _becomingNoisySub = session.becomingNoisyEventStream.listen((_) async {
        await pause();
      });

      if (!kIsWeb) {
        // Ensure Android uses media/music attributes for proper focus handling
        await _player.setAndroidAudioAttributes(const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
          flags: AndroidAudioFlags.none,
        ));
      }
    } catch (e) {
      debugPrint('AudioSession init failed: $e');
    }
  }

  // Public streams for UI
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Future<Duration> get bufferedPosition async => _player.bufferedPosition;

  Future<void> loadFromMeditation({
    required String meditationId,
    required String title,
    required String audioUrl,
    String? artUri,
    int? durationSec,
  }) async {
    if (_currentMeditationId == meditationId && mediaItem.value != null) {
      return; // Already loaded
    }
    _currentMeditationId = meditationId;
    _currentMeditationTitle = title;
    _currentMeditationImageUrl = null;
    _playStartMsUtc = null;
    _sessionRecorded = false;
    _lastWrittenMinute = null;
    _lastLoggedSecond = null;
    _currentMeditationImageUrl = artUri;

    final item = MediaItem(
      id: meditationId,
      title: title,
      artUri: artUri != null && artUri.isNotEmpty ? Uri.parse(artUri) : null,
      duration: durationSec != null ? Duration(seconds: durationSec) : null,
      extras: {
        'audioUrl': audioUrl,
      },
    );
    mediaItem.add(item);

    // Normalize Storage URLs for Android/ExoPlayer compatibility
    String playableUrl = audioUrl;
    try {
      if (audioUrl.startsWith('gs://')) {
        final ref = FirebaseStorage.instance.refFromURL(audioUrl);
        playableUrl = await ref.getDownloadURL();
      } else {
        final uri = Uri.parse(audioUrl);
        if (uri.host.contains('firebasestorage')) {
          // Normalize any Firebase Storage host variants to official download URL
          try {
            final ref = FirebaseStorage.instance.refFromURL(audioUrl);
            playableUrl = await ref.getDownloadURL();
          } catch (_) {
            if (uri.host.endsWith('firebasestorage.app')) {
              // Fallback path extraction for .app URLs
              final path = uri.path; // e.g., /o/audio%2Ffile.mp3
              final oIndex = path.indexOf('/o/');
              if (oIndex != -1) {
                final encoded = path.substring(oIndex + 3);
                final endIdx = encoded.indexOf('/');
                final encodedObjectPath = endIdx == -1 ? encoded : encoded.substring(0, endIdx);
                final objectPath = Uri.decodeComponent(encodedObjectPath);
                final ref = FirebaseStorage.instance.ref().child(objectPath);
                playableUrl = await ref.getDownloadURL();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Audio URL normalization failed: $e');
    }

    try {
      debugPrint('[AudioService] Loading URL: $playableUrl');
      debugPrint('[AudioService] Original URL: $audioUrl');

      // Use cached audio source (instant if cached, stream+cache if not)
      final audioSource = await _createCachedAudioSource(
        meditationId: meditationId,
        url: playableUrl,
      );

      await _player.setAudioSource(audioSource);
      debugPrint('[AudioService] Successfully loaded! Duration: ${_player.duration}');
    } catch (e, stack) {
      // Surface error to audio_service playback state
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
      debugPrint('[AudioService] FAILED to load audio!');
      debugPrint('[AudioService] Error: $e');
      debugPrint('[AudioService] Stack: $stack');
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    debugPrint('[AudioService] play() called');
    await _player.play();
    // Capture first start timestamp (UTC) for current item
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    _playStartMsUtc ??= timestamp;
    debugPrint('[AudioService] play() set _playStartMsUtc = $_playStartMsUtc (timestamp=$timestamp)');
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    // If user stops after crossing threshold, record completion
    _maybeRecordSession(forceComplete: false);
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> fastForward() async {
    final newPos = _player.position + const Duration(seconds: 15);
    final total = _player.duration;
    if (total != null && newPos > total) {
      await _player.seek(total);
    } else {
      await _player.seek(newPos);
    }
  }

  @override
  Future<void> rewind() async {
    final newPos = _player.position - const Duration(seconds: 15);
    await _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  /// Creates cached audio source for progressive download and playback
  /// - If cached: loads from file (instant playback)
  /// - If not cached: streams from URL (immediate playback) + caches in background
  Future<AudioSource> _createCachedAudioSource({
    required String meditationId,
    required String url,
  }) async {
    if (kIsWeb) {
      // Web doesn't support file caching
      return AudioSource.uri(Uri.parse(url));
    }

    try {
      // iOS-safe: Library/Caches directory (auto-managed, no backup, no permissions)
      final cacheDir = await getApplicationCacheDirectory();
      final audioCacheDir = Directory('${cacheDir.path}/audio_cache');

      if (!await audioCacheDir.exists()) {
        await audioCacheDir.create(recursive: true);
      }

      final cacheFile = File('${audioCacheDir.path}/$meditationId.mp3');

      // Check if already cached
      if (await cacheFile.exists()) {
        debugPrint('[AudioService] 🎯 Cache HIT - loading from disk: ${cacheFile.path}');
        return AudioSource.file(cacheFile.path);
      }

      // Cache MISS - use LockCachingAudioSource for progressive download
      debugPrint('[AudioService] 💾 Cache MISS - streaming + caching: ${cacheFile.path}');
      return LockCachingAudioSource(
        Uri.parse(url),
        cacheFile: cacheFile,
      );
    } catch (e) {
      debugPrint('[AudioService] ⚠️ Cache setup failed, fallback to direct stream: $e');
      return AudioSource.uri(Uri.parse(url));
    }
  }

  void _maybeRecordSession({required bool forceComplete}) async {
    if (_sessionRecorded) return;
    final id = _currentMeditationId;
    if (id == null) return;
    final duration = _player.duration;
    if (duration == null || duration.inSeconds <= 0) return;
    final position = _player.position;
    final crossedThreshold = position.inSeconds >= (duration.inSeconds * 0.9).floor();
    final shouldComplete = forceComplete || crossedThreshold;
    if (!shouldComplete) return;

    DateTime startedAtUtc;
    if (_playStartMsUtc != null) {
      startedAtUtc = DateTime.fromMillisecondsSinceEpoch(_playStartMsUtc!, isUtc: true);
    } else {
      // Fallback: approximate by subtracting listened duration
      startedAtUtc = DateTime.now().toUtc().subtract(position);
    }
    // On completion, give full credit (use full track duration)
    final fullSec = duration.inSeconds;
    try {
      await _progress.upsertSession(
        meditationId: id,
        meditationTitle: _currentMeditationTitle,
        meditationImageUrl: _currentMeditationImageUrl,
        startedAtUtc: startedAtUtc,
        durationSec: fullSec,
        completed: true,
      );
    } catch (_) {
      // Swallow to keep audio thread safe
    } finally {
      _sessionRecorded = true;
    }
  }

  @override
  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _completionSub?.cancel();
    await _interruptionSub?.cancel();
    await _becomingNoisySub?.cancel();
    await _player.dispose();
  }
}


