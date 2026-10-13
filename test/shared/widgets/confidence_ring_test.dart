import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/shared/widgets/confidence_ring.dart';

import '../../helpers/helpers.dart';

void main() {
  const color = Color(0xFF123456);

  Widget ring(double value, {bool disableAnimations = false}) {
    return Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: Center(
          child: ConfidenceRing(value: value, color: color),
        ),
      ),
    );
  }

  group('ConfidenceRing match label', () {
    final cases = <double, String>{
      0.95: 'Strong match',
      0.80: 'Strong match',
      0.79: 'Good match',
      0.60: 'Good match',
      0.59: 'Possible match',
      0.0: 'Possible match',
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} -> ${entry.value}', (tester) async {
        await tester.pumpWidgetInShell(ring(entry.key));
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        expect(
          find.text('${(entry.key * 100).round()}%'),
          findsOneWidget,
        );
      });
    }
  });

  group('ConfidenceRing animation', () {
    testWidgets('animates percentage from 0 to value over 400ms', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(ring(0.75));

      expect(find.text('0%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      final midText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .firstWhere((d) => d != null && d.endsWith('%'));
      final mid = int.parse(midText!.replaceAll('%', ''));
      expect(mid, greaterThan(0));
      expect(mid, lessThan(75));

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('shows final value immediately when animations disabled', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(ring(0.42, disableAnimations: true));
      await tester.pump();

      expect(find.text('42%'), findsOneWidget);
      expect(find.text('Possible match'), findsOneWidget);
    });

    testWidgets('clamps values above 1 to 100%', (tester) async {
      await tester.pumpWidgetInShell(ring(1.7));
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Strong match'), findsOneWidget);
    });

    testWidgets('clamps negative values to 0%', (tester) async {
      await tester.pumpWidgetInShell(ring(-0.3));
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Possible match'), findsOneWidget);
    });

    testWidgets('repaints when value changes', (tester) async {
      await tester.pumpWidgetInShell(ring(0.3));
      await tester.pumpAndSettle();
      expect(find.text('30%'), findsOneWidget);

      await tester.pumpWidgetInShell(ring(0.9));
      await tester.pumpAndSettle();
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('Strong match'), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidgetInShell(
        const Center(
          child: ConfidenceRing(value: 0.5, color: color, size: 120),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.getSize(
        find.descendant(
          of: find.byType(ConfidenceRing),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(box, const Size(120, 120));
      final pct = tester.widget<Text>(find.text('50%'));
      expect(pct.style?.fontSize, closeTo(120 * 0.22, 0.001));
      expect(pct.style?.color, color);
    });
  });
}
