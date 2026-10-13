import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/mood_distribution_chart.dart';

import '../../../../helpers/helpers.dart';

void main() {
  Widget chart(MoodDistribution d) => Padding(
    padding: const EdgeInsets.all(20),
    child: SizedBox(width: 400, child: MoodDistributionChart(distribution: d)),
  );

  double barWidth(WidgetTester tester, int index) {
    final bars = find.descendant(
      of: find.byType(MoodDistributionChart),
      matching: find.byType(AnimatedContainer),
    );
    return tester.getSize(bars.at(index)).width;
  }

  group('MoodDistributionChart', () {
    testWidgets('renders one labelled bar per mood with percentages', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        chart(
          const MoodDistribution(
            happy: 42.5,
            sad: 10,
            energetic: 75.5,
            calm: 0,
            danceable: 100,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in ['Happy', 'Sad', 'Energetic', 'Calm', 'Danceable']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('42.5%'), findsOneWidget);
      expect(find.text('10.0%'), findsOneWidget);
      expect(find.text('75.5%'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);

      // Bars are in label order and proportional to the 400px width.
      expect(barWidth(tester, 0), closeTo(170, 0.01));
      expect(barWidth(tester, 1), closeTo(40, 0.01));
      expect(barWidth(tester, 2), closeTo(302, 0.01));
      expect(barWidth(tester, 3), 0);
      expect(barWidth(tester, 4), closeTo(400, 0.01));
    });

    testWidgets('clamps out-of-range values to 0..100', (tester) async {
      await tester.pumpWidgetInShell(
        chart(
          const MoodDistribution(
            happy: 150,
            sad: -20,
            energetic: 50,
            calm: 50,
            danceable: 50,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('50.0%'), findsNWidgets(3));
      expect(barWidth(tester, 0), closeTo(400, 0.01));
      expect(barWidth(tester, 1), 0);
    });

    testWidgets('animates bar width when the distribution changes', (
      tester,
    ) async {
      const before = MoodDistribution(
        happy: 0,
        sad: 0,
        energetic: 0,
        calm: 0,
        danceable: 0,
      );
      const after = MoodDistribution(
        happy: 100,
        sad: 0,
        energetic: 0,
        calm: 0,
        danceable: 0,
      );
      await tester.pumpWidgetInShell(chart(before));
      await tester.pumpWidgetInShell(chart(after));
      await tester.pump(const Duration(milliseconds: 200));

      final mid = barWidth(tester, 0);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(400));

      await tester.pumpAndSettle();
      expect(barWidth(tester, 0), closeTo(400, 0.01));
    });
  });
}
