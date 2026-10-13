import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/catalog/presentation/widgets/catalog_track_card.dart';

import '../../../../helpers/helpers.dart';
import '../../../../shared/widget_fixtures.dart';

void main() {
  group('CatalogTrackCard', () {
    testWidgets('shows name, artist with m:ss duration and up to two tags', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        CatalogTrackCard(
          track: buildJamendoTrack(tags: ['pop', 'upbeat', 'summer']),
          onAnalyzeTap: () {},
        ),
      );

      expect(find.text('Sunny Day'), findsOneWidget);
      expect(find.text('The Testers · 3:05'), findsOneWidget);
      expect(find.text('pop'), findsOneWidget);
      expect(find.text('upbeat'), findsOneWidget);
      expect(find.text('summer'), findsNothing);
      expect(find.text('Analyze →'), findsOneWidget);
    });

    testWidgets('pads seconds and handles sub-minute durations', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        CatalogTrackCard(
          track: buildJamendoTrack(duration: const Duration(seconds: 9)),
          onAnalyzeTap: () {},
        ),
      );

      expect(find.text('The Testers · 0:09'), findsOneWidget);
    });

    testWidgets('omits the tag row when there are no tags', (tester) async {
      await tester.pumpWidgetInShell(
        CatalogTrackCard(
          track: buildJamendoTrack(tags: const []),
          onAnalyzeTap: () {},
        ),
      );

      expect(find.text('pop'), findsNothing);
      expect(find.text('Sunny Day'), findsOneWidget);
    });

    testWidgets('truncates names longer than 28 characters', (tester) async {
      await tester.pumpWidgetInShell(
        CatalogTrackCard(
          track: buildJamendoTrack(
            name: 'A Remarkably Long Track Name That Goes On',
          ),
          onAnalyzeTap: () {},
        ),
      );

      expect(find.text('A Remarkably Long Track Name…'), findsOneWidget);
    });

    testWidgets('shows a placeholder when there is no album art', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        CatalogTrackCard(track: buildJamendoTrack(), onAnalyzeTap: () {}),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(CupertinoIcons.music_note), findsOneWidget);
    });

    testWidgets('falls back to placeholder when album art fails to load', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        CatalogTrackCard(
          track: buildJamendoTrack(
            albumImageUrl: 'https://example.com/art.jpg',
          ),
          onAnalyzeTap: () {},
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      // flutter_test's HttpClient returns 400 for every request, so the
      // errorBuilder is used.
      await tester.pumpAndSettle();
      expect(find.byIcon(CupertinoIcons.music_note), findsOneWidget);
    });

    testWidgets('invokes onAnalyzeTap when the Analyze button is tapped', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidgetInShell(
        CatalogTrackCard(
          track: buildJamendoTrack(),
          onAnalyzeTap: () => taps++,
        ),
      );

      await tester.tap(find.text('Analyze →'));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
