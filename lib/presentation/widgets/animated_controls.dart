import 'package:flutter/material.dart';
import '../../core/animation_constants.dart';

/// Animated play/pause button with morphing icon and scale effect
class AnimatedPlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const AnimatedPlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
    this.size = AnimationConfig.playButtonSize,
    this.color,
    this.backgroundColor,
    super.key,
  });

  @override
  State<AnimatedPlayPauseButton> createState() =>
      _AnimatedPlayPauseButtonState();
}

class _AnimatedPlayPauseButtonState extends State<AnimatedPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AnimationDurations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: AnimationConfig.playButtonScale)
        .animate(CurvedAnimation(
          parent: _scaleController,
          curve: AnimationCurves.standardEasing,
        ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onPressed() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final bgColor = widget.backgroundColor ?? Theme.of(context).colorScheme.surface;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        iconSize: widget.size,
        onPressed: _onPressed,
        icon: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: AlwaysStoppedAnimation(widget.isPlaying ? 1.0 : 0.0),
          color: color,
        ),
        style: IconButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: color,
        ),
      ),
    );
  }
}

/// Custom animated slider with glow effect and smooth thumb animation
class AnimatedSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool enableGlow;

  const AnimatedSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.enableGlow = true,
    super.key,
  });

  @override
  State<AnimatedSlider> createState() => _AnimatedSliderState();
}

class _AnimatedSliderState extends State<AnimatedSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: AnimationDurations.normal,
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: AnimationCurves.standardEasing,
      ),
    );

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? Theme.of(context).colorScheme.surfaceVariant;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4.0,
        thumbShape: RoundSliderThumbShape(
          elevation: _isDragging ? 8.0 : 2.0,
          enabledThumbRadius: _isDragging ? 12.0 : 8.0,
        ),
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: _isDragging ? 18.0 : 12.0,
        ),
      ),
      child: Slider(
        value: widget.value.clamp(widget.min, widget.max),
        min: widget.min,
        max: widget.max,
        onChanged: widget.onChanged,
        onChangeStart: (_) => setState(() => _isDragging = true),
        onChangeEnd: (_) => setState(() => _isDragging = false),
        activeColor: activeColor,
        inactiveColor: inactiveColor.withOpacity(0.3),
      ),
    );
  }
}

/// Pulsing circular progress indicator with glow effect
class PulsingProgressIndicator extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final double size;
  final double strokeWidth;
  final bool showPulse;

  const PulsingProgressIndicator({
    required this.value,
    this.color,
    this.size = 80.0,
    this.strokeWidth = 4.0,
    this.showPulse = true,
    super.key,
  });

  @override
  State<PulsingProgressIndicator> createState() =>
      _PulsingProgressIndicatorState();
}

class _PulsingProgressIndicatorState extends State<PulsingProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: AnimationDurations.normal,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: AnimationCurves.standardEasing,
      ),
    );

    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          value: widget.value,
          strokeWidth: widget.strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          backgroundColor: color.withOpacity(0.2),
        ),
      ),
    );
  }
}

/// Animated linear progress bar with smooth fill animation
class AnimatedProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final double height;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedProgressBar({
    required this.value,
    this.color,
    this.height = 4.0,
    this.animationDuration = AnimationDurations.normal,
    this.animationCurve = AnimationCurves.standardEasing,
    super.key,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: oldWidget.value, end: widget.value).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.animationCurve,
        ),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: LinearProgressIndicator(
            value: _animation.value,
            minHeight: widget.height,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      },
    );
  }
}
