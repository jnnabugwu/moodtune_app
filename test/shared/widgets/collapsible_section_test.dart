import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/shared/widgets/collapsible_section.dart';

import '../../helpers/helpers.dart';

void main() {
  double chevronTurns(WidgetTester tester) => tester
      .widget<RotationTransition>(
        find.descendant(
          of: find.byType(CollapsibleSection),
          matching: find.byType(RotationTransition),
        ),
      )
      .turns
      .value;

  group('CollapsibleSection', () {
    testWidgets('is collapsed by default and hides its child', (tester) async {
      await tester.pumpWidgetInShell(
        const CollapsibleSection(title: 'Details', child: Text('Body')),
      );

      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Body'), findsNothing);
      expect(chevronTurns(tester), 0);
    });

    testWidgets('initiallyExpanded shows child and rotated chevron', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(
        const CollapsibleSection(
          title: 'Details',
          initiallyExpanded: true,
          child: Text('Body'),
        ),
      );

      expect(find.text('Body'), findsOneWidget);
      expect(chevronTurns(tester), 0.5);
    });

    testWidgets('tapping the header expands then collapses', (tester) async {
      await tester.pumpWidgetInShell(
        const CollapsibleSection(title: 'Details', child: Text('Body')),
      );

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);
      expect(chevronTurns(tester), 0.5);

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
      expect(chevronTurns(tester), 0);
    });

    testWidgets('chevron rotation animates over 200ms', (tester) async {
      await tester.pumpWidgetInShell(
        const CollapsibleSection(title: 'Details', child: Text('Body')),
      );

      await tester.tap(find.text('Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = chevronTurns(tester);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(0.5));

      await tester.pump(const Duration(milliseconds: 150));
      expect(chevronTurns(tester), 0.5);
    });

    testWidgets('header is tappable across its full width', (tester) async {
      await tester.pumpWidgetInShell(
        const CollapsibleSection(title: 'Details', child: Text('Body')),
      );

      // Tap the empty space between title and chevron.
      final header = tester.getRect(find.byType(GestureDetector).first);
      await tester.tapAt(Offset(header.center.dx, header.center.dy));
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsOneWidget);
    });
  });
}
