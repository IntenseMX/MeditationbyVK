import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meditation_by_vk/core/animation_constants.dart';
import 'package:meditation_by_vk/core/theme.dart';

/// A soothing animated background with a slow-shifting gradient,
/// subtle parallax blobs, and sparse drifting particles.
class ZenBackground extends StatefulWidget {
  const ZenBackground({super.key});

  @override
  State<ZenBackground> createState() => _ZenBackgroundState();
}

class _ZenBackgroundState extends State<ZenBackground> with TickerProviderStateMixin {
  late final AnimationController _gradientController;
  late final AnimationController _parallaxController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(vsync: this, duration: SplashAnimationConfig.gradientCycle)
      ..repeat();
    _parallaxController = AnimationController(vsync: this, duration: SplashAnimationConfig.parallaxPeriod)
      ..repeat();
    _particleController = AnimationController(vsync: this, duration: SplashAnimationConfig.particleDriftPeriod)
      ..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _parallaxController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    final colorScheme = Theme.of(context).colorScheme;
    final primary = appColors?.pop ?? colorScheme.primary;
    final secondary = colorScheme.secondary;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _gradientController,
          _parallaxController,
          _particleController,
        ]),
        builder: (context, _) {
          final t = _gradientController.value;

          // Create two softly shifted colors derived from theme
          Color shift(Color base, double hueDelta, double lightnessDelta) {
            final hsl = HSLColor.fromColor(base);
            final shifted = hsl.withHue((hsl.hue + hueDelta) % 360).withLightness(
              (hsl.lightness + lightnessDelta).clamp(0.0, 1.0),
            );
            return shifted.toColor();
          }

          final c1 = Color.lerp(primary, shift(primary, 12, 0.05), math.sin(t * 2 * math.pi) * 0.5 + 0.5)!;
          final c2 = Color.lerp(secondary, shift(secondary, -8, -0.03), math.cos(t * 2 * math.pi) * 0.5 + 0.5)!;

          return CustomPaint(
            painter: _ZenPainter(
              gradientColors: [
                c1.withOpacity(0.9),
                c2.withOpacity(0.9),
              ],
              parallaxT: _parallaxController.value,
              particleT: _particleController.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ZenPainter extends CustomPainter {
  _ZenPainter({
    required this.gradientColors,
    required this.parallaxT,
    required this.particleT,
  });

  final List<Color> gradientColors;
  final double parallaxT;
  final double particleT;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGradient(canvas, size);
    _paintParallaxBlobs(canvas, size);
    _paintParticles(canvas, size);
  }

  void _paintGradient(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintParallaxBlobs(Canvas canvas, Size size) {
    final blobPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    final blobs = [
      _BlobSpec(scale: 0.6, dx: 0.2, dy: 0.25, colorIndex: 0, alpha: 0.18),
      _BlobSpec(scale: 0.8, dx: 0.7, dy: 0.7, colorIndex: 1, alpha: 0.16),
      _BlobSpec(scale: 0.5, dx: 0.85, dy: 0.2, colorIndex: 0, alpha: 0.12),
    ];

    for (final blob in blobs) {
      final baseCenter = Offset(size.width * blob.dx, size.height * blob.dy);
      final dx = math.sin(parallaxT * 2 * math.pi + blob.dx) * 20 * blob.scale;
      final dy = math.cos(parallaxT * 2 * math.pi + blob.dy) * 16 * blob.scale;
      final center = baseCenter.translate(dx, dy);

      final color = Color.lerp(gradientColors[blob.colorIndex], Colors.white, 0.05)!;
      blobPaint.color = color.withOpacity(blob.alpha);
      canvas.drawCircle(center, size.shortestSide * 0.25 * blob.scale, blobPaint);
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    final rnd = math.Random(42); // deterministic
    final paint = Paint();
    for (int i = 0; i < SplashAnimationConfig.particleCount; i++) {
      final seed = rnd.nextDouble() * 1000.0;
      final baseX = rnd.nextDouble();
      final baseY = rnd.nextDouble();
      final sizeFrac = rnd.nextDouble();

      final driftX = math.sin((particleT * 2 * math.pi) + seed) * SplashAnimationConfig.particleMaxOffset;
      final driftY = math.cos((particleT * 2 * math.pi) + seed) * SplashAnimationConfig.particleMaxOffset * 0.6;

      final x = (baseX + driftX).clamp(0.0, 1.0) * size.width;
      final y = (baseY + driftY).clamp(0.0, 1.0) * size.height;
      final r = lerpDouble(SplashAnimationConfig.particleMinSize, SplashAnimationConfig.particleMaxSize, sizeFrac)!;
      final a = SplashAnimationConfig.particleBaseOpacity * (0.6 + 0.4 * math.sin(seed + particleT * 2 * math.pi)).abs();

      paint.color = Colors.white.withOpacity(a);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ZenPainter oldDelegate) {
    return oldDelegate.gradientColors != gradientColors ||
        oldDelegate.parallaxT != parallaxT ||
        oldDelegate.particleT != particleT;
  }
}

class _BlobSpec {
  const _BlobSpec({
    required this.scale,
    required this.dx,
    required this.dy,
    required this.colorIndex,
    required this.alpha,
  });

  final double scale;
  final double dx;
  final double dy;
  final int colorIndex;
  final double alpha;
}


