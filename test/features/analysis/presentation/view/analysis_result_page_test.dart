import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/analysis_result_page.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/mood_distribution_chart.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/top_track_card.dart';

import '../../../../helpers/helpers.dart';
import 'results_fixtures.dart';

void main() {
  group('AnalysisResultPage', () {
    testWidgets('shows loading when no analysis is available', (tester) async {
      await tester.pumpApp(
        const AnalysisResultPage(analysisId: 'analysis-1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(status: AnalysisStatus.loading),
        ),
      );
      await tester.pump();

      expect(find.text('Analysis'), findsOneWidget);
      expect(find.text('Loading analysis...'), findsOneWidget);
      expect(find.text('Failed to load analysis'), findsNothing);
    });

    testWidgets('shows failure message when status is error', (tester) async {
      await tester.pumpApp(
        const AnalysisResultPage(analysisId: 'analysis-1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(status: AnalysisStatus.error),
        ),
      );
      await tester.pump();

      expect(find.text('Failed to load analysis'), findsOneWidget);
    });

    testWidgets('ignores bloc analysis with a different id', (tester) async {
      await tester.pumpApp(
        const AnalysisResultPage(analysisId: 'analysis-1'),
        analysisBloc: mockAnalysisBloc(
          AnalysisState(
            currentAnalysis: testPlaylistAnalysis(
              id: 'other',
              playlistName: 'Other Playlist',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Other Playlist'), findsNothing);
      expect(find.text('Loading analysis...'), findsOneWidget);
    });

    testWidgets('renders initialAnalysis when bloc has none', (tester) async {
      await tester.pumpApp(
        AnalysisResultPage(
          analysisId: 'analysis-1',
          initialAnalysis: testPlaylistAnalysis(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Road Trip'), findsOneWidget);
      expect(find.text('42 tracks analyzed'), findsOneWidget);
      expect(find.text('Primary Mood'), findsOneWidget);
      expect(find.text('Euphoric'), findsOneWidget);
      expect(find.text('Confidence: 87.3%'), findsOneWidget);
      expect(find.text('bright, energetic'), findsOneWidget);
      expect(find.text('Mood Distribution'), findsOneWidget);
      expect(find.byType(MoodDistributionChart), findsOneWidget);
      expect(find.text('Top Tracks'), findsOneWidget);
      expect(find.byType(TopTrackCard), findsNWidgets(2));
      expect(find.text('First Track'), findsOneWidget);
      expect(find.text('Second Track'), findsOneWidget);
    });

    testWidgets('renders averages and created date', (tester) async {
      await tester.pumpApp(
        AnalysisResultPage(
          analysisId: 'analysis-1',
          initialAnalysis: testPlaylistAnalysis(),
        ),
      );
      await tester.pumpAndSettle();

      final averages = find.text('Averages');
      await tester.scrollUntilVisible(
        find.textContaining('Created '),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(averages, findsOneWidget);
      expect(find.text('Valence'), findsOneWidget);
      expect(find.text('65.4%'), findsOneWidget);
      expect(find.text('71.2%'), findsOneWidget);
      expect(find.text('Danceability'), findsOneWidget);
      expect(find.text('50.0%'), findsWidgets);
      expect(find.text('Tempo'), findsOneWidget);
      expect(find.text('121.4 BPM'), findsOneWidget);
      expect(
        find.text('Created ${DateTime(2024, 3, 15, 10, 30)}'),
        findsOneWidget,
      );
    });

    testWidgets('omits descriptors line when there are none', (tester) async {
      await tester.pumpApp(
        AnalysisResultPage(
          analysisId: 'analysis-1',
          initialAnalysis: testPlaylistAnalysis(descriptors: const []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Euphoric'), findsOneWidget);
      expect(find.text('bright, energetic'), findsNothing);
    });

    testWidgets('prefers bloc analysis with matching id over initial', (
      tester,
    ) async {
      await tester.pumpApp(
        AnalysisResultPage(
          analysisId: 'analysis-1',
          initialAnalysis: testPlaylistAnalysis(playlistName: 'Stale'),
        ),
        analysisBloc: mockAnalysisBloc(
          AnalysisState(
            status: AnalysisStatus.success,
            currentAnalysis: testPlaylistAnalysis(playlistName: 'Fresh'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fresh'), findsOneWidget);
      expect(find.text('Stale'), findsNothing);
    });

    testWidgets('rebuilds from loading to result when bloc emits', (
      tester,
    ) async {
      final bloc = mockAnalysisBloc(
        const AnalysisState(status: AnalysisStatus.loading),
      );
      final loaded = AnalysisState(
        status: AnalysisStatus.success,
        currentAnalysis: testPlaylistAnalysis(),
      );
      whenListen(
        bloc,
        Stream<AnalysisState>.value(loaded),
        initialState: const AnalysisState(status: AnalysisStatus.loading),
      );

      await tester.pumpApp(
        const AnalysisResultPage(analysisId: 'analysis-1'),
        analysisBloc: bloc,
      );
      await tester.pumpAndSettle();

      expect(find.text('Loading analysis...'), findsNothing);
      expect(find.text('Road Trip'), findsOneWidget);
    });
  });
}
