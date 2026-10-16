import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:moodtune_app/features/catalog/presentation/view/catalog_search_page.dart';
import 'package:moodtune_app/features/catalog/presentation/widgets/catalog_confirm_sheet.dart';
import 'package:moodtune_app/features/catalog/presentation/widgets/catalog_track_card.dart';

import '../../../../helpers/helpers.dart';
import '../../catalog_fixtures.dart';

void main() {
  late MockCatalogBloc catalogBloc;
  late MockAnalysisBloc analysisBloc;

  setUpAll(() {
    registerFallbackValue(const CatalogCleared());
    registerFallbackValue(const AnalysisClearErrorRequested());
  });

  setUp(() {
    catalogBloc = mockCatalogBloc();
    analysisBloc = mockAnalysisBloc();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      const CatalogSearchPage(),
      catalogBloc: catalogBloc,
      analysisBloc: analysisBloc,
    );
    await tester.pump();
  }

  /// Returns every CatalogSearchRequested added to the catalog bloc.
  List<CatalogSearchRequested> addedSearches() => verify(
    () => catalogBloc.add(captureAny()),
  ).captured.whereType<CatalogSearchRequested>().toList();

  Finder byTypeName(String name) =>
      find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

  group('renders state', () {
    testWidgets('initial shows the empty prompt and mood chips', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Browse Catalog'), findsOneWidget);
      expect(
        find.text('Search for a track or pick a mood to explore.'),
        findsOneWidget,
      );
      for (final label in ['All', 'Upbeat', 'Serene', 'Charged']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('loading shows three shimmer cards', (tester) async {
      when(() => catalogBloc.state).thenReturn(const CatalogLoading());
      await pumpPage(tester);

      expect(byTypeName('_ShimmerCard'), findsNWidgets(3));
      expect(
        find.text('Search for a track or pick a mood to explore.'),
        findsNothing,
      );
    });

    testWidgets('loaded renders a card per track', (tester) async {
      when(() => catalogBloc.state).thenReturn(
        CatalogLoaded([
          buildJamendoTrack(),
          buildJamendoTrack(id: '2', name: 'Moon Song'),
        ]),
      );
      await pumpPage(tester);

      expect(find.byType(CatalogTrackCard), findsNWidgets(2));
      expect(find.text('Sunny Day'), findsOneWidget);
      expect(find.text('Moon Song'), findsOneWidget);
    });

    testWidgets('empty results without a query suggest clearing the filter', (
      tester,
    ) async {
      when(() => catalogBloc.state).thenReturn(const CatalogLoaded([]));
      await pumpPage(tester);

      expect(
        find.text('No tracks match this mood.\nTry clearing the filter.'),
        findsOneWidget,
      );
    });

    testWidgets('empty results with a query mention the query', (tester) async {
      final controller = StreamController<CatalogState>();
      addTearDown(controller.close);
      whenListen(
        catalogBloc,
        controller.stream,
        initialState: const CatalogInitial(),
      );
      await pumpPage(tester);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'zzz');
      when(() => catalogBloc.state).thenReturn(const CatalogLoaded([]));
      controller.add(const CatalogLoaded([]));
      await tester.pump();

      expect(
        find.text(
          "No tracks found for 'zzz'.\n"
          'Try different keywords or clear the mood filter.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('error shows retry which re-runs the current search', (
      tester,
    ) async {
      when(() => catalogBloc.state).thenReturn(const CatalogError('boom'));
      await pumpPage(tester);

      expect(
        find.text("Couldn't reach the catalog right now."),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(addedSearches(), [const CatalogSearchRequested(query: '')]);
    });
  });

  group('interactions', () {
    testWidgets('typing searches with the current text', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'jazz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(addedSearches(), [
        const CatalogSearchRequested(query: 'jazz'),
        const CatalogSearchRequested(query: 'jazz'),
      ]);
    });

    testWidgets('mood chips toggle the mood filter', (tester) async {
      await pumpPage(tester);
      await tester.enterText(find.byType(CupertinoSearchTextField), 'rock');
      await tester.pump();
      clearInteractions(catalogBloc);

      // Select a mood.
      await tester.tap(find.text('Serene'));
      await tester.pump(const Duration(milliseconds: 200));
      // Tap again to deselect.
      await tester.tap(find.text('Serene'));
      await tester.pump(const Duration(milliseconds: 200));
      // Select another, then reset via "All".
      await tester.tap(find.text('Charged'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('All'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(addedSearches(), [
        const CatalogSearchRequested(query: 'rock', moodTag: 'serene'),
        const CatalogSearchRequested(query: 'rock'),
        const CatalogSearchRequested(query: 'rock', moodTag: 'charged'),
        const CatalogSearchRequested(query: 'rock'),
      ]);
    });

    testWidgets('typing keeps the selected mood', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Upbeat'));
      await tester.pump(const Duration(milliseconds: 200));
      clearInteractions(catalogBloc);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'sun');
      await tester.pump();

      expect(addedSearches(), [
        const CatalogSearchRequested(query: 'sun', moodTag: 'upbeat'),
      ]);
    });

    testWidgets(
      'confirming a track starts catalog analysis and opens loading',
      (tester) async {
        final track = buildJamendoTrack(
          id: '7',
          duration: const Duration(seconds: 200),
        );
        when(() => catalogBloc.state).thenReturn(CatalogLoaded([track]));
        await pumpPage(tester);

        await tester.tap(find.text('Analyze →'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(CatalogConfirmSheet), findsOneWidget);

        await tester.tap(find.text('Analyze this track'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(
          () => analysisBloc.add(
            const CatalogTrackAnalyzeRequested(
              audioUrl: 'https://audio.example/7.mp3',
              trackId: '7',
              trackName: 'Sunny Day',
              artistName: 'The Testers',
              jamendoPageUrl: 'https://jamendo.example/track/7',
            ),
          ),
        ).called(1);
        expect(
          find.text(navigatedTo(RouteNames.analysisLoading)),
          findsOneWidget,
        );
      },
    );

    testWidgets('cancelling the sheet does not start analysis', (tester) async {
      when(
        () => catalogBloc.state,
      ).thenReturn(CatalogLoaded([buildJamendoTrack()]));
      await pumpPage(tester);

      await tester.tap(find.text('Analyze →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CatalogConfirmSheet), findsNothing);
      verifyNever(() => analysisBloc.add(any()));
    });
  });
}
