import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/painting.dart';
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
    repository = MockShareRepository();
    renderer = MockShareCardRenderer();
    when(
      () => renderer.render(content),
    ).thenAnswer((_) async => testShareImage);
  });

  void stubAvailability({bool instagram = true, bool x = true}) {
    when(
      () => repository.isAvailable(ShareTarget.instagramStory),
    ).thenAnswer((_) async => instagram);
    when(
      () => repository.isAvailable(ShareTarget.x),
    ).thenAnswer((_) async => x);
    when(
      () => repository.isAvailable(ShareTarget.system),
    ).thenAnswer((_) async => true);
  }

  ShareBloc buildBloc() => ShareBloc(
    repository: repository,
    renderer: renderer,
    captionBuilder: (_, target) => testShareCaption(target),
  );

  ShareState ready(List<ShareTarget> targets) =>
      ShareState(status: ShareStatus.ready, content: content, targets: targets);

  test('initial state', () {
    expect(buildBloc().state, const ShareState());
  });

  group('ShareOpened', () {
    blocTest<ShareBloc, ShareState>(
      'lists installed targets plus "More…" (R1)',
      setUp: stubAvailability,
      build: buildBloc,
      act: (bloc) => bloc.add(ShareOpened(content)),
      expect: () => [
        ShareState(status: ShareStatus.loadingTargets, content: content),
        ready(ShareTarget.values),
      ],
    );

    blocTest<ShareBloc, ShareState>(
      'hides Instagram when it is not available',
      setUp: () => stubAvailability(instagram: false),
      build: buildBloc,
      act: (bloc) => bloc.add(ShareOpened(content)),
      expect: () => [
        ShareState(status: ShareStatus.loadingTargets, content: content),
        ready(const [ShareTarget.x, ShareTarget.system]),
      ],
    );
  });

  group('ShareTargetSelected', () {
    const origin = Rect.fromLTWH(1, 2, 3, 4);

    blocTest<ShareBloc, ShareState>(
      'renders the card, shares it and ends done (R3)',
      setUp: () => when(
        () => repository.share(any()),
      ).thenAnswer((_) async => const Right(ShareOutcome.completed)),
      build: buildBloc,
      seed: () => ready(ShareTarget.values),
      act: (bloc) => bloc.add(
        const ShareTargetSelected(ShareTarget.system, origin: origin),
      ),
      expect: () => [
        ready(ShareTarget.values).copyWith(
          status: ShareStatus.sharing,
          activeTarget: ShareTarget.system,
        ),
        ready(ShareTarget.values).copyWith(
          status: ShareStatus.done,
          activeTarget: ShareTarget.system,
          outcome: ShareOutcome.completed,
        ),
      ],
      verify: (_) {
        final request =
            verify(() => repository.share(captureAny())).captured.single
                as ShareRequest;
        expect(request.target, ShareTarget.system);
        expect(request.image, testShareImage);
        expect(request.caption, testShareCaption(ShareTarget.system));
        expect(request.sharePositionOrigin, origin);
        // Charged gradient: deep purple → electric red (D3).
        expect(request.backgroundTopColor, 0xFF2D1B69);
        expect(request.backgroundBottomColor, 0xFFC0392B);
        verify(() => renderer.render(content)).called(1);
      },
    );

    blocTest<ShareBloc, ShareState>(
      'a cancelled share ends done with dismissed, no failure (R10)',
      setUp: () => when(
        () => repository.share(any()),
      ).thenAnswer((_) async => const Right(ShareOutcome.dismissed)),
      build: buildBloc,
      seed: () => ready(ShareTarget.values),
      act: (bloc) => bloc.add(const ShareTargetSelected(ShareTarget.x)),
      expect: () => [
        ready(
          ShareTarget.values,
        ).copyWith(status: ShareStatus.sharing, activeTarget: ShareTarget.x),
        ready(ShareTarget.values).copyWith(
          status: ShareStatus.done,
          activeTarget: ShareTarget.x,
          outcome: ShareOutcome.dismissed,
        ),
      ],
    );

    blocTest<ShareBloc, ShareState>(
      'a repository failure ends in failure and keeps the targets',
      setUp: () => when(
        () => repository.share(any()),
      ).thenAnswer((_) async => const Left(ShareFailure('rejected'))),
      build: buildBloc,
      seed: () => ready(ShareTarget.values),
      act: (bloc) =>
          bloc.add(const ShareTargetSelected(ShareTarget.instagramStory)),
      expect: () => [
        ready(ShareTarget.values).copyWith(
          status: ShareStatus.sharing,
          activeTarget: ShareTarget.instagramStory,
        ),
        ready(ShareTarget.values).copyWith(
          status: ShareStatus.failure,
          activeTarget: ShareTarget.instagramStory,
          failure: const ShareFailure('rejected'),
        ),
      ],
    );

    blocTest<ShareBloc, ShareState>(
      'a render error ends in ShareRenderFailure without sharing (AC7)',
      setUp: () => when(
        () => renderer.render(content),
      ).thenThrow(StateError('no bytes')),
      build: buildBloc,
      seed: () => ready(ShareTarget.values),
      act: (bloc) => bloc.add(const ShareTargetSelected(ShareTarget.system)),
      expect: () => [
        ready(ShareTarget.values).copyWith(
          status: ShareStatus.sharing,
          activeTarget: ShareTarget.system,
        ),
        isA<ShareState>()
            .having((s) => s.status, 'status', ShareStatus.failure)
            .having((s) => s.failure, 'failure', isA<ShareRenderFailure>())
            .having((s) => s.targets, 'targets', ShareTarget.values),
      ],
      verify: (_) => verifyNever(() => repository.share(any())),
    );

    blocTest<ShareBloc, ShareState>(
      'renders once and reuses the card for a second target',
      setUp: () => when(
        () => repository.share(any()),
      ).thenAnswer((_) async => const Right(ShareOutcome.dismissed)),
      build: buildBloc,
      seed: () => ready(ShareTarget.values),
      act: (bloc) async {
        bloc.add(const ShareTargetSelected(ShareTarget.system));
        await bloc.stream.firstWhere((s) => s.status == ShareStatus.done);
        bloc.add(const ShareTargetSelected(ShareTarget.x));
      },
      verify: (_) {
        verify(() => renderer.render(content)).called(1);
        verify(() => repository.share(any())).called(2);
      },
    );

    blocTest<ShareBloc, ShareState>(
      'ignores a tap before the sheet has content',
      build: buildBloc,
      act: (bloc) => bloc.add(const ShareTargetSelected(ShareTarget.system)),
      expect: () => const <ShareState>[],
      verify: (_) => verifyNever(() => repository.share(any())),
    );
  });

  group('ShareState.copyWith', () {
    test('clears outcome and failure unless re-passed', () {
      final failed = ready(
        ShareTarget.values,
      ).copyWith(status: ShareStatus.failure, failure: const ShareFailure('x'));
      expect(failed.failure, const ShareFailure('x'));
      expect(failed.copyWith(status: ShareStatus.sharing).failure, isNull);
      expect(failed.copyWith(outcome: ShareOutcome.completed).failure, isNull);
    });
  });
}
