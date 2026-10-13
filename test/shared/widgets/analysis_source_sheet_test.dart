import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/shared/widgets/analysis_source_sheet.dart';

import '../../helpers/helpers.dart';

void main() {
  final launcher = Builder(
    builder: (context) => CupertinoPageScaffold(
      child: Center(
        child: CupertinoButton(
          onPressed: () => showAnalysisSourceSheet(context),
          child: const Text('open'),
        ),
      ),
    ),
  );

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpApp(launcher);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('showAnalysisSourceSheet', () {
    testWidgets('shows title, message and both source options', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.text('Analyze a Song'), findsOneWidget);
      expect(
        find.text('Choose how you want to find your track.'),
        findsOneWidget,
      );
      expect(find.text('Browse Catalog'), findsOneWidget);
      expect(find.text('Upload a Song'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Browse Catalog closes the sheet and pushes the catalog', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Browse Catalog'));
      await tester.pumpAndSettle();

      expect(find.text('Analyze a Song'), findsNothing);
      expect(find.text(navigatedTo(RouteNames.catalog)), findsOneWidget);
    });

    testWidgets('Upload a Song closes the sheet and pushes upload screen', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Upload a Song'));
      await tester.pumpAndSettle();

      expect(find.text('Analyze a Song'), findsNothing);
      expect(find.text(navigatedTo(RouteNames.uploadMusic)), findsOneWidget);
    });

    testWidgets('Cancel closes the sheet without navigating', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Analyze a Song'), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(find.textContaining('navigated:'), findsNothing);
    });
  });
}
