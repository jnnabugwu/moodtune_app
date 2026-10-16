import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/mood_switchover.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/on_device_mood_classifier.dart';

import '../../shared/widget_fixtures.dart';

class MockClassifier extends Mock implements OnDeviceMoodClassifier {}

class MockDownloader extends Mock implements AudioDownloader {}

const _mood = OnDeviceMood(
  primaryMood: 'sad',
  probabilities: {'sad': 0.9, 'happy': 0.1},
  tags: ['vocals', 'piano'],
);
const _success = OnDeviceMoodAttempt(
  mood: _mood,
  elapsed: Duration(milliseconds: 120),
);

void main() {
  late MockClassifier classifier;
  late MockDownloader downloader;
  late bool enabled;

  setUp(() {
    classifier = MockClassifier();
    downloader = MockDownloader();
    enabled = true;
    when(() => classifier.attempt(any())).thenAnswer((_) async => _success);
  });

  MoodSwitchover build({Future<bool> Function()? isEnabled}) => MoodSwitchover(
    classifier: classifier,
    downloader: downloader,
    isEnabled: isEnabled ?? () async => enabled,
  );

  group('MoodSwitchover.apply', () {
    final backend = buildAudioUploadAnalysis(
      primaryMood: 'happy',
      confidence: 0.85,
    );

    test('swaps in the on-device mood, tags and reasoning', () {
      final result = MoodSwitchover.apply(backend, _success);

      expect(result.mood.primaryMood, 'sad');
      expect(result.mood.source, MoodSource.onDevice);
      expect(result.mood.soundTags, ['vocals', 'piano']);
      expect(result.mood.descriptors, isEmpty);
      expect(result.mood.backendPrimaryMood, 'happy');
      expect(result.mood.reasoning, onDeviceReasoning);
    });

    test("keeps the backend's features and metadata", () {
      final result = MoodSwitchover.apply(backend, _success);

      expect(result.id, backend.id);
      expect(result.mood.audioFeatures, backend.mood.audioFeatures);
      expect(result.mood.confidence, backend.mood.confidence);
    });

    test('leaves the backend result alone without an on-device mood', () {
      expect(MoodSwitchover.apply(backend, null), backend);
      expect(
        MoodSwitchover.apply(
          backend,
          const OnDeviceMoodAttempt(elapsed: Duration.zero, failure: 'x'),
        ),
        backend,
      );
    });
  });

  group('classifyFile', () {
    test('classifies the file when enabled', () async {
      final attempt = await build().classifyFile('/song.mp3');

      expect(attempt, _success);
      verify(() => classifier.attempt('/song.mp3')).called(1);
    });

    test('skips classification when the kill switch is off', () async {
      enabled = false;

      final attempt = await build().classifyFile('/song.mp3');

      expect(attempt.mood, isNull);
      expect(attempt.failure, 'disabled');
      verifyNever(() => classifier.attempt(any()));
    });

    test('treats a failing switch check as enabled', () async {
      final attempt = await build(
        isEnabled: () async => throw Exception('config down'),
      ).classifyFile('/song.mp3');

      expect(attempt, _success);
    });
  });

  group('classifyUrl', () {
    test('downloads, classifies and deletes the download', () async {
      final dir = await Directory.systemTemp.createTemp('switchover_test');
      final file = File('${dir.path}/track.mp3')..writeAsBytesSync([1, 2, 3]);
      when(
        () => downloader.download('https://audio'),
      ).thenAnswer((_) async => file);

      final attempt = await build().classifyUrl('https://audio');

      expect(attempt, _success);
      verify(() => classifier.attempt(file.path)).called(1);
      expect(dir.existsSync(), isFalse);
    });

    test('reports a failed download without classifying', () async {
      when(
        () => downloader.download(any()),
      ).thenThrow(const SocketException('offline'));

      final attempt = await build().classifyUrl('https://audio');

      expect(attempt.mood, isNull);
      expect(attempt.failure, startsWith('download:'));
      verifyNever(() => classifier.attempt(any()));
    });

    test('skips the download when the kill switch is off', () async {
      enabled = false;

      final attempt = await build().classifyUrl('https://audio');

      expect(attempt.failure, 'disabled');
      verifyNever(() => downloader.download(any()));
    });
  });
}
