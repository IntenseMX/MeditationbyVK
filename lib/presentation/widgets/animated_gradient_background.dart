import 'package:flutter/material.dart';
import '../../core/animation_constants.dart';

/// Animated gradient background that smoothly transitions between colors
/// Creates a calming, subtle visual effect for meditation screens
class AnimatedGradientBackground extends StatefulWidget {
  /// Colors to cycle through in the gradient animation
  final List<Color> colors;

  /// Duration for one complete animation cycle
  final Duration duration;

  /// Starting alignment for the gradient (default: topLeft)
  final AlignmentGeometry begin;

  /// Ending alignment for the gradient (default: bottomRight)
  final AlignmentGeometry end;

  /// Whether to automatically start the animation
  final bool autoPlay;

  const AnimatedGradientBackground({
    required this.colors,
    this.duration = const Duration(seconds: 8),
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.autoPlay = true,
    super.key,
  });

  @override
  State<AnimatedGradientBackground> createState() {
    assert(colors.length >= 2, 'At least 2 colors are required');
    return _AnimatedGradientBackgroundState();
  }
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentColorIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.addStatusListener(_onAnimationStatus);

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _currentColorIndex = (_currentColorIndex + 1) % widget.colors.length;
      });
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  Color _getCurrentColor() {
    return widget.colors[_currentColorIndex];
  }

  Color _getNextColor() {
    final nextIndex = (_currentColorIndex + 1) % widget.colors.length;
    return widget.colors[nextIndex];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentColor = _getCurrentColor();
        final nextColor = _getNextColor();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.begin,
              end: widget.end,
              colors: [
                Color.lerp(currentColor, nextColor, _animation.value)!
                    .withOpacity(AnimationConfig.gradientOpacity),
                Color.lerp(
                  currentColor.withOpacity(0.5),
                  nextColor.withOpacity(0.5),
                  _animation.value,
                )!.withOpacity(AnimationConfig.gradientOpacity),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Stacked animated gradients for more complex color transitions
class MultiColorAnimatedGradient extends StatefulWidget {
  /// Multiple color lists for cycling through different gradients
  final List<List<Color>> colorSchemes;

  /// Duration for each color scheme
  final Duration duration;

  /// Starting alignment
  final AlignmentGeometry begin;

  /// Ending alignment
  final AlignmentGeometry end;

  /// Whether to auto-play the animation
  final bool autoPlay;

  const MultiColorAnimatedGradient({
    required this.colorSchemes,
    this.duration = const Duration(seconds: 8),
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.autoPlay = true,
    super.key,
  });

  @override
  State<MultiColorAnimatedGradient> createState() {
    assert(colorSchemes.isNotEmpty, 'At least one color scheme is required');
    return _MultiColorAnimatedGradientState();
  }
}

class _MultiColorAnimatedGradientState extends State<MultiColorAnimatedGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _schemeIndex = 0;
  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.addStatusListener(_onAnimationStatus);

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _colorIndex += 1;
        if (_colorIndex >= widget.colorSchemes[_schemeIndex].length - 1) {
          _colorIndex = 0;
          _schemeIndex = (_schemeIndex + 1) % widget.colorSchemes.length;
        }
      });
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final colors = widget.colorSchemes[_schemeIndex];
        final from = colors[_colorIndex];
        final to = colors[(_colorIndex + 1) % colors.length];

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.begin,
              end: widget.end,
              colors: [
                Color.lerp(from, to, _animation.value)!
                    .withOpacity(AnimationConfig.gradientOpacity),
                Color.lerp(from.withOpacity(0.5), to.withOpacity(0.5), _animation.value)!
                    .withOpacity(AnimationConfig.gradientOpacity),
              ],
            ),
          ),
        );
      },
    );
  }
}
