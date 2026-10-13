import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/shared/widgets/sign_up_strip.dart';

import '../../helpers/helpers.dart';

void main() {
  group('SignUpStrip', () {
    testWidgets('shows prompt copy and a Sign up button', (tester) async {
      await tester.pumpWidgetInShell(SignUpStrip(onSignUp: () {}));

      expect(find.text('Save this & see your history'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      expect(tester.getSize(find.byType(SignUpStrip)).height, 60);
    });

    testWidgets('invokes onSignUp when the button is tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidgetInShell(SignUpStrip(onSignUp: () => taps++));

      await tester.tap(find.text('Sign up'));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
