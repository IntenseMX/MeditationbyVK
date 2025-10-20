import 'package:flutter/material.dart';
import '../../core/animation_constants.dart';
import '../../data/datasources/dummy_data.dart';
import '../widgets/animated_controls.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/breathing_circle.dart';
import '../widgets/interactive_particle_background.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.meditationId});
  final String meditationId;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  double positionSeconds = 0;
  late AnimationController _imageAnimationController;
  late Animation<double> _imageScaleAnimation;

  Map<String, dynamic>? get _meditation {
    try {
      return DummyData.meditations.firstWhere(
        (m) => m['id'] == widget.meditationId,
      );
    } catch (_) {
      return null;
    }
  }

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
    final meditation = _meditation;
    if (meditation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('Meditation not found')),
      );
    }

    final String title = meditation['title'] as String;
    final String subtitle = meditation['subtitle'] as String;
    final int durationMin = meditation['duration'] as int;
    final String imageUrl = meditation['imageUrl'] as String;
    final List<dynamic> categories = meditation['categories'] as List<dynamic>? ?? [];

    final double totalSeconds = (durationMin * 60).toDouble().clamp(60, 3600);
    final progressValue = totalSeconds > 0 ? positionSeconds / totalSeconds : 0.0;

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
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
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
              // Categories
              if (categories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: categories.take(3).map((cat) {
                    return Chip(
                      label: Text(cat.toString()),
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),
              // Breathing circle visualization
              Center(
                child: BreathingCircle(
                  size: 150,
                  color: colorScheme.primary,
                  autoPlay: isPlaying,
                ),
              ),
              const SizedBox(height: 48),
              // Animated play/pause button
              Center(
                child: AnimatedPlayPauseButton(
                  isPlaying: isPlaying,
                  onPressed: () {
                    setState(() => isPlaying = !isPlaying);
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
                  setState(() => positionSeconds = value);
                },
                activeColor: colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _format(double seconds) {
    final total = seconds.round();
    final m = (total ~/ 60).toString().padLeft(1, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}


