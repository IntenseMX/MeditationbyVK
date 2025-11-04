import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meditation_by_vk/core/animation_constants.dart';

/// Soft radial glow that gently breathes in size and opacity.
class BreathingGlow extends StatefulWidget {
  const BreathingGlow({
    super.key,
    required this.size,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: SplashAnimationConfig.glowPulse)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (math.sin(_controller.value * 2 * math.pi - math.pi / 2) + 1) / 2; // 0..1 sine
        final scale = 1.0 + 0.08 * t;
        final opacity = 0.35 + 0.25 * t;
        final size = widget.size * scale;
        return IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  baseColor.withOpacity(opacity),
                  baseColor.withOpacity(0.0),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}


