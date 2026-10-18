import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The MoodTune smiling-note mark, drawn from the brand SVG (viewBox
/// 0 0 220 220). Used by the splash lockup and the share card.
class MoodTuneNoteMark extends StatelessWidget {
  const MoodTuneNoteMark({
    required this.size,
    required this.noteColor,
    required this.faceColor,
    super.key,
  });

  /// Side of the square the mark is drawn in.
  final double size;

  /// Stem, flag and head colour.
  final Color noteColor;

  /// Eyes and smile colour.
  final Color faceColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: NoteMarkPainter(noteColor: noteColor, faceColor: faceColor),
      ),
    );
  }
}

/// Paints the note mark. All coordinates have the SVG translate(10,10)
/// baked in.
///
/// Shapes:
///   1. Stem  — vertical rect
///   2. Flag  — cubic-bezier closed path
///   3. Head  — ellipse rotated −22° around its centre (110, 168)
///   4. Eyes  — two circles inside the head
///   5. Smile — quadratic arc, stroked
///
/// Shapes 3–5 share the same −22° rotation transform.
class NoteMarkPainter extends CustomPainter {
  const NoteMarkPainter({required this.noteColor, required this.faceColor});

  final Color noteColor;
  final Color faceColor;

  static const int _viewBox = 220;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale so all coordinates live in the 220×220 viewBox space.
    canvas.scale(size.width / _viewBox);

    final fill = Paint()
      ..color = noteColor
      ..style = PaintingStyle.fill;

    final face = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;

    final smilePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // 1. Stem — rect x=138 y=0 w=13 h=150 (+ translate 10,10)
    canvas.drawRect(const Rect.fromLTWH(148, 10, 13, 150), fill);

    // 2. Flag — M 151 0 C … Z (+ translate 10,10)
    final flag = Path()
      ..moveTo(161, 10)
      ..cubicTo(208, 28, 218, 70, 188, 96)
      ..cubicTo(210, 66, 198, 40, 161, 32)
      ..close();
    canvas.drawPath(flag, fill);

    // 3–5. Head + face — all share rotate(−22°) around (110, 168).
    final smile = Path()
      ..moveTo(90, 180)
      ..quadraticBezierTo(110, 196, 130, 180);

    canvas
      ..save()
      ..translate(110, 168)
      ..rotate(-22 * math.pi / 180)
      ..translate(-110, -168)
      // 3. Head — ellipse cx=110 cy=168 rx=58 ry=42
      ..drawOval(
        Rect.fromCenter(center: const Offset(110, 168), width: 116, height: 84),
        fill,
      )
      // 4. Eyes — r=6.5 at (94,160) and (126,160)
      ..drawCircle(const Offset(94, 160), 6.5, face)
      ..drawCircle(const Offset(126, 160), 6.5, face)
      // 5. Smile — quadratic arc
      ..drawPath(smile, smilePaint)
      ..restore();
  }

  @override
  bool shouldRepaint(NoteMarkPainter oldDelegate) =>
      noteColor != oldDelegate.noteColor || faceColor != oldDelegate.faceColor;
}
