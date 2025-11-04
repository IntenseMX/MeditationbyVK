import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Interactive floating particle/bubble background with parallax effect
class InteractiveParticleBackground extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double minSize;
  final double maxSize;
  final double speed;

  const InteractiveParticleBackground({
    this.particleCount = 30,
    this.particleColor = AppTheme.white,
    this.minSize = 4.0,
    this.maxSize = 20.0,
    this.speed = 1.0,
    super.key,
  });

  @override
  State<InteractiveParticleBackground> createState() =>
      _InteractiveParticleBackgroundState();
}

class _InteractiveParticleBackgroundState
    extends State<InteractiveParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  Offset? touchPosition;

  @override
  void initState() {
    super.initState();
    particles = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1), // Continuous animation
    )..repeat();

    _controller.addListener(() {
      setState(() {
        _updateParticles();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (particles.isEmpty) {
      _initParticles();
    }
  }

  void _initParticles() {
    final size = MediaQuery.of(context).size;
    final random = Random();

    particles = List.generate(widget.particleCount, (index) {
      return Particle(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        size: widget.minSize +
            random.nextDouble() * (widget.maxSize - widget.minSize),
        speedX: (random.nextDouble() - 0.5) * widget.speed,
        speedY: (random.nextDouble() - 0.5) * widget.speed * 0.5,
        opacity: 0.3 + random.nextDouble() * 0.4,
        color: widget.particleColor,
      );
    });
  }

  void _updateParticles() {
    final size = MediaQuery.of(context).size;

    for (var particle in particles) {
      // Update position
      particle.x += particle.speedX;
      particle.y += particle.speedY;

      // Interactive repulsion from touch
      if (touchPosition != null) {
        final dx = particle.x - touchPosition!.dx;
        final dy = particle.y - touchPosition!.dy;
        final distance = sqrt(dx * dx + dy * dy);

        if (distance < 150) {
          final force = (150 - distance) / 150;
          particle.x += dx * force * 0.5;
          particle.y += dy * force * 0.5;
        }
      }

      // Wrap around screen edges
      if (particle.x < -particle.size) particle.x = size.width + particle.size;
      if (particle.x > size.width + particle.size) particle.x = -particle.size;
      if (particle.y < -particle.size) particle.y = size.height + particle.size;
      if (particle.y > size.height + particle.size) particle.y = -particle.size;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          touchPosition = details.localPosition;
        });
      },
      onPanEnd: (_) {
        setState(() {
          touchPosition = null;
        });
      },
      child: CustomPaint(
        painter: ParticlePainter(particles),
        child: Container(),
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 0.5);

      // Draw glow circle
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );

      // Draw inner bright core
      final corePaint = Paint()
        ..color = particle.color.withOpacity(particle.opacity * 0.8);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * 0.5,
        corePaint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

/// Simpler floating bubbles version for better performance
class FloatingBubbles extends StatefulWidget {
  final int bubbleCount;
  final List<Color> colors;

  const FloatingBubbles({
    this.bubbleCount = 20,
    required this.colors,
    super.key,
  });

  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<FloatingBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Bubble> bubbles;

  @override
  void initState() {
    super.initState();
    bubbles = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        _updateBubbles();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bubbles.isEmpty) {
      _initBubbles();
    }
  }

  void _initBubbles() {
    final size = MediaQuery.of(context).size;
    final random = Random();

    bubbles = List.generate(widget.bubbleCount, (index) {
      return Bubble(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        radius: 20 + random.nextDouble() * 60,
        speed: 0.2 + random.nextDouble() * 0.5,
        color: widget.colors[random.nextInt(widget.colors.length)],
        phase: random.nextDouble() * 2 * pi,
      );
    });
  }

  void _updateBubbles() {
    final size = MediaQuery.of(context).size;

    for (var bubble in bubbles) {
      // Float upward with horizontal wave motion
      bubble.y -= bubble.speed;
      bubble.x += sin(bubble.y * 0.01 + bubble.phase) * 0.5;

      // Reset to bottom when reaching top
      if (bubble.y < -bubble.radius) {
        bubble.y = size.height + bubble.radius;
        bubble.x = Random().nextDouble() * size.width;
      }

      // Keep within horizontal bounds
      if (bubble.x < -bubble.radius) bubble.x = size.width + bubble.radius;
      if (bubble.x > size.width + bubble.radius) bubble.x = -bubble.radius;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BubblePainter(bubbles),
      child: Container(),
    );
  }
}

class Bubble {
  double x;
  double y;
  double radius;
  double speed;
  Color color;
  double phase;

  Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.color,
    required this.phase,
  });
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;

  BubblePainter(this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      // Outer glow
      final glowPaint = Paint()
        ..color = bubble.color.withOpacity(0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, bubble.radius * 0.3);

      canvas.drawCircle(
        Offset(bubble.x, bubble.y),
        bubble.radius,
        glowPaint,
      );

      // Bubble circle with gradient effect
      final bubblePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            bubble.color.withOpacity(0.15),
            bubble.color.withOpacity(0.05),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(bubble.x, bubble.y),
          radius: bubble.radius,
        ));

      canvas.drawCircle(
        Offset(bubble.x, bubble.y),
        bubble.radius,
        bubblePaint,
      );

      // Highlight for 3D effect
      final highlightPaint = Paint()
        ..color = bubble.color.withOpacity(0.3);

      canvas.drawCircle(
        Offset(bubble.x - bubble.radius * 0.3, bubble.y - bubble.radius * 0.3),
        bubble.radius * 0.3,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) => true;
}
