import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/shared/widgets/bottom_sheet_base.dart';

import '../../helpers/helpers.dart';

void main() {
  group('MoodTuneBottomSheet', () {
    testWidgets('renders its child below a drag handle', (tester) async {
      await tester.pumpWidgetInShell(
        const Align(
          alignment: Alignment.bottomCenter,
          child: MoodTuneBottomSheet(child: Text('Sheet body')),
        ),
      );

      expect(find.text('Sheet body'), findsOneWidget);
      final handle = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints ==
                const BoxConstraints.tightFor(width: 36, height: 4),
      );
      expect(handle, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Sheet body')).dy,
        greaterThan(tester.getTopLeft(handle).dy),
      );
    });

    testWidgets('applies custom content padding', (tester) async {
      await tester.pumpWidgetInShell(
        const Align(
          alignment: Alignment.bottomCenter,
          child: MoodTuneBottomSheet(
            contentPadding: EdgeInsets.all(40),
            child: Text('Padded'),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .ancestor(of: find.text('Padded'), matching: find.byType(Padding))
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(40));
    });
  });

  group('showMoodTuneBottomSheet', () {
    Widget launcher(void Function(BuildContext) onPressed) {
      return Builder(
        builder: (context) => Center(
          child: CupertinoButton(
            onPressed: () => onPressed(context),
            child: const Text('open'),
          ),
        ),
      );
    }

    testWidgets('presents the sheet and returns the popped value', (
      tester,
    ) async {
      Future<String?>? result;
      await tester.pumpWidgetInShell(
        launcher((context) {
          result = showMoodTuneBottomSheet<String>(
            context: context,
            child: Builder(
              builder: (sheetContext) => CupertinoButton(
                onPressed: () => Navigator.of(sheetContext).pop('picked'),
                child: const Text('pick'),
              ),
            ),
          );
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(MoodTuneBottomSheet), findsOneWidget);

      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      expect(find.byType(MoodTuneBottomSheet), findsNothing);
      expect(await result, 'picked');
    });

    testWidgets('dismissible sheet closes on barrier tap with null result', (
      tester,
    ) async {
      Future<String?>? result;
      await tester.pumpWidgetInShell(
        launcher((context) {
          result = showMoodTuneBottomSheet<String>(
            context: context,
            child: const Text('content'),
          );
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('content'), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('non-dismissible sheet ignores barrier taps', (tester) async {
      await tester.pumpWidgetInShell(
        launcher((context) {
          unawaited(
            showMoodTuneBottomSheet<void>(
              context: context,
              isDismissible: false,
              child: const Text('content'),
            ),
          );
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('content'), findsOneWidget);
    });
  });
}
