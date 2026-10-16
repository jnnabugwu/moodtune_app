import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/mood_feedback/presentation/widgets/mood_feedback_prompt.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('MoodFeedbackPrompt', () {
    late int agrees;
    late List<MoodIdentity> disagrees;

    setUp(() {
      agrees = 0;
      disagrees = [];
    });

    Future<void> pump(WidgetTester tester, {MoodIdentity? displayedMood}) =>
        tester.pumpWidgetInShell(
          MoodFeedbackPrompt(
            onAgree: () => agrees++,
            onDisagree: disagrees.add,
            displayedMood: displayedMood,
          ),
        );

    Finder option(MoodIdentity mood) =>
        find.byKey(ValueKey('mood_feedback_option_${mood.name}'));

    const thanks = 'Thanks! That helps MoodTune learn.';

    testWidgets('asks the question with thumbs up and down', (tester) async {
      await pump(tester);

      expect(find.text('Does this feel right?'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.hand_thumbsup), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.hand_thumbsdown), findsOneWidget);
      expect(find.text('What does it feel like?'), findsNothing);
      expect(find.text(thanks), findsNothing);
    });

    testWidgets('thumbs up calls onAgree once and thanks the user', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsup));
      await tester.pumpAndSettle();

      expect(agrees, 1);
      expect(disagrees, isEmpty);
      expect(find.text(thanks), findsOneWidget);
      expect(find.text('Does this feel right?'), findsNothing);
      expect(find.byIcon(CupertinoIcons.hand_thumbsup), findsNothing);
    });

    testWidgets('thumbs down reveals all four buckets with mood labels', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsdown));
      await tester.pumpAndSettle();

      expect(find.text('What does it feel like?'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.hand_thumbsdown_fill), findsOneWidget);
      for (final mood in MoodIdentity.values) {
        expect(option(mood), findsOneWidget);
        expect(find.text(MoodTheme.shortLabel(mood)), findsOneWidget);
        expect(find.byIcon(MoodTheme.iconFor(mood)), findsOneWidget);
      }
      expect(agrees, 0);
      expect(disagrees, isEmpty);
    });

    testWidgets('picking a bucket calls onDisagree and thanks the user', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsdown));
      await tester.pumpAndSettle();
      await tester.tap(option(MoodIdentity.charged));
      await tester.pumpAndSettle();

      expect(disagrees, [MoodIdentity.charged]);
      expect(agrees, 0);
      expect(find.text(thanks), findsOneWidget);
      expect(option(MoodIdentity.serene), findsNothing);
    });

    testWidgets('leaves the displayed bucket out of the picker', (
      tester,
    ) async {
      await pump(tester, displayedMood: MoodIdentity.upbeat);

      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsdown));
      await tester.pumpAndSettle();

      expect(option(MoodIdentity.upbeat), findsNothing);
      expect(option(MoodIdentity.serene), findsOneWidget);
      expect(option(MoodIdentity.charged), findsOneWidget);
      expect(option(MoodIdentity.reflective), findsOneWidget);
    });

    testWidgets('tapping thumbs down again hides the picker', (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsdown));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsdown_fill));
      await tester.pumpAndSettle();

      expect(find.text('What does it feel like?'), findsNothing);
      expect(find.byIcon(CupertinoIcons.hand_thumbsdown), findsOneWidget);
    });

    testWidgets('can change its mind to thumbs up while picking', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsdown));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsup));
      await tester.pumpAndSettle();

      expect(agrees, 1);
      expect(disagrees, isEmpty);
      expect(find.text(thanks), findsOneWidget);
    });

    testWidgets('cannot be answered twice (rapid double tap)', (tester) async {
      await pump(tester);

      final thumbsUp = find.byIcon(CupertinoIcons.hand_thumbsup);
      await tester.tap(thumbsUp);
      // Second tap before the rebuild lands on the same, now-answered state.
      await tester.tap(thumbsUp, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(agrees, 1);
      expect(find.byType(CupertinoButton), findsNothing);
    });

    testWidgets('shows the thank-you immediately with reduced motion', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pump(tester);

      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsup));
      await tester.pump();

      expect(find.text(thanks), findsOneWidget);
    });

    testWidgets('exposes accessible labels', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      expect(find.bySemanticsLabel('Yes, this feels right'), findsOneWidget);
      expect(find.bySemanticsLabel('No, this feels off'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.hand_thumbsdown));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          'SERENE, ${MoodTheme.quadrantLabel(MoodIdentity.serene)}',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
