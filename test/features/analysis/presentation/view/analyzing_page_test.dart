import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/analyzing_page.dart';

import '../../../../helpers/helpers.dart';
import 'flow_fixtures.dart';

const _homeText = 'home';
const _pagePath = '/page';

/// Mounts a placeholder home and pushes [page] on top so `context.pop()`
/// has somewhere to go.
Future<void> _pumpPushed(
  WidgetTester tester,
  Widget page, {
  required AnalysisBloc analysisBloc,
}) async {
  final router = await tester.pumpApp(
    const Center(child: Text(_homeText)),
    analysisBloc: analysisBloc,
    extraRoutes: [GoRoute(path: _pagePath, builder: (_, _) => page)],
  );
  unawaited(router.push(_pagePath));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Finder _checkIcons() => find.byIcon(CupertinoIcons.check_mark_circled_solid);

Finder _emptyIcons() => find.byIcon(CupertinoIcons.circle);

void main() {
  group(AnalyzingPage, () {
    testWidgets('renders playlist meta with track count and limit', (
      tester,
    ) async {
      await tester.pumpApp(
        const AnalyzingPage(
          playlistId: 'p1',
          playlistName: 'Road Trip',
          trackCount: 120,
          limit: 25,
        ),
        analysisBloc: mockAnalysisBloc(),
      );

      expect(find.text('Analyzing'), findsOneWidget);
      expect(find.text('Analyzing your playlist...'), findsOneWidget);
      expect(find.text('Road Trip'), findsOneWidget);
      expect(find.text('120 songs (up to 25 analyzed)'), findsOneWidget);
      expect(find.text('Working on it...'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Fetching tracks'), findsOneWidget);
      expect(find.text('Analyzing mood'), findsOneWidget);
      expect(find.text('Generating results'), findsOneWidget);
    });

    testWidgets('falls back to default name and limit copy', (tester) async {
      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: mockAnalysisBloc(),
      );

      expect(find.text('Playlist'), findsOneWidget);
      expect(find.text('Analyzing up to 50 tracks'), findsOneWidget);
    });

    testWidgets('marks only the first step active when not yet analyzing', (
      tester,
    ) async {
      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(status: AnalysisStatus.loading),
        ),
      );

      expect(_checkIcons(), findsOneWidget);
      expect(_emptyIcons(), findsNWidgets(2));
    });

    testWidgets('marks two steps active while analyzing', (tester) async {
      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(status: AnalysisStatus.analyzing),
        ),
      );

      expect(_checkIcons(), findsNWidgets(2));
      expect(_emptyIcons(), findsOneWidget);
    });

    testWidgets('marks all steps active on success', (tester) async {
      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(status: AnalysisStatus.success),
        ),
      );

      expect(_checkIcons(), findsNWidgets(3));
      expect(_emptyIcons(), findsNothing);
    });

    testWidgets('shows error message from state', (tester) async {
      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(
            status: AnalysisStatus.error,
            error: 'Spotify is down',
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Spotify is down'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Analyzing your playlist...'), findsNothing);
    });

    testWidgets('shows default error message when error is null', (
      tester,
    ) async {
      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(status: AnalysisStatus.error),
        ),
      );

      expect(find.text('Failed to analyze playlist.'), findsOneWidget);
    });

    testWidgets('navigates to the analysis result on success', (
      tester,
    ) async {
      final bloc = mockAnalysisBloc(
        const AnalysisState(status: AnalysisStatus.analyzing),
      );
      whenListen(
        bloc,
        Stream.fromIterable([
          AnalysisState(
            status: AnalysisStatus.success,
            currentAnalysis: playlistAnalysis,
          ),
        ]),
        initialState: const AnalysisState(status: AnalysisStatus.analyzing),
      );

      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: bloc,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text(
          navigatedTo(RouteNames.analysisResultFor(playlistAnalysis.id)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('passes the analysis as extra when navigating on success', (
      tester,
    ) async {
      final bloc = mockAnalysisBloc();
      whenListen(
        bloc,
        Stream.fromIterable([
          AnalysisState(
            status: AnalysisStatus.success,
            currentAnalysis: playlistAnalysis,
          ),
        ]),
        initialState: const AnalysisState(),
      );

      Object? receivedExtra;
      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: bloc,
        extraRoutes: [
          GoRoute(
            path: RouteNames.analysisResult,
            builder: (_, state) {
              receivedExtra = state.extra;
              return Text('result:${state.pathParameters['id']}');
            },
          ),
        ],
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('result:${playlistAnalysis.id}'), findsOneWidget);
      expect(receivedExtra, equals(playlistAnalysis));
    });

    testWidgets('does not navigate on success without an analysis', (
      tester,
    ) async {
      final bloc = mockAnalysisBloc();
      whenListen(
        bloc,
        Stream.fromIterable([
          const AnalysisState(status: AnalysisStatus.success),
        ]),
        initialState: const AnalysisState(),
      );

      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: bloc,
      );
      await tester.pump();

      expect(find.textContaining('navigated:'), findsNothing);
      expect(find.text('Analyzing your playlist...'), findsOneWidget);
    });

    testWidgets('does not re-navigate when status is unchanged', (
      tester,
    ) async {
      const initial = AnalysisState(status: AnalysisStatus.success);
      final bloc = mockAnalysisBloc(initial);
      whenListen(
        bloc,
        Stream.fromIterable([
          // Same status, so listenWhen filters this out.
          AnalysisState(
            status: AnalysisStatus.success,
            currentAnalysis: playlistAnalysis,
          ),
        ]),
        initialState: initial,
      );

      await tester.pumpApp(
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: bloc,
      );
      await tester.pump();

      expect(find.textContaining('navigated:'), findsNothing);
    });

    testWidgets('Cancel pops back to the previous route', (tester) async {
      await _pumpPushed(
        tester,
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: mockAnalysisBloc(),
      );
      expect(find.text('Analyzing your playlist...'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(_homeText), findsOneWidget);
      expect(find.text('Analyzing your playlist...'), findsNothing);
    });

    testWidgets('Back on the error view pops to the previous route', (
      tester,
    ) async {
      await _pumpPushed(
        tester,
        const AnalyzingPage(playlistId: 'p1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(status: AnalysisStatus.error, error: 'boom'),
        ),
      );
      expect(find.text('boom'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(_homeText), findsOneWidget);
      expect(find.text('boom'), findsNothing);
    });
  });
}
