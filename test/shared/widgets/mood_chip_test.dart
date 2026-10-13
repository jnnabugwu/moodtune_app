import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/shared/widgets/mood_chip.dart';

import '../../helpers/helpers.dart';

void main() {
  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(MoodChip),
        matching: find.byType(AnimatedContainer),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  group('MoodChip', () {
    for (final mood in MoodIdentity.values) {
      testWidgets('selected $mood chip is filled with the mood accent', (
        tester,
      ) async {
        await tester.pumpWidgetInShell(
          Center(
            child: MoodChip(label: 'Label', mood: mood, isSelected: true),
          ),
        );

        final accent = MoodTheme.colorsFor(mood).accent;
        final decoration = decorationOf(tester);
        expect(decoration.color, accent);
        expect((decoration.border! as Border).top.color, accent);
        final text = tester.widget<Text>(find.text('Label'));
        expect(text.style?.color, CupertinoColors.white);
      });
    }

    testWidgets('unselected chip renders as a neutral ghost chip', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        const Center(
          child: MoodChip(label: 'Calm', mood: MoodIdentity.serene),
        ),
      );

      final decoration = decorationOf(tester);
      expect(decoration.color, CupertinoColors.tertiarySystemFill);
      expect(
        (decoration.border! as Border).top.color,
        CupertinoColors.separator,
      );
      final text = tester.widget<Text>(find.text('Calm'));
      expect(text.style?.color, CupertinoColors.label);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidgetInShell(
        Center(
          child: MoodChip(
            label: 'Upbeat',
            mood: MoodIdentity.upbeat,
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Upbeat'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('tapping without onTap does nothing', (tester) async {
      await tester.pumpWidgetInShell(
        const Center(
          child: MoodChip(label: 'Charged', mood: MoodIdentity.charged),
        ),
      );

      await tester.tap(find.text('Charged'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('animates between selected and unselected styles', (
      tester,
    ) async {
      Widget build({required bool selected}) => Center(
        child: MoodChip(
          label: 'Mood',
          mood: MoodIdentity.charged,
          isSelected: selected,
        ),
      );

      await tester.pumpWidgetInShell(build(selected: false));
      await tester.pumpWidgetInShell(build(selected: true));
      await tester.pumpAndSettle();

      expect(
        decorationOf(tester).color,
        MoodTheme.colorsFor(MoodIdentity.charged).accent,
      );
    });
  });
}
