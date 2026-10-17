import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/results_page.dart';
import 'package:moodtune_app/shared/widgets/confidence_ring.dart';
import 'package:moodtune_app/shared/widgets/mood_hero_card.dart';

import '../../../../helpers/helpers.dart';

HistoryEntry _entry({
  String title = 'Saved Song',
  String? subtitle = 'Saved Artist',
  String primaryMood = 'happy',
  double? confidence = 0.8,
  HistoryEntryType type = HistoryEntryType.song,
  EngineComparison? comparison,
}) => HistoryEntry(
  id: 'h1',
  title: title,
  subtitle: subtitle,
  primaryMood: primaryMood,
  confidence: confidence,
  createdAt: DateTime(2026, 10, 17),
  type: type,
  comparison: comparison,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const AnalysisHistoryRequested());
  });

  group('ResultsPage.saved', () {
    Future<AnalysisBloc> pumpSaved(
      WidgetTester tester,
      HistoryEntry entry,
    ) async {
      final bloc = mockAnalysisBloc();
      await tester.pumpApp(ResultsPage.saved(entry: entry), analysisBloc: bloc);
      await tester.pumpAndSettle();
      return bloc;
    }

    testWidgets('shows title, artist, mood and confidence', (tester) async {
      final bloc = await pumpSaved(tester, _entry());

      expect(find.text('Song Analysis'), findsOneWidget);
      expect(find.text('Saved Song'), findsOneWidget);
      expect(find.text('Saved Artist'), findsOneWidget);
      expect(find.text('UPBEAT'), findsOneWidget);
      expect(find.byType(ConfidenceRing), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      // Read-only: nothing dispatched, nothing re-analyzed.
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('leaves out sections the entry has no data for', (
      tester,
    ) async {
      await pumpSaved(tester, _entry());

      expect(find.text('Audio details'), findsNothing);
      expect(find.text('Does this feel right?'), findsNothing);
      expect(find.text('Analyze another song'), findsNothing);
      expect(find.text('Go to Home'), findsNothing);
      expect(find.textContaining('Jamendo'), findsNothing);
      // No engine rows without a stored comparison.
      expect(find.text('Mood shown from'), findsNothing);
    });

    testWidgets('shows both engines and which one was shown', (tester) async {
      await pumpSaved(
        tester,
        _entry(
          primaryMood: 'calm',
          confidence: null,
          comparison: const EngineComparison(
            backendMood: 'happy',
            onDeviceMood: 'calm',
            displayedSource: MoodSource.onDevice,
          ),
        ),
      );

      expect(find.text('Mood shown from'), findsOneWidget);
      expect(find.text('On-device'), findsOneWidget);
      expect(find.text('Backend mood'), findsOneWidget);
      expect(find.text('UPBEAT'), findsOneWidget);
      expect(find.text('On-device mood'), findsOneWidget);
      // Hero card and the on-device row both say SERENE.
      expect(find.text('SERENE'), findsNWidgets(2));
      expect(find.byType(ConfidenceRing), findsNothing);
    });

    testWidgets('no ring when the on-device mood was shown, even with a '
        'stored confidence', (tester) async {
      await pumpSaved(
        tester,
        _entry(
          comparison: const EngineComparison(
            backendMood: 'happy',
            onDeviceMood: 'happy',
            displayedSource: MoodSource.onDevice,
          ),
        ),
      );

      final card = tester.widget<MoodHeroCard>(find.byType(MoodHeroCard));
      expect(card.confidence, isNull);
      expect(find.byType(ConfidenceRing), findsNothing);
    });

    testWidgets('says when the on-device engine did not run', (tester) async {
      await pumpSaved(
        tester,
        _entry(
          comparison: const EngineComparison(
            backendMood: 'happy',
            displayedSource: MoodSource.backend,
          ),
        ),
      );

      expect(find.text('Backend'), findsOneWidget);
      expect(find.text('Didn’t run'), findsOneWidget);
      expect(find.byType(ConfidenceRing), findsOneWidget);
    });

    testWidgets('playlist entries without an artist', (tester) async {
      await pumpSaved(
        tester,
        _entry(
          title: 'Road Trip',
          subtitle: null,
          type: HistoryEntryType.playlist,
        ),
      );

      expect(find.text('Playlist Analysis'), findsOneWidget);
      expect(find.text('Road Trip'), findsOneWidget);
      expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    });
  });
}
