import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/analysis_disclaimer_sheet.dart';

import '../../../../helpers/helpers.dart';

void main() {
  Future<Future<bool?>> open(
    WidgetTester tester, {
    int? minTracks,
    int? maxTracks,
  }) async {
    late Future<bool?> result;
    await tester.pumpWidgetInShell(
      Builder(
        builder: (context) => Center(
          child: CupertinoButton(
            onPressed: () {
              result = minTracks == null || maxTracks == null
                  ? showAnalysisDisclaimerSheet(context)
                  : showAnalysisDisclaimerSheet(
                      context,
                      minTracks: minTracks,
                      maxTracks: maxTracks,
                    );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  group('showAnalysisDisclaimerSheet', () {
    testWidgets('shows default requirements', (tester) async {
      await open(tester);

      expect(find.text('Analyze Playlist'), findsOneWidget);
      expect(
        find.text('We will analyze your playlist to uncover its overall mood.'),
        findsOneWidget,
      );
      expect(find.text('Requirements'), findsOneWidget);
      expect(
        find.text('• Playlist must have at least 5 tracks.'),
        findsOneWidget,
      );
      expect(
        find.text('• We analyze up to 50 tracks for speed.'),
        findsOneWidget,
      );
    });

    testWidgets('shows custom track limits', (tester) async {
      await open(tester, minTracks: 3, maxTracks: 20);

      expect(
        find.text('• Playlist must have at least 3 tracks.'),
        findsOneWidget,
      );
      expect(
        find.text('• We analyze up to 20 tracks for speed.'),
        findsOneWidget,
      );
    });

    testWidgets('Analyze now resolves to true', (tester) async {
      final result = await open(tester);

      await tester.tap(find.text('Analyze now'));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
      expect(find.text('Analyze Playlist'), findsNothing);
    });

    testWidgets('Cancel resolves to false', (tester) async {
      final result = await open(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await result, isFalse);
      expect(find.text('Analyze Playlist'), findsNothing);
    });
  });
}
