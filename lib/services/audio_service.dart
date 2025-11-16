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
import 'package:shared_preferences/shared_preferences.dart';
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
  int _accumulatedSeconds = 0; // total time from previous completed loops
  int? _lastWrittenDuration; // last duration written to Firestore (non-decreasing guard)
  int? _lastWrittenMinute; // last whole minute written for progressive updates
  int? _lastLoggedSecond; // last second we logged (to avoid spam)
  int? _singleTrackDurationSec; // source duration in seconds (if known)
  bool _finalized = false; // ensure we only finalize once

  String? get _uid => _auth.currentUser?.uid;
  String get _baselineKey => 'audio_session_baseline_${_uid ?? "anon"}_${_currentMeditationId ?? "none"}';

  Future<void> _loadBaseline() async {
    if (_uid == null || _currentMeditationId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_baselineKey);
      if (raw == null || raw.isEmpty) return;
      final parts = raw.split('|');
      if (parts.length < 3) return;
      final startedAtMs = int.tryParse(parts[0]);
      final acc = int.tryParse(parts[1]);
      final lastDur = int.tryParse(parts[2]);
      if (startedAtMs != null && startedAtMs > 0) {
        _playStartMsUtc = startedAtMs;
      }
      if (acc != null && acc >= 0) _accumulatedSeconds = acc;
      if (lastDur != null && lastDur >= 0) _lastWrittenDuration = lastDur;
      debugPrint('[AudioService] 🔁 Baseline loaded: start=$_playStartMsUtc acc=$_accumulatedSeconds last=$_lastWrittenDuration');
    } catch (e) {
      debugPrint('[AudioService] Baseline load failed: $e');
    }
  }

  Future<void> _saveBaseline() async {
    if (_uid == null || _currentMeditationId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final started = _playStartMsUtc ?? 0;
      final acc = _accumulatedSeconds;
      final lastDur = _lastWrittenDuration ?? 0;
      await prefs.setString(_baselineKey, '$started|$acc|$lastDur');
      debugPrint('[AudioService] 💾 Baseline saved: start=$started acc=$acc last=$lastDur');
    } catch (e) {
      debugPrint('[AudioService] Baseline save failed: $e');
    }
  }

  Future<void> _clearBaseline() async {
    if (_uid == null || _currentMeditationId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_baselineKey);
      debugPrint('[AudioService] 🧹 Baseline cleared for key=$_baselineKey');
    } catch (e) {
      debugPrint('[AudioService] Baseline clear failed: $e');
    }
  }

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
      if (_finalized) return;

      // Only log when second changes (avoid spam from multiple updates per second)
      final currentSecond = pos.inSeconds;
      if (_lastLoggedSecond == null || currentSecond != _lastLoggedSecond) {
        _lastLoggedSecond = currentSecond;
        debugPrint('[AudioService] ${pos.inSeconds}s');

        // DIAGNOSTIC: Log state every 10 seconds to debug why writes aren't happening
        if (currentSecond % 10 == 0) {
          final dur = _player.duration;
          debugPrint('[AudioService] 🔍 DIAGNOSTIC at ${currentSecond}s:');
          debugPrint('  - duration: ${dur?.inSeconds} sec');
          debugPrint('  - _playStartMsUtc: $_playStartMsUtc');
          debugPrint('  - _accumulatedSeconds: $_accumulatedSeconds');
          debugPrint('  - _lastWrittenMinute: $_lastWrittenMinute');
          debugPrint('  - _uid: $_uid');
          debugPrint('  - _currentMeditationId: $_currentMeditationId');
        }
      }

      // Progressive minute upsert
      final dur = _player.duration;
      if (dur != null && dur.inSeconds > 0) {
        // Keep a copy of single track duration when known
        _singleTrackDurationSec ??= dur.inSeconds;
        final startedMs = _playStartMsUtc;
        if (startedMs != null) {
          final minute = pos.inSeconds ~/ 60;
          if (_lastWrittenMinute == null || minute > _lastWrittenMinute!) {
            _lastWrittenMinute = minute;
            debugPrint('[AudioService] 📊 Minute $minute rollover - writing session update...');
            try {
              // Absolute, non-decreasing duration
              final computed = _accumulatedSeconds + pos.inSeconds;
              final toWrite = _lastWrittenDuration == null ? computed : (computed > _lastWrittenDuration! ? computed : _lastWrittenDuration!);
              await _progress.upsertSession(
                meditationId: id,
                meditationTitle: _currentMeditationTitle,
                meditationImageUrl: _currentMeditationImageUrl,
                startedAtUtc: DateTime.fromMillisecondsSinceEpoch(startedMs, isUtc: true),
                durationSec: toWrite,
                completed: false,
              );
              debugPrint('[AudioService] ✅ Minute $minute write SUCCESS');
              _lastWrittenDuration = toWrite;
              await _saveBaseline();
            } catch (e, st) {
              debugPrint('[AudioService] ❌ Minute write FAILED: $e');
              debugPrint('[AudioService] Stack: $st');
            }
          }
        } else {
          // DIAGNOSTIC: startedMs is null
          if (currentSecond % 30 == 0) {
            debugPrint('[AudioService] ⚠️ BLOCKED: _playStartMsUtc is NULL (session not started)');
          }
        }
      } else {
        // DIAGNOSTIC: duration is null or 0
        if (currentSecond % 30 == 0) {
          debugPrint('[AudioService] ⚠️ BLOCKED: duration is NULL or 0 (dur=$dur)');
        }
      }
    });

    // Track first playing transition and finalize on complete
    _completionSub = _player.playerStateStream.listen((state) async {
      // Capture start time on first transition to playing for current item
      if (state.playing && _playStartMsUtc == null && !_finalized) {
        _playStartMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
        await _saveBaseline();
      }
      // Do not auto-finalize on ProcessingState.completed; UI will either loop or finalize.
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
    _lastWrittenMinute = null;
    _lastLoggedSecond = null;
    _currentMeditationImageUrl = artUri;
    _accumulatedSeconds = 0;
    _lastWrittenDuration = null;
    _finalized = false;
    _singleTrackDurationSec = durationSec;

    // Try to rehydrate previous baseline (if any) for this meditation
    await _loadBaseline();

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
      // Update track duration when known
      _singleTrackDurationSec ??= _player.duration?.inSeconds;
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
    if (_playStartMsUtc == null) {
      _playStartMsUtc = timestamp;
      await _saveBaseline();
      debugPrint('[AudioService] play() set _playStartMsUtc = $_playStartMsUtc (timestamp=$timestamp)');
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    // Finalize on explicit stop
    await finalizeSession();
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

  // Public API: called by UI when a loop restarts
  Future<void> onLoopRestart() async {
    final single = _singleTrackDurationSec ?? _player.duration?.inSeconds;
    if (single == null || single <= 0) return;
    _accumulatedSeconds += single;
    _lastWrittenMinute = null;  // Reset minute guard for new loop
    debugPrint('[AudioService] 🔁 Loop restart: +$single s → accumulated=$_accumulatedSeconds (minute guard reset)');
    await _saveBaseline();
  }

  // Public API: finalize the session (stop/exit or non-loop completion)
  Future<void> finalizeSession() async {
    if (_finalized) return;
    final id = _currentMeditationId;
    final startedMs = _playStartMsUtc;
    if (id == null || startedMs == null) {
      debugPrint('[AudioService] finalizeSession skipped (missing id or start)');
      return;
    }
    final pos = _player.position.inSeconds;
    final total = _accumulatedSeconds + (pos < 0 ? 0 : pos);
    final singleSec = _singleTrackDurationSec ?? _player.duration?.inSeconds ?? 0;
    final threshold = (singleSec * 0.9).floor();
    final crossed = singleSec > 0 && total >= threshold;
    final toWrite = _lastWrittenDuration == null ? total : (total > _lastWrittenDuration! ? total : _lastWrittenDuration!);
    try {
      debugPrint('[AudioService] 🧾 Finalize: total=$total single=$singleSec crossed=$crossed write=$toWrite');
      await _progress.upsertSession(
        meditationId: id,
        meditationTitle: _currentMeditationTitle,
        meditationImageUrl: _currentMeditationImageUrl,
        startedAtUtc: DateTime.fromMillisecondsSinceEpoch(startedMs, isUtc: true),
        durationSec: toWrite,
        completed: crossed,
      );
      _lastWrittenDuration = toWrite;
      _finalized = true;
      _currentMeditationId = null;  // Clear ID so next load isn't blocked
      await _clearBaseline();
    } catch (e) {
      debugPrint('[AudioService] Finalize failed: $e');
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


