import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/top_track_card.dart';

import '../../../../helpers/helpers.dart';
import '../../../../shared/widget_fixtures.dart';

void main() {
  group('TopTrackCard', () {
    testWidgets('shows track name, joined artists and metric tags', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        const TopTrackCard(track: testTrackAnalysis),
      );

      expect(find.text('Electric Feel'), findsOneWidget);
      expect(find.text('MGMT, Guest'), findsOneWidget);
      expect(find.text('Mood: Happy'), findsOneWidget);
      expect(find.text('Energy 42%'), findsOneWidget);
      expect(find.text('Valence 73%'), findsOneWidget);
    });

    testWidgets('handles a track with no artists and zero metrics', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        const TopTrackCard(
          track: TrackAnalysis(
            trackId: 'x',
            trackName: 'Silence',
            artists: [],
            valence: 0,
            energy: 1,
            danceability: 0,
            moodLabel: 'Calm',
          ),
        ),
      );

      expect(find.text('Silence'), findsOneWidget);
      expect(find.text(''), findsOneWidget);
      expect(find.text('Mood: Calm'), findsOneWidget);
      expect(find.text('Energy 100%'), findsOneWidget);
      expect(find.text('Valence 0%'), findsOneWidget);
    });
  });
}
