import 'package:flutter/material.dart';
import '../../core/animation_constants.dart';

/// Animated breathing circle for meditation visualization
/// Expands and contracts to guide breathing exercises
class BreathingCircle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration breatheInDuration;
  final Duration holdDuration;
  final Duration breatheOutDuration;
  final bool autoPlay;

  const BreathingCircle({
    this.size = AnimationConfig.breathingCircleBaseSize,
    required this.color,
    this.breatheInDuration = AnimationDurations.breatheIn,
    this.holdDuration = AnimationDurations.hold,
    this.breatheOutDuration = AnimationDurations.breatheOut,
    this.autoPlay = true,
    super.key,
  });

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    // Total cycle time: breathe in + hold + breathe out
    final totalDuration = widget.breatheInDuration.inMilliseconds +
        widget.holdDuration.inMilliseconds +
        widget.breatheOutDuration.inMilliseconds;

    _controller = AnimationController(
      duration: Duration(milliseconds: totalDuration),
      vsync: this,
    );

    // Calculate intervals for each phase
    final breatheInEnd =
        widget.breatheInDuration.inMilliseconds / totalDuration;
    final holdEnd = (widget.breatheInDuration.inMilliseconds +
            widget.holdDuration.inMilliseconds) /
        totalDuration;

    _breathingAnimation = Tween<double>(
      begin: AnimationConfig.breathingCircleMinScale,
      end: AnimationConfig.breathingCircleMaxScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0,
          breatheInEnd,
          curve: Curves.easeInOut,
        ),
      ),
    );

    // Create exhale animation for the last part
    _breathingAnimation = TweenSequence<double>([
      // Breathe in: scale up
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: AnimationConfig.breathingCircleMinScale,
          end: AnimationConfig.breathingCircleMaxScale,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: breatheInEnd * 100,
      ),
      // Hold: stay at max scale
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: AnimationConfig.breathingCircleMaxScale,
          end: AnimationConfig.breathingCircleMaxScale,
        ),
        weight: (holdEnd - breatheInEnd) * 100,
      ),
      // Breathe out: scale down
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: AnimationConfig.breathingCircleMaxScale,
          end: AnimationConfig.breathingCircleMinScale,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: (1 - holdEnd) * 100,
      ),
    ]).animate(_controller);

    if (widget.autoPlay) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ripple 1
            Transform.scale(
              scale: _breathingAnimation.value * 1.5,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.1 * (1 - (_breathingAnimation.value - 0.8).abs())),
                ),
              ),
            ),
            // Outer ripple 2
            Transform.scale(
              scale: _breathingAnimation.value * 1.3,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.2 * (1 - (_breathingAnimation.value - 0.8).abs())),
                ),
              ),
            ),
            // Main breathing circle
            ScaleTransition(
              scale: _breathingAnimation,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withOpacity(0.9),
                      widget.color.withOpacity(0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.6),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            // Inner glow
            ScaleTransition(
              scale: _breathingAnimation,
              child: Container(
                width: widget.size * 0.5,
                height: widget.size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Breathing circle with text guidance
class BreathingCircleWithText extends StatefulWidget {
  final double size;
  final Color color;
  final Duration breatheInDuration;
  final Duration holdDuration;
  final Duration breatheOutDuration;
  final TextStyle textStyle;
  final bool autoPlay;

  const BreathingCircleWithText({
    this.size = 150,
    required this.color,
    this.breatheInDuration = AnimationDurations.breatheIn,
    this.holdDuration = AnimationDurations.hold,
    this.breatheOutDuration = AnimationDurations.breatheOut,
    required this.textStyle,
    this.autoPlay = true,
    super.key,
  });

  @override
  State<BreathingCircleWithText> createState() =>
      _BreathingCircleWithTextState();
}

class _BreathingCircleWithTextState extends State<BreathingCircleWithText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _breathingText = 'Breathe In';

  @override
  void initState() {
    super.initState();

    final totalDuration = widget.breatheInDuration.inMilliseconds +
        widget.holdDuration.inMilliseconds +
        widget.breatheOutDuration.inMilliseconds;

    _controller = AnimationController(
      duration: Duration(milliseconds: totalDuration),
      vsync: this,
    );

    _updateBreathingText();

    if (widget.autoPlay) {
      _controller.repeat();
    }
  }

  void _updateBreathingText() {
    _controller.addListener(() {
      final breatheInEnd = widget.breatheInDuration.inMilliseconds /
          (_controller.duration!.inMilliseconds);
      final holdEnd = (widget.breatheInDuration.inMilliseconds +
              widget.holdDuration.inMilliseconds) /
          (_controller.duration!.inMilliseconds);

      setState(() {
        if (_controller.value < breatheInEnd) {
          _breathingText = 'Breathe In';
        } else if (_controller.value < holdEnd) {
          _breathingText = 'Hold';
        } else {
          _breathingText = 'Breathe Out';
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BreathingCircle(
      size: widget.size,
      color: widget.color,
      breatheInDuration: widget.breatheInDuration,
      holdDuration: widget.holdDuration,
      breatheOutDuration: widget.breatheOutDuration,
      autoPlay: false,
    );
  }
}
