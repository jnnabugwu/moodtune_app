import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/shared/widgets/animated_waveform.dart';

import '../../helpers/helpers.dart';

void main() {
  const color = Color(0xFFE8721A);

  Finder bars() => find.descendant(
    of: find.byType(AnimatedWaveform),
    matching: find.byType(Container),
  );

  List<double> barHeights(WidgetTester tester) =>
      tester.widgetList<Container>(bars()).map((c) {
        return c.constraints!.maxHeight;
      }).toList();

  Widget waveform({bool isAnimating = true}) => Center(
    child: AnimatedWaveform(color: color, isAnimating: isAnimating),
  );

  group('AnimatedWaveform', () {
    testWidgets('renders barCount bars in the given colour and size', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(waveform(isAnimating: false));

      expect(bars(), findsNWidgets(7));
      expect(
        tester.getSize(
          find.descendant(
            of: find.byType(AnimatedWaveform),
            matching: find.byType(SizedBox),
          ),
        ),
        const Size(56, 40),
      );
      for (final c in tester.widgetList<Container>(bars())) {
        expect((c.decoration! as BoxDecoration).color, color);
      }
    });

    testWidgets('supports fewer bars and custom dimensions', (tester) async {
      await tester.pumpWidgetInShell(
        const Center(
          child: AnimatedWaveform(
            color: color,
            isAnimating: false,
            barCount: 3,
            width: 30,
            height: 20,
          ),
        ),
      );

      expect(bars(), findsNWidgets(3));
      // (30 - 4 * 2) / 3 bar width.
      final firstBar = tester.widget<Container>(bars().first);
      expect(firstBar.constraints!.maxWidth, closeTo(22 / 3, 0.0001));
    });

    testWidgets('bar heights stay fixed when not animating', (tester) async {
      await tester.pumpWidgetInShell(waveform(isAnimating: false));
      final before = barHeights(tester);

      await tester.pump(const Duration(milliseconds: 300));

      expect(barHeights(tester), before);
      // At t=0 the first bar (phase 0) is at its midpoint: 0.1 + 0.4 * 0.5.
      expect(before.first, closeTo(40 * 0.3, 0.0001));
    });

    testWidgets('bar heights change over time when animating', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(waveform());
      final before = barHeights(tester);

      await tester.pump(const Duration(milliseconds: 300));

      expect(barHeights(tester), isNot(equals(before)));
      for (final h in barHeights(tester)) {
        expect(h, inInclusiveRange(40 * 0.1, 40.0));
      }
    });

    testWidgets('stops and restarts when isAnimating toggles', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(waveform());
      await tester.pump(const Duration(milliseconds: 100));

      // Stop.
      await tester.pumpWidgetInShell(waveform(isAnimating: false));
      final stopped = barHeights(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(barHeights(tester), stopped);

      // Rebuild with the same flag is a no-op.
      await tester.pumpWidgetInShell(waveform(isAnimating: false));
      await tester.pump(const Duration(milliseconds: 300));
      expect(barHeights(tester), stopped);

      // Restart.
      await tester.pumpWidgetInShell(waveform());
      await tester.pump(const Duration(milliseconds: 300));
      expect(barHeights(tester), isNot(equals(stopped)));

      // Replace with an empty tree so the repeating controller is disposed.
      await tester.pumpWidget(const SizedBox());
    });
  });
}
