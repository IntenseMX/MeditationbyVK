import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animation_constants.dart';
import '../../providers/meditations_list_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../widgets/animated_controls.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/breathing_circle.dart';
import '../widgets/interactive_particle_background.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.meditationId});
  final String meditationId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  String? _loadedMeditationId;
  late AnimationController _imageAnimationController;
  late Animation<double> _imageScaleAnimation;

  @override
  void initState() {
    super.initState();
    _imageAnimationController = AnimationController(
      duration: AnimationDurations.normal,
      vsync: this,
    );

    _imageScaleAnimation =
        Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageAnimationController,
        curve: AnimationCurves.entrance,
      ),
    );

    _imageAnimationController.forward();
  }

  @override
  void dispose() {
    _imageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meditationAsync = ref.watch(meditationByIdProvider(widget.meditationId));
    final audioState = ref.watch(audioPlayerProvider);
    return meditationAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('Failed to load')),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Player')),
            body: const Center(child: Text('Meditation not found')),
          );
        }

        final String title = (data['title'] as String?) ?? '';
        final String subtitle = (data['description'] as String?) ?? '';
        final int durationSec = (data['durationSec'] as int?) ?? 300;
        final String imageUrl = (data['imageUrl'] as String?) ?? '';
        final String audioUrl = (data['audioUrl'] as String?) ?? '';
        final String? categoryId = data['categoryId'] as String?;

        // Lazy-load audio when data is ready
        if (_loadedMeditationId != widget.meditationId && audioUrl.isNotEmpty) {
          _loadedMeditationId = widget.meditationId;
          // Defer to next frame to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(audioPlayerProvider.notifier).load(
                  meditationId: widget.meditationId,
                  title: title,
                  audioUrl: audioUrl,
                  imageUrl: imageUrl,
                  durationSec: durationSec,
                );
          });
        }

        final double totalSeconds = (audioState.duration?.inSeconds ?? 0).toDouble();
        final double positionSeconds = totalSeconds > 0
            ? audioState.position.inSeconds.toDouble().clamp(0, totalSeconds)
            : 0.0;

    // Get theme colors for gradient
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

        final heroTag = 'meditation_$title';

        return Stack(
          children: [
        // Animated gradient background
        Positioned.fill(
          child: AnimatedGradientBackground(
            colors: gradientColors,
            duration: const Duration(seconds: 12),
          ),
        ),
        // Interactive floating bubbles
        Positioned.fill(
          child: FloatingBubbles(
            bubbleCount: 25,
            colors: gradientColors,
          ),
        ),
        // Main content
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (audioState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Playback error: ${audioState.error}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Hero animated image
              Hero(
                tag: heroTag,
                child: Material(
                  color: Colors.transparent,
                  child: ScaleTransition(
                    scale: _imageScaleAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : Container(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title and subtitle
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: 12),
              // Category (simple title-cased id for Phase 2)
              if (categoryId != null && categoryId.isNotEmpty)
                Chip(
                  label: Text(_prettyCategory(categoryId)),
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                ),
              const SizedBox(height: 32),
              // Breathing circle visualization
              Center(
                child: BreathingCircle(
                  size: 150,
                  color: colorScheme.primary,
                  autoPlay: audioState.isPlaying,
                ),
              ),
              const SizedBox(height: 48),
              // Animated play/pause button
              Center(
                child: AnimatedPlayPauseButton(
                  isPlaying: audioState.isPlaying,
                  onPressed: () {
                    final ctrl = ref.read(audioPlayerProvider.notifier);
                    if (audioState.isPlaying) {
                      ctrl.pause();
                    } else {
                      ctrl.play();
                    }
                  },
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),
              // Time display with animation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: AnimationDurations.fast,
                    style: Theme.of(context)
                        .textTheme.bodyMedium!
                        .copyWith(
                          color: colorScheme.onBackground,
                          fontWeight: FontWeight.w500,
                        ),
                  child: Text(_format(positionSeconds)),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: AnimationDurations.fast,
                    style: Theme.of(context)
                        .textTheme.bodyMedium!
                        .copyWith(
                          color: colorScheme.onBackground.withOpacity(0.6),
                        ),
                    child: Text(totalSeconds > 0 ? _format(totalSeconds) : '--:--'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Animated slider
              AnimatedSlider(
                value: positionSeconds,
                min: 0,
                max: totalSeconds > 0 ? totalSeconds : 1.0,
                onChanged: (value) {
                  if (totalSeconds > 0) {
                    ref.read(audioPlayerProvider.notifier).seek(Duration(seconds: value.round()));
                  }
                },
                activeColor: colorScheme.primary,
              ),
              if (audioState.isLoading && totalSeconds == 0) ...[
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
        );
      },
    );
  }

  String _format(double seconds) {
    final total = seconds.round();
    final m = (total ~/ 60).toString().padLeft(1, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _prettyCategory(String input) {
    final s = input.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return s.split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }
}


