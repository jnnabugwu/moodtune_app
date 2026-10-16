import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/history_entry.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/analysis_card.dart';

import '../../../../helpers/helpers.dart';
import '../../../../shared/widget_fixtures.dart';

void main() {
  group('AnalysisCard', () {
    testWidgets('playlist entry shows title, mood, confidence and type', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        AnalysisCard(
          entry: buildHistoryEntry(
            subtitle: 'ignored for playlists',
            primaryMood: 'Happy',
            confidence: 0.876,
          ),
        ),
      );

      expect(find.text('Morning Mix'), findsOneWidget);
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('88% confidence'), findsOneWidget);
      expect(find.text('Playlist'), findsOneWidget);
      // Subtitle is only rendered for songs.
      expect(find.text('ignored for playlists'), findsNothing);
    });

    testWidgets('song entry shows the artist subtitle and Song tag', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        AnalysisCard(
          entry: buildHistoryEntry(
            title: 'Bohemian Rhapsody',
            subtitle: 'Queen',
            primaryMood: 'Energetic',
            confidence: 0.5,
            type: HistoryEntryType.song,
          ),
        ),
      );

      expect(find.text('Bohemian Rhapsody'), findsOneWidget);
      expect(find.text('Queen'), findsOneWidget);
      expect(find.text('Energetic'), findsOneWidget);
      expect(find.text('50% confidence'), findsOneWidget);
      expect(find.text('Song'), findsOneWidget);
    });

    testWidgets('song entry without subtitle omits the artist line', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        AnalysisCard(
          entry: buildHistoryEntry(
            title: 'Untitled',
            type: HistoryEntryType.song,
          ),
        ),
      );

      expect(find.text('Untitled'), findsOneWidget);
      expect(find.text('Song'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidgetInShell(
        AnalysisCard(entry: buildHistoryEntry(), onTap: () => taps++),
      );

      await tester.tap(find.text('Morning Mix'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('keeps the type tag on the right without confidence', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        AnalysisCard(entry: buildHistoryEntry(confidence: null)),
      );
      final withoutConfidence = tester.getTopRight(find.text('Playlist')).dx;

      await tester.pumpWidgetInShell(AnalysisCard(entry: buildHistoryEntry()));
      final withConfidence = tester.getTopRight(find.text('Playlist')).dx;

      expect(find.textContaining('confidence'), findsOneWidget);
      expect(withoutConfidence, withConfidence);
    });
  });
}
