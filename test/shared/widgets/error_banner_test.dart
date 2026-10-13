import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/shared/widgets/error_banner.dart';

import '../../helpers/helpers.dart';

void main() {
  group('ErrorBanner', () {
    testWidgets('renders the message with a red error icon', (tester) async {
      await tester.pumpWidgetInShell(
        const ErrorBanner(message: 'Something went wrong'),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.exclamationmark_circle_fill),
      );
      expect(icon.color, const Color(0xFFC0392B));

      final text = tester.widget<Text>(find.text('Something went wrong'));
      expect(text.style?.color, const Color(0xFFC0392B));
    });

    testWidgets('wraps long messages instead of truncating', (tester) async {
      final longMessage = 'Network error. ' * 20;
      await tester.pumpWidgetInShell(ErrorBanner(message: longMessage));

      expect(find.text(longMessage), findsOneWidget);
      final text = tester.widget<Text>(find.text(longMessage));
      expect(text.maxLines, isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
