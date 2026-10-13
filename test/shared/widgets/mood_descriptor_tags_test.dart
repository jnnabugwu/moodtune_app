import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/shared/widgets/mood_descriptor_tags.dart';

import '../../helpers/helpers.dart';

void main() {
  group('MoodDescriptorTags', () {
    testWidgets('renders nothing when tags are empty', (tester) async {
      await tester.pumpWidgetInShell(const MoodDescriptorTags(tags: []));

      expect(
        find.descendant(
          of: find.byType(MoodDescriptorTags),
          matching: find.byType(Wrap),
        ),
        findsNothing,
      );
      expect(tester.getSize(find.byType(MoodDescriptorTags)), Size.zero);
    });

    testWidgets('renders one pill per tag inside a Wrap', (tester) async {
      await tester.pumpWidgetInShell(
        const MoodDescriptorTags(tags: ['upbeat', 'danceable', 'bright']),
      );

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('upbeat'), findsOneWidget);
      expect(find.text('danceable'), findsOneWidget);
      expect(find.text('bright'), findsOneWidget);

      final text = tester.widget<Text>(find.text('upbeat'));
      expect(text.style?.color, const Color(0xFF2D2A26));
    });

    testWidgets('wraps many tags onto multiple lines without overflow', (
      tester,
    ) async {
      final tags = List.generate(20, (i) => 'descriptor-$i');
      await tester.pumpWidgetInShell(MoodDescriptorTags(tags: tags));

      expect(tester.takeException(), isNull);
      final first = tester.getTopLeft(find.text('descriptor-0'));
      final last = tester.getTopLeft(find.text('descriptor-19'));
      expect(last.dy, greaterThan(first.dy));
    });
  });
}
