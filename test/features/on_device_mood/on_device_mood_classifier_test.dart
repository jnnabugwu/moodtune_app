import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/error/exceptions.dart';
import 'package:moodtune_app/features/on_device_mood/domain/decoded_audio.dart';
import 'package:moodtune_app/features/on_device_mood/domain/yamnet_mood_model.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/on_device_mood_classifier.dart';

final _audio = DecodedAudio(
  windows: [Float32List(4)],
  startSeconds: const [0],
  durationSeconds: 1,
  sampleRate: 16000,
  sourceSampleRate: 44100,
  channelCount: 2,
);

/// Index 0 → happy, 1 → sad; index 2 is the only tag class.
const _model = YamnetMoodModel(
  moodClasses: [(index: 0, label: 'happy'), (index: 1, label: 'sad')],
  logScoreMeans: {'happy': 0, 'sad': 0},
  epsilon: 1e-9,
  tagClasses: [(index: 2, tag: 'piano')],
  tagThreshold: null,
  maxTags: 3,
);

class FakeDecoder implements AudioWindowDecoder {
  FakeDecoder({this.error});

  final Exception? error;
  final paths = <String>[];

  @override
  Future<DecodedAudio> decodeWindows(String path) async {
    paths.add(path);
    if (error != null) throw error!;
    return _audio;
  }
}

class FakeEngine implements AudioClassifierEngine {
  FakeEngine({this.error, this.delay = Duration.zero});

  final Exception? error;
  final Duration delay;

  @override
  Future<ClassScores> score(DecodedAudio audio) async {
    await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return ClassScores(
      mean: Float32List.fromList([0.1, 0.4, 0.2]),
      peak: Float32List.fromList([0.1, 0.4, 0.2]),
    );
  }
}

void main() {
  group('OnDeviceMoodClassifier', () {
    test('decodes, scores and interprets the file', () async {
      final decoder = FakeDecoder();
      final classifier = OnDeviceMoodClassifier(
        decoder: decoder,
        engine: FakeEngine(),
        loadModel: () async => _model,
      );

      final mood = await classifier.classify('/song.mp3');

      expect(decoder.paths, ['/song.mp3']);
      expect(mood?.primaryMood, 'sad');
      expect(mood?.tags, ['piano']);
    });

    test('returns null when the file cannot be decoded', () async {
      final classifier = OnDeviceMoodClassifier(
        decoder: FakeDecoder(
          error: const AudioDecodeException('unreadable', 'nope'),
        ),
        engine: FakeEngine(),
        loadModel: () async => _model,
      );

      expect(await classifier.classify('/song.ogg'), isNull);
    });

    test('returns null when the model fails', () async {
      final classifier = OnDeviceMoodClassifier(
        decoder: FakeDecoder(),
        engine: FakeEngine(error: Exception('interpreter crashed')),
        loadModel: () async => _model,
      );

      expect(await classifier.classify('/song.mp3'), isNull);
    });

    test('returns null when it runs past the timeout', () async {
      final classifier = OnDeviceMoodClassifier(
        decoder: FakeDecoder(),
        engine: FakeEngine(delay: const Duration(milliseconds: 50)),
        loadModel: () async => _model,
        timeout: const Duration(milliseconds: 10),
      );

      expect(await classifier.classify('/song.mp3'), isNull);
    });

    test('loads the config once and reuses it', () async {
      var loads = 0;
      final classifier = OnDeviceMoodClassifier(
        decoder: FakeDecoder(),
        engine: FakeEngine(),
        loadModel: () async {
          loads++;
          return _model;
        },
      );

      await classifier.classify('/a.mp3');
      await classifier.classify('/b.mp3');

      expect(loads, 1);
    });

    test('retries loading the config after a failure', () async {
      var loads = 0;
      final classifier = OnDeviceMoodClassifier(
        decoder: FakeDecoder(),
        engine: FakeEngine(),
        loadModel: () async {
          if (loads++ == 0) throw const FormatException('bad config');
          return _model;
        },
      );

      expect(await classifier.classify('/a.mp3'), isNull);
      expect((await classifier.classify('/a.mp3'))?.primaryMood, 'sad');
      expect(loads, 2);
    });
  });
}
