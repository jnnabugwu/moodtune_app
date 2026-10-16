import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/shared/widgets/history_row_item.dart';

import '../../helpers/helpers.dart';
import '../widget_fixtures.dart';

Finder _markLabelled(String label) =>
    find.byWidgetPredicate((w) => w is Icon && w.semanticLabel == label);

void main() {
  group('HistoryRowItem', () {
    testWidgets('playlist entry shows mood chip, title, date and confidence', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        HistoryRowItem(
          item: buildHistoryEntry(confidence: 0.876),
          onTap: () {},
        ),
      );

      expect(find.text('UPBEAT'), findsOneWidget);
      expect(find.text('Morning Mix'), findsOneWidget);
      expect(find.text('Mar 14, 2025'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);

      final pct = tester.widget<Text>(find.text('88%'));
      expect(pct.style?.color, MoodTheme.colorsFor(MoodIdentity.upbeat).accent);
    });

    testWidgets('song entry shows artist subtitle and date on its own line', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        HistoryRowItem(
          item: buildHistoryEntry(
            title: 'Clair de Lune',
            subtitle: 'Debussy',
            primaryMood: 'sad',
            type: HistoryEntryType.song,
          ),
          onTap: () {},
        ),
      );

      expect(find.text('REFLECTIVE'), findsOneWidget);
      expect(find.text('Clair de Lune'), findsOneWidget);
      expect(find.text('Debussy'), findsOneWidget);
      expect(find.text('Mar 14, 2025'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Mar 14, 2025')).dy,
        greaterThan(tester.getTopLeft(find.text('Debussy')).dy),
      );
    });

    testWidgets('truncates titles longer than 24 characters', (tester) async {
      await tester.pumpWidgetInShell(
        HistoryRowItem(
          item: buildHistoryEntry(
            title: 'An Extremely Long Playlist Title Here',
          ),
          onTap: () {},
        ),
      );

      expect(find.text('An Extremely Long Playli…'), findsOneWidget);
      expect(find.text('An Extremely Long Playlist Title Here'), findsNothing);
    });

    testWidgets('keeps titles of exactly 24 characters intact', (tester) async {
      const title = 'ABCDEFGHIJKLMNOPQRSTUVWX';
      expect(title.length, 24);
      await tester.pumpWidgetInShell(
        HistoryRowItem(
          item: buildHistoryEntry(title: title),
          onTap: () {},
        ),
      );

      expect(find.text(title), findsOneWidget);
    });

    for (final entry in {
      'calm': 'SERENE',
      'angry': 'CHARGED',
      'unknown-mood': 'REFLECTIVE',
    }.entries) {
      testWidgets('maps "${entry.key}" to ${entry.value} chip', (tester) async {
        await tester.pumpWidgetInShell(
          HistoryRowItem(
            item: buildHistoryEntry(primaryMood: entry.key),
            onTap: () {},
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('invokes onTap when the row is tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidgetInShell(
        HistoryRowItem(item: buildHistoryEntry(), onTap: () => taps++),
      );

      await tester.tap(find.byType(HistoryRowItem));
      await tester.pump();

      expect(taps, 1);
    });

    group('engine comparison', () {
      const disagree = EngineComparison(
        backendMood: 'happy',
        onDeviceMood: 'calm',
        displayedSource: MoodSource.onDevice,
        agrees: false,
      );

      testWidgets('hides the confidence when there is none', (tester) async {
        await tester.pumpWidgetInShell(
          HistoryRowItem(
            item: buildHistoryEntry(confidence: null),
            onTap: () {},
          ),
        );

        expect(find.textContaining('%'), findsNothing);
      });

      testWidgets('is hidden unless showComparison is on', (tester) async {
        await tester.pumpWidgetInShell(
          HistoryRowItem(
            item: buildHistoryEntry(comparison: disagree),
            onTap: () {},
          ),
        );

        expect(find.textContaining('On-device'), findsNothing);
      });

      testWidgets('shows both moods, a mismatch mark and the answer', (
        tester,
      ) async {
        await tester.pumpWidgetInShell(
          HistoryRowItem(
            item: buildHistoryEntry(comparison: disagree),
            onTap: () {},
            showComparison: true,
          ),
        );

        expect(
          find.text('On-device SERENE · Backend UPBEAT · 👎'),
          findsOneWidget,
        );
        expect(_markLabelled('Engines disagree'), findsOneWidget);
      });

      testWidgets('marks a match at the bucket level', (tester) async {
        await tester.pumpWidgetInShell(
          HistoryRowItem(
            item: buildHistoryEntry(
              comparison: const EngineComparison(
                backendMood: 'happy',
                onDeviceMood: 'energetic',
                displayedSource: MoodSource.onDevice,
              ),
            ),
            onTap: () {},
            showComparison: true,
          ),
        );

        expect(_markLabelled('Engines agree'), findsOneWidget);
      });

      testWidgets('says when on-device did not run', (tester) async {
        await tester.pumpWidgetInShell(
          HistoryRowItem(
            item: buildHistoryEntry(
              comparison: const EngineComparison(
                backendMood: 'happy',
                displayedSource: MoodSource.backend,
              ),
            ),
            onTap: () {},
            showComparison: true,
          ),
        );

        expect(
          find.text('Backend UPBEAT · on-device didn’t run'),
          findsOneWidget,
        );
      });
    });
  });
}
