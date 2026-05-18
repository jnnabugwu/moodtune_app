import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// An animated waveform composed of [barCount] vertical bars.
///
/// Each bar's height is driven by a sine function with a unique phase offset,
/// creating a natural staggered pulse effect. All bars are controlled by a
/// single [AnimationController], keeping resource usage minimal.
///
/// Set [isAnimating] to `false` to stop the animation (e.g. when
/// [MediaQueryData.disableAnimations] is true or the screen is idle).
class AnimatedWaveform extends StatefulWidget {
  const AnimatedWaveform({
    required this.color,
    super.key,
    this.isAnimating = true,
    this.barCount = 7,
    this.width = 56,
    this.height = 40,
  });

  final Color color;
  final bool isAnimating;
  final int barCount;
  final double width;
  final double height;

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase offsets distributed evenly across [0, 2π] for a staggered look.
  static const List<double> _phases = [
    0.00,
    0.14,
    0.28,
    0.42,
    0.57,
    0.71,
    0.85,
  ];

  // Individual peak heights give each bar a distinct personality.
  static const List<double> _maxHeights = [
    0.50,
    0.80,
    1.00,
    0.70,
    0.90,
    0.60,
    0.75,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isAnimating) _controller.repeat();
  }

  @override
  void didUpdateWidget(AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnimating == widget.isAnimating) return;
    if (widget.isAnimating) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gap between bars is 4 logical pixels.
    const gap = 4.0;
    final barWidth =
        (widget.width - gap * (widget.barCount - 1)) / widget.barCount;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0 → 1 looping

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              final phase = _phases[i] * 2 * math.pi;
              final sinValue =
                  (math.sin(2 * math.pi * t + phase) + 1) / 2; // 0 → 1
              const minH = 0.10;
              final maxH = _maxHeights[i];
              final heightFraction = minH + (maxH - minH) * sinValue;

              return Container(
                width: barWidth,
                height: widget.height * heightFraction,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(barWidth / 2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
