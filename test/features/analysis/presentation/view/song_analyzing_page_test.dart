import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/song_analyzing_page.dart';
import 'package:moodtune_app/features/spotify/domain/entities/spotify_track.dart';

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

void main() {
  group(SongAnalyzingPage, () {
    testWidgets('renders loading copy without track meta', (tester) async {
      await tester.pumpApp(
        const SongAnalyzingPage(trackId: 'track-1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(status: AnalysisStatus.analyzing),
        ),
      );

      expect(find.text('Analyzing'), findsOneWidget);
      expect(find.text('Analyzing song...'), findsOneWidget);
      expect(find.text('This may take a few seconds.'), findsOneWidget);
      expect(find.text('Working on it...'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text(spotifyTrack.name), findsNothing);
    });

    testWidgets('renders track name and joined artists', (tester) async {
      await tester.pumpApp(
        const SongAnalyzingPage(trackId: 'track-1', track: spotifyTrack),
        analysisBloc: mockAnalysisBloc(),
      );

      expect(find.text('Track One'), findsOneWidget);
      expect(find.text('Artist A, Artist B'), findsOneWidget);
    });

    testWidgets('omits the artists line when a track has no artists', (
      tester,
    ) async {
      await tester.pumpApp(
        const SongAnalyzingPage(
          trackId: 'solo',
          track: SpotifyTrack(id: 'solo', name: 'Nameless', artists: []),
        ),
        analysisBloc: mockAnalysisBloc(),
      );

      expect(find.text('Nameless'), findsOneWidget);
      // No empty artists line is rendered under the track name.
      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(SafeArea),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(texts, isNot(contains('')));
    });

    testWidgets('shows error message from state', (tester) async {
      await tester.pumpApp(
        const SongAnalyzingPage(trackId: 'track-1', track: spotifyTrack),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(
            status: AnalysisStatus.error,
            error: 'Track unavailable',
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Track unavailable'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Analyzing song...'), findsNothing);
    });

    testWidgets('shows default error message when error is null', (
      tester,
    ) async {
      await tester.pumpApp(
        const SongAnalyzingPage(trackId: 'track-1'),
        analysisBloc: mockAnalysisBloc(
          const AnalysisState(status: AnalysisStatus.error),
        ),
      );

      expect(find.text('Failed to analyze song.'), findsOneWidget);
    });

    testWidgets('navigates to the song result with the analysis as extra', (
      tester,
    ) async {
      final bloc = mockAnalysisBloc();
      whenListen(
        bloc,
        Stream.fromIterable([
          const AnalysisState(status: AnalysisStatus.analyzing),
          const AnalysisState(
            status: AnalysisStatus.success,
            currentSongAnalysis: songAnalysisResult,
          ),
        ]),
        initialState: const AnalysisState(),
      );

      Object? receivedExtra;
      await tester.pumpApp(
        const SongAnalyzingPage(trackId: 'track-1'),
        analysisBloc: bloc,
        extraRoutes: [
          GoRoute(
            path: RouteNames.songResult,
            builder: (_, state) {
              receivedExtra = state.extra;
              return const Text('song-result');
            },
          ),
        ],
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('song-result'), findsOneWidget);
      expect(receivedExtra, equals(songAnalysisResult));
    });

    testWidgets('navigates to song result route on success', (tester) async {
      final bloc = mockAnalysisBloc();
      whenListen(
        bloc,
        Stream.fromIterable([
          const AnalysisState(
            status: AnalysisStatus.success,
            currentSongAnalysis: songAnalysisResult,
          ),
        ]),
        initialState: const AnalysisState(),
      );

      await tester.pumpApp(
        const SongAnalyzingPage(trackId: 'track-1'),
        analysisBloc: bloc,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(navigatedTo(RouteNames.songResult)), findsOneWidget);
    });

    testWidgets('does not navigate on success without a song analysis', (
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
        const SongAnalyzingPage(trackId: 'track-1'),
        analysisBloc: bloc,
      );
      await tester.pump();

      expect(find.textContaining('navigated:'), findsNothing);
      expect(find.text('Analyzing song...'), findsOneWidget);
    });

    testWidgets('Cancel pops back to the previous route', (tester) async {
      await _pumpPushed(
        tester,
        const SongAnalyzingPage(trackId: 'track-1'),
        analysisBloc: mockAnalysisBloc(),
      );
      expect(find.text('Analyzing song...'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(_homeText), findsOneWidget);
      expect(find.text('Analyzing song...'), findsNothing);
    });

    testWidgets('Back on the error view pops to the previous route', (
      tester,
    ) async {
      await _pumpPushed(
        tester,
        const SongAnalyzingPage(trackId: 'track-1'),
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
