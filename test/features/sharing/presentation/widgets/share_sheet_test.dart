import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/sharing/sharing.dart';

import '../../../../helpers/helpers.dart';
import '../../sharing_fixtures.dart';

void main() {
  late MockShareRepository repository;
  late MockShareCardRenderer renderer;
  final content = testShareContent();

  setUpAll(() {
    registerFallbackValue(testShareRequest(ShareTarget.system));
    talker.disable();
  });

  tearDownAll(talker.enable);

  setUp(() {
    final mocks = registerSharingMocks();
    repository = mocks.repository;
    renderer = mocks.renderer;
    when(
      () => renderer.render(content),
    ).thenAnswer((_) async => testShareImage);
  });

  void stubAvailability({bool instagram = true}) {
    when(
      () => repository.isAvailable(ShareTarget.instagramStory),
    ).thenAnswer((_) async => instagram);
  }

  /// Pumps a page with a button that opens the share sheet, then opens it.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => CupertinoPageScaffold(
          child: Center(
            child: CupertinoButton(
              onPressed: () => unawaited(showShareSheet(context, content)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('ShareSheet', () {
    testWidgets('lists installed targets plus "More…" (AC1)', (tester) async {
      stubAvailability();

      await openSheet(tester);

      expect(find.text('Share your result'), findsOneWidget);
      expect(find.text('Instagram Stories'), findsOneWidget);
      expect(find.text('X'), findsWidgets);
      expect(find.text('More…'), findsOneWidget);
    });

    testWidgets('hides Instagram Stories when it is not installed (R1)', (
      tester,
    ) async {
      stubAvailability(instagram: false);

      await openSheet(tester);

      expect(find.text('Instagram Stories'), findsNothing);
      expect(find.byKey(const ValueKey('share_target_x')), findsOneWidget);
      expect(find.text('More…'), findsOneWidget);
    });

    testWidgets('closes after a completed share', (tester) async {
      stubAvailability();
      when(
        () => repository.share(any()),
      ).thenAnswer((_) async => const Right(ShareOutcome.completed));

      await openSheet(tester);
      await tester.tap(find.text('More…'));
      await tester.pumpAndSettle();

      expect(find.text('Share your result'), findsNothing);
      expect(find.text('open'), findsOneWidget);
      final request =
          verify(() => repository.share(captureAny())).captured.single
              as ShareRequest;
      expect(request.target, ShareTarget.system);
      // The tapped row's rect anchors the iPad popover (R6).
      expect(request.sharePositionOrigin, isNotNull);
      expect(request.sharePositionOrigin!.width, greaterThan(0));
    });

    testWidgets('closes quietly when the user cancels (AC7)', (tester) async {
      stubAvailability();
      when(
        () => repository.share(any()),
      ).thenAnswer((_) async => const Right(ShareOutcome.dismissed));

      await openSheet(tester);
      await tester.tap(find.text('More…'));
      await tester.pumpAndSettle();

      expect(find.text('Share your result'), findsNothing);
      expect(find.byKey(const Key('share_failed_message')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows an inline message and stays open on failure (AC7)', (
      tester,
    ) async {
      stubAvailability();
      when(
        () => repository.share(any()),
      ).thenAnswer((_) async => const Left(ShareFailure('rejected')));

      await openSheet(tester);
      await tester.tap(find.text('Instagram Stories'));
      await tester.pumpAndSettle();

      expect(find.text('Share your result'), findsOneWidget);
      expect(find.byKey(const Key('share_failed_message')), findsOneWidget);
      expect(find.text("Couldn't share right now. Try again."), findsOneWidget);
      // Targets stay tappable for a retry.
      final row = tester.widget<CupertinoButton>(
        find.byKey(const ValueKey('share_target_system')),
      );
      expect(row.onPressed, isNotNull);
    });

    testWidgets('shows a render failure inline (AC7)', (tester) async {
      stubAvailability();
      when(() => renderer.render(content)).thenThrow(StateError('no bytes'));

      await openSheet(tester);
      await tester.tap(find.text('More…'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('share_failed_message')), findsOneWidget);
      verifyNever(() => repository.share(any()));
    });

    testWidgets('shows progress and disables rows while sharing', (
      tester,
    ) async {
      stubAvailability();
      final completer = Completer<Either<ShareFailure, ShareOutcome>>();
      when(() => repository.share(any())).thenAnswer((_) => completer.future);

      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('share_target_x')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Preparing your card…'), findsOneWidget);
      final row = tester.widget<CupertinoButton>(
        find.byKey(const ValueKey('share_target_system')),
      );
      expect(row.onPressed, isNull);

      completer.complete(const Right(ShareOutcome.completed));
      await tester.pumpAndSettle();
      expect(find.text('Share your result'), findsNothing);
    });
  });
}
