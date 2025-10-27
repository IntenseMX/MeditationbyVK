import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_service.dart';

class AudioUiState {
  final bool isLoading;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;
  final String? error;

  const AudioUiState({
    required this.isLoading,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.error,
  });

  AudioUiState copyWith({
    bool? isLoading,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? error,
  }) {
    return AudioUiState(
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error,
    );
  }
}

final audioHandlerProvider = Provider<AppAudioHandler>((ref) => throw UnimplementedError('audioHandlerProvider must be overridden in main.dart'));

class AudioPlayerNotifier extends Notifier<AudioUiState> {
  AppAudioHandler get _handler => ref.read(audioHandlerProvider);

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  AudioUiState build() {
    final initial = const AudioUiState(
      isLoading: false,
      isPlaying: false,
      position: Duration.zero,
      duration: null,
    );

    // Bind streams once per provider lifecycle
    _posSub = _handler.positionStream.listen((d) {
      state = state.copyWith(position: d);
    });
    _durSub = _handler.durationStream.listen((d) {
      state = state.copyWith(duration: d);
    });
    _stateSub = _handler.playerStateStream.listen((s) {
      final loading = s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering;
      state = state.copyWith(isLoading: loading, isPlaying: s.playing);
    });

    ref.onDispose(() async {
      await _posSub?.cancel();
      await _durSub?.cancel();
      await _stateSub?.cancel();
    });

    return initial;
  }

  Future<void> load({
    required String meditationId,
    required String title,
    required String audioUrl,
    String? imageUrl,
    int? durationSec,
  }) async {
    // Optimistically mark loading and clear previous errors
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _handler.loadFromMeditation(
        meditationId: meditationId,
        title: title,
        audioUrl: audioUrl,
        artUri: imageUrl,
        durationSec: durationSec,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> seek(Duration d) => _handler.seek(d);
  Future<void> stop() => _handler.stop();

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final audioPlayerProvider = NotifierProvider.autoDispose<AudioPlayerNotifier, AudioUiState>(
  AudioPlayerNotifier.new,
);


