import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/moods.dart';
import '../../domain/mood.dart';
import '../../core/theme.dart';

class MoodCarousel3D extends ConsumerStatefulWidget {
  const MoodCarousel3D({super.key});

  @override
  ConsumerState<MoodCarousel3D> createState() => _MoodCarousel3DState();
}

class _MoodCarousel3DState extends ConsumerState<MoodCarousel3D> with SingleTickerProviderStateMixin {
  // Animation & gesture constants (no magic numbers)
  static const double _perspective = 0.001;
  static const double _sideTranslateX = 120.0;
  static const double _sideTranslateZ = -100.0;
  static const double _hiddenTranslateZ = -200.0;
  static const double _sideRotateY = 0.35; // ~20°
  static const double _centerScale = 1.0;
  static const double _sideScale = 0.8;
  static const double _hiddenScale = 0.6;
  static const double _sideOpacity = 0.7;
  static const Duration _animDuration = Duration(milliseconds: 400);
  static const Curve _animCurve = Curves.easeOutCubic;
  static const double _swipeVelocityThreshold = 250.0;
  static const double _dragDistanceThreshold = 40.0;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  int _currentIndex = 0; // index of center mood
  bool _isAnimating = false;
  int _direction = 0; // -1 = left (next), +1 = right (prev), 0 = none
  double _dragDx = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animDuration);
    _animation = CurvedAnimation(parent: _controller, curve: _animCurve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moods = MoodConfig.moods;
    if (moods.isEmpty) {
      return const SizedBox.shrink();
    }

    final int leftIndex = (_currentIndex - 1 + moods.length) % moods.length;
    final int centerIndex = _currentIndex;
    final int rightIndex = (_currentIndex + 1) % moods.length;
    final int hiddenIndex = _direction == -1
        ? (_currentIndex + 2) % moods.length // entering from right on left swipe
        : _direction == 1
            ? (_currentIndex - 2 + moods.length) % moods.length // entering from left on right swipe
            : rightIndex; // default not used when not animating

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {
        _dragDx = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        if (_isAnimating) return;
        _dragDx += details.delta.dx;
        if (_dragDx.abs() >= _dragDistanceThreshold) {
          if (_dragDx < 0) {
            _swipeLeft();
          } else {
            _swipeRight();
          }
          _dragDx = 0.0;
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isAnimating) return;
        final v = details.primaryVelocity ?? 0.0;
        if (v < -_swipeVelocityThreshold) {
          _swipeLeft();
        } else if (v > _swipeVelocityThreshold) {
          _swipeRight();
        }
        _dragDx = 0.0;
      },
      child: Semantics(
        label: 'Pick Your Mood carousel',
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (_isAnimating)
              _buildAnimatedRoleCard(
                mood: moods[hiddenIndex],
                from: CardPosition.hidden,
                to: _direction == -1 ? CardPosition.right : CardPosition.left,
              ),
            _buildAnimatedRoleCard(
              mood: moods[leftIndex],
              from: CardPosition.left,
              to: _direction == -1 ? CardPosition.hidden : CardPosition.center,
            ),
            _buildAnimatedRoleCard(
              mood: moods[rightIndex],
              from: CardPosition.right,
              to: _direction == -1 ? CardPosition.center : CardPosition.hidden,
            ),
            // Center on top
            _buildAnimatedRoleCard(
              mood: moods[centerIndex],
              from: CardPosition.center,
              to: _direction == -1 ? CardPosition.left : CardPosition.right,
            ),
          ],
        ),
      ),
    );
  }

  void _swipeLeft() {
    if (_isAnimating) return;
    setState(() {
      _direction = -1;
      _isAnimating = true;
    });
    _controller.forward(from: 0.0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % MoodConfig.moods.length;
        _isAnimating = false;
        _direction = 0;
      });
    });
    HapticFeedback.mediumImpact();
  }

  void _swipeRight() {
    if (_isAnimating) return;
    setState(() {
      _direction = 1;
      _isAnimating = true;
    });
    _controller.forward(from: 0.0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex - 1 + MoodConfig.moods.length) % MoodConfig.moods.length;
        _isAnimating = false;
        _direction = 0;
      });
    });
    HapticFeedback.mediumImpact();
  }

  Widget _buildAnimatedRoleCard({
    required Mood mood,
    required CardPosition from,
    required CardPosition to,
  }) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final double t = _isAnimating ? _animation.value : 0.0;
          final _Params a = _paramsFor(from);
          final _Params b = _paramsFor(_isAnimating ? to : from);
          final _Params p = _lerpParams(a, b, t);

          final Matrix4 m = Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateY(p.rotateY)
            ..translate(p.translateX, 0.0, p.translateZ)
            ..scale(p.scale);

          return Opacity(
            opacity: p.opacity,
            child: Transform(
              alignment: Alignment.center,
              transform: m,
              child: _MoodCard(
                mood: mood,
                onTap: () => _onCardTap(from),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCardTap(CardPosition pos) {
    // Promote side cards to center; center navigates
    if (_isAnimating) return;
    final moods = MoodConfig.moods;
    final int centerIndex = _currentIndex;
    final Mood centerMood = moods[centerIndex];
    if (pos == CardPosition.center) {
      HapticFeedback.lightImpact();
      context.push('/mood/${centerMood.id}');
      return;
    }
    if (pos == CardPosition.left) {
      _swipeRight();
    } else if (pos == CardPosition.right) {
      _swipeLeft();
    }
  }

  _Params _paramsFor(CardPosition position) {
    switch (position) {
      case CardPosition.left:
        return const _Params(
          translateX: -_sideTranslateX,
          translateZ: _sideTranslateZ,
          rotateY: _sideRotateY,
          scale: _sideScale,
          opacity: _sideOpacity,
        );
      case CardPosition.center:
        return const _Params(
          translateX: 0.0,
          translateZ: 0.0,
          rotateY: 0.0,
          scale: _centerScale,
          opacity: 1.0,
        );
      case CardPosition.right:
        return const _Params(
          translateX: _sideTranslateX,
          translateZ: _sideTranslateZ,
          rotateY: -_sideRotateY,
          scale: _sideScale,
          opacity: _sideOpacity,
        );
      case CardPosition.hidden:
        return const _Params(
          translateX: 0.0,
          translateZ: _hiddenTranslateZ,
          rotateY: 0.0,
          scale: _hiddenScale,
          opacity: 0.0,
        );
    }
  }

  _Params _lerpParams(_Params a, _Params b, double t) {
    double lerp(double x, double y) => x + (y - x) * t;
    return _Params(
      translateX: lerp(a.translateX, b.translateX),
      translateZ: lerp(a.translateZ, b.translateZ),
      rotateY: lerp(a.rotateY, b.rotateY),
      scale: lerp(a.scale, b.scale),
      opacity: lerp(a.opacity, b.opacity).clamp(0.0, 1.0),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood, required this.onTap});
  final Mood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final List<Color> gradient = _colorsForMood(context, mood);
    final textOnGradient = Theme.of(context).extension<AppColors>()?.textOnGradient ?? Colors.white;
    return SizedBox(
      width: MoodConfig.cardWidth,
      height: MoodConfig.cardHeight,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              border: Border.all(color: cs.outline.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Icon(mood.icon, size: MoodConfig.iconSize, color: textOnGradient),
                  const Spacer(),
                  // Name
                  Text(
                    mood.name,
                    style: TextStyle(
                      fontSize: MoodConfig.titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: textOnGradient,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Tagline
                  Text(
                    mood.tagline,
                    style: TextStyle(
                      fontSize: MoodConfig.taglineFontSize,
                      fontWeight: FontWeight.w600,
                      color: textOnGradient.withOpacity(0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _colorsForMood(BuildContext context, Mood mood) {
    final cs = Theme.of(context).colorScheme;
    switch (mood.id) {
      case 'calm':
        // primary → tertiary
        return <Color>[cs.primary, cs.tertiary];
      case 'focus':
        // secondary → primary
        return <Color>[cs.secondary, cs.primary];
      case 'sleep':
        // tertiary → surface
        return <Color>[cs.tertiary, cs.surface];
      default:
        return <Color>[cs.primary, cs.tertiary];
    }
  }
}

enum CardPosition { hidden, left, center, right }

class _Params {
  const _Params({
    required this.translateX,
    required this.translateZ,
    required this.rotateY,
    required this.scale,
    required this.opacity,
  });
  final double translateX;
  final double translateZ;
  final double rotateY;
  final double scale;
  final double opacity;
}


