import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/mood_feedback/mood_feedback.dart';
import 'package:moodtune_app/features/mood_feedback/presentation/mood_observation_recorder.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/mood_switchover.dart';

import '../../../shared/widget_fixtures.dart';

class MockRepository extends Mock implements MoodObservationRepository {}

const _attempt = OnDeviceMoodAttempt(
  mood: OnDeviceMood(
    primaryMood: 'sad',
    probabilities: {'sad': 0.9, 'happy': 0.1},
    tags: ['piano'],
  ),
  elapsed: Duration(milliseconds: 140),
);

void main() {
  late MockRepository repository;
  late MoodObservationRecorder recorder;
  final backend = buildAudioUploadAnalysis();

  setUpAll(() {
    registerFallbackValue(
      const MoodObservation(
        id: 'x',
        source: MoodObservationSource.upload,
        backendMood: 'happy',
        displayedMood: 'happy',
        displayedSource: DisplayedMoodSource.backend,
      ),
    );
  });

  setUp(() {
    repository = MockRepository();
    recorder = MoodObservationRecorder(repository: repository);
    when(
      () => repository.record(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.sendFeedback(
        id: any(named: 'id'),
        agrees: any(named: 'agrees'),
        userMood: any(named: 'userMood'),
      ),
    ).thenAnswer((_) async => const Right(null));
  });

  MoodObservation recorded() =>
      verify(() => repository.record(captureAny())).captured.single
          as MoodObservation;

  group('record', () {
    test('stores the backend and on-device moods side by side', () {
      final displayed = MoodSwitchover.apply(backend, _attempt);

      final id = recorder.record(
        source: MoodObservationSource.catalog,
        backendMood: 'happy',
        displayed: displayed,
        attempt: _attempt,
      );

      final observation = recorded();
      expect(observation.id, id);
      expect(observation.source, MoodObservationSource.catalog);
      expect(observation.analysisId, backend.id);
      expect(observation.backendMood, 'happy');
      expect(observation.onDeviceMood, 'sad');
      expect(observation.onDeviceTags, ['piano']);
      expect(observation.onDeviceProbabilities, {'sad': 0.9, 'happy': 0.1});
      expect(observation.onDeviceLatencyMs, 140);
      expect(observation.onDeviceError, isNull);
      expect(observation.displayedMood, 'sad');
      expect(observation.displayedSource, DisplayedMoodSource.onDevice);
    });

    test('records a failed attempt with its reason and no latency', () {
      recorder.record(
        source: MoodObservationSource.upload,
        backendMood: 'happy',
        displayed: backend,
        attempt: const OnDeviceMoodAttempt(
          elapsed: Duration(seconds: 5),
          failure: 'timeout',
        ),
      );

      final observation = recorded();
      expect(observation.onDeviceMood, isNull);
      expect(observation.onDeviceLatencyMs, isNull);
      expect(observation.onDeviceError, 'timeout');
      expect(observation.displayedSource, DisplayedMoodSource.backend);
    });

    test('truncates long errors to what the backend accepts', () {
      recorder.record(
        source: MoodObservationSource.upload,
        backendMood: 'happy',
        displayed: backend,
        attempt: OnDeviceMoodAttempt(
          elapsed: Duration.zero,
          failure: 'x' * 900,
        ),
      );

      expect(recorded().onDeviceError, hasLength(500));
    });

    test('gives each result its own id', () {
      final a = recorder.record(
        source: MoodObservationSource.upload,
        backendMood: 'happy',
        displayed: backend,
      );
      final b = recorder.record(
        source: MoodObservationSource.upload,
        backendMood: 'happy',
        displayed: backend,
      );

      expect(a, isNot(b));
    });
  });

  group('sendFeedback', () {
    test('waits for the observation to be stored before sending', () async {
      final stored = Completer<Either<Failure, void>>();
      when(() => repository.record(any())).thenAnswer((_) => stored.future);
      final id = recorder.record(
        source: MoodObservationSource.upload,
        backendMood: 'happy',
        displayed: backend,
      );

      final sending = recorder.sendFeedback(
        id,
        agrees: false,
        userMood: MoodIdentity.reflective,
      );
      await Future<void>.delayed(Duration.zero);
      verifyNever(
        () => repository.sendFeedback(
          id: any(named: 'id'),
          agrees: any(named: 'agrees'),
          userMood: any(named: 'userMood'),
        ),
      );

      stored.complete(const Right(null));
      await sending;
      verify(
        () => repository.sendFeedback(
          id: id,
          agrees: false,
          userMood: MoodIdentity.reflective,
        ),
      ).called(1);
    });

    test('drops feedback when the observation was not stored', () async {
      when(
        () => repository.record(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('down')));
      final id = recorder.record(
        source: MoodObservationSource.upload,
        backendMood: 'happy',
        displayed: backend,
      );

      await recorder.sendFeedback(id, agrees: true);

      verifyNever(
        () => repository.sendFeedback(
          id: any(named: 'id'),
          agrees: any(named: 'agrees'),
          userMood: any(named: 'userMood'),
        ),
      );
    });

    test('drops feedback for an unknown id', () async {
      await recorder.sendFeedback('nope', agrees: true);

      verifyNever(
        () => repository.sendFeedback(
          id: any(named: 'id'),
          agrees: any(named: 'agrees'),
          userMood: any(named: 'userMood'),
        ),
      );
    });

    test('swallows a failed send', () async {
      when(
        () => repository.sendFeedback(
          id: any(named: 'id'),
          agrees: any(named: 'agrees'),
          userMood: any(named: 'userMood'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('down')));
      final id = recorder.record(
        source: MoodObservationSource.upload,
        backendMood: 'happy',
        displayed: backend,
      );

      await expectLater(recorder.sendFeedback(id, agrees: true), completes);
      verify(() => repository.sendFeedback(id: id, agrees: true)).called(1);
    });
  });
}
