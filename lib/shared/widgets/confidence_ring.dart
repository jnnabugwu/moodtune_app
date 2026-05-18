import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// An animated donut-ring widget that visualises a confidence score.
///
/// Animates from 0 → [value] over 400 ms on first mount (ease-out).
/// Respects [MediaQueryData.disableAnimations] — when set, shows the final
/// value immediately without animation.
///
/// Below the ring a short match-quality label is shown:
/// * ≥ 80 %  → "Strong match"
/// * ≥ 60 %  → "Good match"
/// * < 60 %  → "Possible match"
class ConfidenceRing extends StatelessWidget {
  const ConfidenceRing({
    required this.value,
    required this.color,
    super.key,
    this.size = 80,
    this.strokeWidth = 8,
  });

  /// Confidence score in the range [0, 1].
  final double value;

  /// Ring and percentage text colour.
  final Color color;

  /// Outer diameter of the ring in logical pixels.
  final double size;

  /// Stroke width of the ring arc.
  final double strokeWidth;

  String get _matchLabel {
    if (value >= 0.80) return 'Strong match';
    if (value >= 0.60) return 'Good match';
    return 'Possible match';
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, animatedValue, _) {
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(size, size),
                    painter: _RingPainter(
                      value: animatedValue,
                      color: color,
                      strokeWidth: strokeWidth,
                    ),
                  ),
                  Text(
                    '${(animatedValue * 100).round()}%',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          _matchLabel,
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = color.withAlpha(40)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc (drawn clockwise from 12 o'clock)
    if (value > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * value.clamp(0.0, 1.0),
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
