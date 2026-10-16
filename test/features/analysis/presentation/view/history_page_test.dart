import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/engine_comparison.dart';
import 'package:moodtune_app/features/analysis/presentation/view/history_page.dart';
import 'package:moodtune_app/shared/widgets/history_row_item.dart';
import 'package:moodtune_app/shared/widgets/mood_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/helpers.dart';
import 'results_fixtures.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const AnalysisHistoryRequested());
  });

  group('HistoryPage', () {
    group('initial load', () {
      testWidgets('requests history when none is loaded', (tester) async {
        final bloc = mockAnalysisBloc();

        await tester.pumpApp(const HistoryPage(), analysisBloc: bloc);
        await tester.pumpAndSettle();

        verify(() => bloc.add(const AnalysisHistoryRequested())).called(1);
      });

      testWidgets('does not request history when already loaded', (
        tester,
      ) async {
        final history = testHistory(2);
        final bloc = mockAnalysisBloc(
          AnalysisState(history: history, filteredHistory: history),
        );

        await tester.pumpApp(const HistoryPage(), analysisBloc: bloc);
        await tester.pumpAndSettle();

        verifyNever(() => bloc.add(any()));
      });

      testWidgets('does not request history while already loading', (
        tester,
      ) async {
        final bloc = mockAnalysisBloc(
          const AnalysisState(historyLoading: true),
        );

        await tester.pumpApp(const HistoryPage(), analysisBloc: bloc);
        await tester.pump();

        verifyNever(() => bloc.add(any()));
        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      });
    });

    group('navigation bar', () {
      testWidgets('hides the leading back button when embedded', (
        tester,
      ) async {
        await tester.pumpApp(const HistoryPage(isEmbedded: true));
        await tester.pumpAndSettle();

        expect(find.text('My History'), findsOneWidget);
        final navBar = tester.widget<CupertinoNavigationBar>(
          find.byType(CupertinoNavigationBar),
        );
        expect(navBar.leading, isA<SizedBox>());
      });

      testWidgets('uses default leading when standalone', (tester) async {
        await tester.pumpApp(const HistoryPage());
        await tester.pumpAndSettle();

        expect(find.text('My History'), findsOneWidget);
        final navBar = tester.widget<CupertinoNavigationBar>(
          find.byType(CupertinoNavigationBar),
        );
        expect(navBar.leading, isNull);
      });
    });

    group('error state', () {
      testWidgets('shows error and retries on "Try again"', (tester) async {
        final history = testHistory(1);
        final bloc = mockAnalysisBloc(
          AnalysisState(history: history, historyError: 'Network down'),
        );

        await tester.pumpApp(const HistoryPage(), analysisBloc: bloc);
        await tester.pumpAndSettle();

        expect(find.text('Network down'), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.exclamationmark_circle), findsOne);
        expect(find.byType(HistoryRowItem), findsNothing);

        await tester.tap(find.text('Try again'));
        await tester.pump();

        verify(() => bloc.add(const AnalysisHistoryRequested())).called(1);
      });
    });

    group('empty state', () {
      testWidgets('shows "Nothing here yet." and opens the source sheet', (
        tester,
      ) async {
        await tester.pumpApp(const HistoryPage());
        await tester.pumpAndSettle();

        expect(find.text('Nothing here yet.'), findsOneWidget);
        expect(find.text('Clear filter'), findsNothing);

        await tester.tap(find.text('Analyze a song'));
        await tester.pumpAndSettle();

        expect(find.text('Analyze a Song'), findsOneWidget);
        expect(find.text('Browse Catalog'), findsOneWidget);
        expect(find.text('Upload a Song'), findsOneWidget);

        await tester.tap(find.text('Upload a Song'));
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.uploadMusic)), findsOneWidget);
      });

      testWidgets('shows filter-specific empty state and clears filter', (
        tester,
      ) async {
        // History loaded but the filtered view is empty.
        final bloc = mockAnalysisBloc(AnalysisState(history: testHistory(3)));

        await tester.pumpApp(const HistoryPage(), analysisBloc: bloc);
        await tester.pumpAndSettle();
        expect(find.text('Nothing here yet.'), findsOneWidget);

        await tester.tap(find.text('Serene'));
        await tester.pumpAndSettle();

        verify(
          () => bloc.add(const AnalysisHistoryFilterChanged('serene')),
        ).called(1);
        expect(find.text('No analyses match this filter.'), findsOneWidget);
        expect(find.text('Analyze a song'), findsNothing);

        await tester.tap(find.text('Clear filter'));
        await tester.pumpAndSettle();

        verify(
          () => bloc.add(const AnalysisHistoryFilterChanged(null)),
        ).called(1);
        expect(find.text('Nothing here yet.'), findsOneWidget);
      });
    });

    group('filters', () {
      testWidgets('renders All plus one chip per mood', (tester) async {
        await tester.pumpApp(const HistoryPage());
        await tester.pumpAndSettle();

        expect(find.text('All'), findsOneWidget);
        expect(find.byType(MoodChip), findsNWidgets(4));
        for (final label in ['Upbeat', 'Serene', 'Charged', 'Reflective']) {
          expect(find.widgetWithText(MoodChip, label), findsOneWidget);
        }
        // "All" is selected by default; no mood chip is.
        for (final chip in tester.widgetList<MoodChip>(find.byType(MoodChip))) {
          expect(chip.isSelected, isFalse);
        }
      });

      testWidgets('tapping a chip selects it; tapping again clears it', (
        tester,
      ) async {
        final history = testHistory(2);
        final bloc = mockAnalysisBloc(
          AnalysisState(history: history, filteredHistory: history),
        );

        await tester.pumpApp(const HistoryPage(), analysisBloc: bloc);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Upbeat'));
        await tester.pumpAndSettle();

        verify(
          () => bloc.add(const AnalysisHistoryFilterChanged('upbeat')),
        ).called(1);
        expect(
          tester
              .widget<MoodChip>(find.widgetWithText(MoodChip, 'Upbeat'))
              .isSelected,
          isTrue,
        );

        await tester.tap(find.text('Upbeat'));
        await tester.pumpAndSettle();

        verify(
          () => bloc.add(const AnalysisHistoryFilterChanged(null)),
        ).called(1);
        expect(
          tester
              .widget<MoodChip>(find.widgetWithText(MoodChip, 'Upbeat'))
              .isSelected,
          isFalse,
        );
      });

      testWidgets('tapping All resets the filter', (tester) async {
        final history = testHistory(2);
        final bloc = mockAnalysisBloc(
          AnalysisState(history: history, filteredHistory: history),
        );

        await tester.pumpApp(const HistoryPage(), analysisBloc: bloc);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Charged'));
        await tester.pumpAndSettle();
        verify(
          () => bloc.add(const AnalysisHistoryFilterChanged('charged')),
        ).called(1);

        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        verify(
          () => bloc.add(const AnalysisHistoryFilterChanged(null)),
        ).called(1);
        expect(
          tester
              .widget<MoodChip>(find.widgetWithText(MoodChip, 'Charged'))
              .isSelected,
          isFalse,
        );
      });
    });

    group('list', () {
      testWidgets('renders filtered history rows', (tester) async {
        final history = [
          testHistoryEntry(0, subtitle: 'Artist Zero'),
          testHistoryEntry(1, mood: 'serene'),
          testHistoryEntry(2, mood: 'charged'),
        ];
        final bloc = mockAnalysisBloc(
          AnalysisState(history: history, filteredHistory: history.sublist(1)),
        );

        await tester.pumpApp(const HistoryPage(), analysisBloc: bloc);
        await tester.pumpAndSettle();

        expect(find.byType(HistoryRowItem), findsNWidgets(2));
        expect(find.text('Entry 0'), findsNothing);
        expect(find.text('Entry 1'), findsOneWidget);
        expect(find.text('Entry 2'), findsOneWidget);
        expect(
          find.text('Showing your 50 most recent analyses.'),
          findsNothing,
        );

        // Rows are tappable without side effects.
        await tester.tap(find.text('Entry 1'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('shows cap footnote when 50 items are shown', (tester) async {
        final history = testHistory(50);
        final bloc = mockAnalysisBloc(
          AnalysisState(history: history, filteredHistory: history),
        );

        await tester.pumpApp(const HistoryPage(), analysisBloc: bloc);
        await tester.pumpAndSettle();

        const footnote = 'Showing your 50 most recent analyses.';
        await tester.scrollUntilVisible(
          find.text(footnote),
          300,
          scrollable: find
              .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable),
              )
              .first,
        );

        expect(find.text(footnote), findsOneWidget);
        expect(find.text('Entry 49'), findsOneWidget);
      });

      group('engine comparison', () {
        final compared = HistoryEntry(
          id: 'c1',
          title: 'Inside Outside',
          primaryMood: 'calm',
          confidence: null,
          createdAt: DateTime.utc(2026, 10, 16),
          type: HistoryEntryType.song,
          comparison: const EngineComparison(
            backendMood: 'happy',
            onDeviceMood: 'calm',
            displayedSource: MoodSource.onDevice,
            agrees: true,
          ),
        );

        testWidgets('is off by default and toggles from the nav bar', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({});
          final preference = EngineComparisonPreference();
          final bloc = mockAnalysisBloc(
            AnalysisState(history: [compared], filteredHistory: [compared]),
          );

          await tester.pumpApp(
            HistoryPage(comparisonPreference: preference),
            analysisBloc: bloc,
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('agreed on'), findsNothing);
          expect(find.textContaining('On-device SERENE'), findsNothing);

          await tester.tap(find.bySemanticsLabel('Compare engines'));
          await tester.pumpAndSettle();

          expect(
            find.text('On-device and backend agreed on 0 of 1'),
            findsOneWidget,
          );
          expect(
            find.text(
              'Your answers: on-device right 1, backend right 0 (of 1)',
            ),
            findsOneWidget,
          );
          expect(
            find.text('On-device SERENE · Backend UPBEAT · 👍 on-device'),
            findsOneWidget,
          );
          expect(preference.enabled.value, isTrue);
        });

        testWidgets('starts on when it was left on', (tester) async {
          SharedPreferences.setMockInitialValues({
            'history.showEngineComparison': true,
          });
          final bloc = mockAnalysisBloc(
            AnalysisState(history: [compared], filteredHistory: [compared]),
          );

          await tester.pumpApp(
            HistoryPage(comparisonPreference: EngineComparisonPreference()),
            analysisBloc: bloc,
          );
          await tester.pumpAndSettle();

          expect(
            find.bySemanticsLabel('Hide engine comparison'),
            findsOneWidget,
          );
          expect(find.textContaining('agreed on'), findsOneWidget);
        });
      });
    });
  });
}
