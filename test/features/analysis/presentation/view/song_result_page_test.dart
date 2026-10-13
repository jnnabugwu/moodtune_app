import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/view/song_result_page.dart';

import '../../../../helpers/helpers.dart';
import 'results_fixtures.dart';

void main() {
  group('SongResultPage', () {
    testWidgets('renders header, mood card and audio features', (
      tester,
    ) async {
      await tester.pumpApp(const SongResultPage(analysis: testSongAnalysis));
      await tester.pumpAndSettle();

      expect(find.text('Song Analysis'), findsOneWidget);
      expect(find.text('Blinding Lights'), findsOneWidget);
      expect(find.text('The Weeknd'), findsOneWidget);

      expect(find.text('Mood'), findsOneWidget);
      expect(find.text('ENERGETIC'), findsOneWidget);
      expect(find.text('88\n% confidence'), findsOneWidget);

      expect(find.text('Audio Features'), findsOneWidget);
      expect(find.text('Tempo'), findsOneWidget);
      expect(find.text('171 BPM'), findsOneWidget);
      expect(find.text('Energy'), findsOneWidget);
      expect(find.text('0.73'), findsOneWidget);
      expect(find.text('Valence'), findsOneWidget);
      expect(find.text('0.33'), findsOneWidget);
      expect(find.text('Danceability'), findsOneWidget);
      expect(find.text('0.51'), findsOneWidget);
      expect(find.text('Loudness'), findsOneWidget);
      expect(find.text('-5.9 dB'), findsOneWidget);
    });

    testWidgets('back button goes to spotify when nothing to pop', (
      tester,
    ) async {
      await tester.pumpApp(const SongResultPage(analysis: testSongAnalysis));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.spotify)), findsOneWidget);
    });

    testWidgets('back button pops when there is a previous route', (
      tester,
    ) async {
      final router = await tester.pumpApp(
        const Text('previous page'),
        extraRoutes: [
          GoRoute(
            path: '/song-result',
            builder: (_, _) => const SongResultPage(analysis: testSongAnalysis),
          ),
        ],
      );
      unawaited(router.push<void>('/song-result'));
      await tester.pumpAndSettle();
      expect(find.text('Blinding Lights'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      expect(find.text('previous page'), findsOneWidget);
      expect(find.text('Blinding Lights'), findsNothing);
      expect(find.text(navigatedTo(RouteNames.spotify)), findsNothing);
    });
  });
}
