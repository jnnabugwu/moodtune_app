import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/shared/widgets/toast_notice.dart';

import '../../helpers/helpers.dart';

void main() {
  group('showToastNotice', () {
    Future<void> show(WidgetTester tester) async {
      await tester.pumpWidgetInShell(
        Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => showToastNotice(context, message: 'Done'),
            child: const Text('Show'),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
    }

    testWidgets('fades in, stays, then removes itself', (tester) async {
      await show(tester);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Done'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(ToastNotice), findsNothing);
    });

    testWidgets('lets taps through to the page underneath', (tester) async {
      await show(tester);
      expect(find.text('Done'), findsOneWidget);

      // Tapping again shows a second notice, so the first did not block it.
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsNWidgets(2));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(ToastNotice), findsNothing);
    });

    testWidgets('cancels its timer when the app goes away', (tester) async {
      await show(tester);

      await tester.pumpWidget(const SizedBox());
      // Past the 2 s hold: a live timer would fire on a disposed controller.
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(ToastNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
