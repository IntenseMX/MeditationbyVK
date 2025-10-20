import 'package:flutter/material.dart';
import 'animation_constants.dart';

/// Utility class for building common animation patterns
class AnimationUtils {
  /// Staggered animation for list items
  static Widget buildStaggeredAnimation({
    required int index,
    required Widget child,
    required AnimationController controller,
    Duration staggerDelay = AnimationConfig.staggerDelay,
  }) {
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          (index * staggerDelay.inMilliseconds) / controller.duration!.inMilliseconds,
          ((index + 1) * staggerDelay.inMilliseconds) / controller.duration!.inMilliseconds,
          curve: AnimationCurves.entrance,
        ),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  /// Fade and scale animation
  static Widget fadeScaleAnimation({
    required Widget child,
    required AnimationController controller,
    double beginScale = 0.8,
    double endScale = 1.0,
  }) {
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: AnimationCurves.entrance,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation.drive(Tween<double>(begin: beginScale, end: endScale)),
        child: child,
      ),
    );
  }

  /// Bounce in animation
  static Widget bounceInAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: AnimationCurves.bounce,
        ),
      ),
      child: child,
    );
  }

  /// Slide transition (commonly used for page navigation)
  static Widget slideAnimation({
    required Widget child,
    required AnimationController controller,
    Offset begin = const Offset(1, 0),
    Offset end = Offset.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: end).animate(
        CurvedAnimation(
          parent: controller,
          curve: AnimationCurves.standardEasing,
        ),
      ),
      child: child,
    );
  }
}

/// Implicit animation wrappers for simple cases
class AnimatedGradient extends StatefulWidget {
  final List<Color> colors;
  final Duration duration;
  final Curve curve;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const AnimatedGradient({
    required this.colors,
    this.duration = const Duration(seconds: 3),
    this.curve = Curves.easeInOut,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    super.key,
  });

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Color> _colors;

  @override
  void initState() {
    super.initState();
    _colors = widget.colors;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _colors,
              begin: widget.begin,
              end: widget.end,
            ),
          ),
        );
      },
    );
  }
}
