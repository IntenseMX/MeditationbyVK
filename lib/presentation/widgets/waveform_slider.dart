import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/animation_constants.dart';

/// Custom waveform progress bar with draggable handle
/// Simulates audio waveform visualization with vertical bars
class WaveformSlider extends StatefulWidget {
  final double value; // Current position (0.0 to 1.0)
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final int barCount;

  const WaveformSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
    this.barCount = AnimationConfig.waveformBarCount,
    super.key,
  });

  @override
  State<WaveformSlider> createState() => _WaveformSliderState();
}

class _WaveformSliderState extends State<WaveformSlider> {
  late List<double> _barHeights;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _barHeights = _generateBars();
  }

  List<double> _generateBars() {
    return List.generate(widget.barCount, (index) {
      // Create wave-like pattern with some randomness
      final wave = math.sin(index * 0.3) * 0.5 + 0.5; // Base wave pattern
      final randomness = (index % 3) * 0.1; // Add variation
      final height = 5 + (wave * 25) + (randomness * 20);
      return height.clamp(5.0, 40.0); // Clamp between 5-40px
    });
  }

  double _getNormalizedValue(double position, double width) {
    final value = (position / width) * (widget.max - widget.min) + widget.min;
    return value.clamp(widget.min, widget.max);
  }

  void _handleDragUpdate(Offset localPosition, double width) {
    final newValue = _getNormalizedValue(localPosition.dx, width);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        setState(() => _isDragging = true);
        _handleDragUpdate(details.localPosition, context.size?.width ?? 1.0);
      },
      onHorizontalDragUpdate: (details) {
        _handleDragUpdate(details.localPosition, context.size?.width ?? 1.0);
      },
      onHorizontalDragEnd: (_) {
        setState(() => _isDragging = false);
      },
      onTapDown: (details) {
        _handleDragUpdate(details.localPosition, context.size?.width ?? 1.0);
      },
      child: Container(
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Waveform bars
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(widget.barCount, (index) {
                final barWidth = AnimationConfig.waveformBarWidth;
                final barHeight = _barHeights[index];
                // Bar should be active if progress has passed its center position
                final barProgress = (index + 0.5) / widget.barCount;
                final currentProgress = (widget.value - widget.min) / (widget.max - widget.min);

                final isActive = barProgress <= currentProgress;
                final color = isActive ? widget.activeColor : widget.inactiveColor;
                
                return AnimatedContainer(
                  duration: AnimationConfig.waveformTransition,
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(barWidth / 2),
                    color: color,
                  ),
                );
              }),
              ),
            ),

            // Draggable handle
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final normalizedValue = (widget.value - widget.min) / (widget.max - widget.min);
                final handleSize = 24.0;
                final barPadding = 12.0;

                // Account for the 12px padding on the waveform bars
                // Center the bubble on the progress point
                final effectiveWidth = width - (2 * barPadding);
                final centerPosition = barPadding + (normalizedValue * effectiveWidth);
                final handlePosition = centerPosition - (handleSize / 2);

                return Stack(
                  children: [
                    Positioned(
                      left: handlePosition.clamp(0.0, width - handleSize),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.activeColor,
                          boxShadow: [
                            BoxShadow(
                              color: widget.activeColor.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isDragging
                            ? Icon(Icons.grain, size: 12, color: Colors.white)
                            : Container(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Simplified version for use in lists or compact layouts
class MiniWaveform extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color activeColor;
  final Color inactiveColor;
  final int barCount;

  const MiniWaveform({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.barCount = 30,
    super.key,
  });

  List<double> _generateBars() {
    return List.generate(barCount, (index) {
      final wave = math.sin(index * 0.4) * 0.5 + 0.5;
      return 3 + wave * 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    final barHeights = _generateBars();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (index) {
        final barProgress = (index + 1) / barCount;
        final isActive = barProgress <= progress;
        final color = isActive ? activeColor : inactiveColor;
        
        return Container(
          width: 2,
          height: barHeights[index],
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: color,
          ),
        );
      }),
    );
  }
}
