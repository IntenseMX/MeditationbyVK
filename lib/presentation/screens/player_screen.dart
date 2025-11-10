import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animation_constants.dart';
import '../../providers/meditations_list_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/category_provider.dart';
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
  // Layout sizing constants
  static const double _breathingSectionHeight = 220.0;
  static const double _breathingCircleSize = 180.0;
  static const double _playButtonSize = 80.0;

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
    // Categories lookup for resolving categoryId → category name
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final catList = categoriesAsync.asData?.value;
    final Map<String, String> categoryIdToName = {
      if (catList != null) ...{
        for (final c in catList) c.id: c.name,
      }
    };
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
        final bool isPremium = (data['isPremium'] == true);

        // Subscription gate: prevent loading/playing premium if user not subscribed
        final sub = ref.watch(subscriptionProvider);
        if (isPremium && !sub.isPremium) {
          // Defer navigation to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Premium content. Upgrade to continue.')),
              );
              context.push('/paywall');
            }
          });
          return Scaffold(
            appBar: AppBar(title: const Text('Player')),
            body: const Center(child: Text('Premium content locked')),
            backgroundColor: Colors.transparent,
          );
        }

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

        final double totalSeconds =
            (audioState.duration ?? Duration(seconds: durationSec)).inSeconds.toDouble();
        final double positionSeconds = audioState.position.inSeconds.toDouble().clamp(0, totalSeconds);

    // Get theme colors for gradient
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

        final heroTag = 'meditation_${widget.meditationId}';

        return WillPopScope(
          onWillPop: () async {
            // Pause playback when leaving the player via back navigation
            ref.read(audioPlayerProvider.notifier).pause();
            return true;
          },
          child: Stack(
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
                  label: Text(_resolveCategoryName(categoryId, categoryIdToName)),
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                ),
              const SizedBox(height: 24),
              // Breathing circle behind play button
              SizedBox(
                height: _breathingSectionHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    BreathingCircle(
                      size: _breathingCircleSize,
                      color: colorScheme.primary,
                      autoPlay: audioState.isPlaying,
                    ),
                    AnimatedPlayPauseButton(
                      isPlaying: audioState.isPlaying,
                      onPressed: () {
                        final ctrl = ref.read(audioPlayerProvider.notifier);
                        if (audioState.isPlaying) {
                          ctrl.pause();
                        } else {
                          ctrl.play();
                        }
                      },
                      size: _playButtonSize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                  child: Text(_format(totalSeconds)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Animated slider
              AnimatedSlider(
                value: positionSeconds.clamp(0, totalSeconds),
                min: 0,
                max: totalSeconds,
                onChanged: (value) {
                  ref.read(audioPlayerProvider.notifier).seek(Duration(seconds: value.round()));
                },
                activeColor: colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
          ),
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

  String _resolveCategoryName(String? categoryId, Map<String, String> idToName) {
    if (categoryId == null || categoryId.trim().isEmpty) return 'General';
    final byName = idToName[categoryId];
    if (byName != null && byName.trim().isNotEmpty) return byName;
    return _prettyCategory(categoryId);
  }

  String _prettyCategory(String input) {
    final s = input.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return s.split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }
}


