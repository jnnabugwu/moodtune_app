import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';
import 'package:moodtune_app/features/on_device_mood/domain/yamnet_mood_model.dart';

/// The shipped config, so the test fails if the asset and logic drift apart.
YamnetMoodModel shippedModel() => YamnetMoodModel.fromJson(
  jsonDecode(File('assets/models/yamnet_mood.json').readAsStringSync())
      as Map<String, Object?>,
);

ClassScores scoresFrom(Map<String, Object?> track) => ClassScores(
  mean: Float32List.fromList((track['mean']! as List).cast<double>()),
  peak: Float32List.fromList((track['peak']! as List).cast<double>()),
);

void main() {
  final golden =
      jsonDecode(
            File(
              'test/features/on_device_mood/fixtures/yamnet_golden.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  final tracks = (golden['tracks']! as List).cast<Map<String, Object?>>();
  final model = shippedModel();

  group('YamnetMoodModel matches the Python pipeline', () {
    for (final track in tracks) {
      final expected = track['expected']! as Map<String, Object?>;

      test('${track['track']} → ${expected['primaryMood']}', () {
        final mood = model.interpret(scoresFrom(track));

        expect(mood.primaryMood, expected['primaryMood']);
        expect(mood.tags, expected['tags']);
        final probabilities = expected['probabilities']! as Map;
        for (final MapEntry(:key, :value) in probabilities.entries) {
          expect(
            mood.probabilities[key],
            closeTo(value as double, 1e-4),
            reason: key as String,
          );
        }
      });

      test('${track['track']} tags with a cutoff', () {
        final mood = model
            .withTagThreshold(golden['threshold']! as double)
            .interpret(scoresFrom(track));

        expect(mood.tags, track['expectedTagsAtThreshold']);
      });
    }

    test('covers every mood label', () {
      final labels = {
        for (final t in tracks)
          (t['expected']! as Map<String, Object?>)['primaryMood'],
      };
      expect(labels, {'happy', 'energetic', 'calm', 'angry', 'sad'});
    });
  });

  group('YamnetMoodModel', () {
    YamnetMoodModel tiny({double? threshold, int maxTags = 2}) =>
        YamnetMoodModel(
          moodClasses: const [
            (index: 0, label: 'happy'),
            (index: 1, label: 'sad'),
          ],
          logScoreMeans: const {'happy': 0, 'sad': 0},
          epsilon: 1e-9,
          tagClasses: const [
            (index: 2, tag: 'vocals'),
            (index: 3, tag: 'vocals'),
            (index: 4, tag: 'piano'),
            (index: 5, tag: 'drums'),
          ],
          tagThreshold: threshold,
          maxTags: maxTags,
        );

    ClassScores scores(List<double> mean, List<double> peak) => ClassScores(
      mean: Float32List.fromList(mean),
      peak: Float32List.fromList(peak),
    );

    test('picks the label with the higher calibrated score', () {
      final mood = tiny().interpret(
        scores([0.2, 0.6, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0]),
      );

      expect(mood.primaryMood, 'sad');
      expect(mood.probabilities['sad'], closeTo(0.75, 1e-6));
      expect(mood.probabilities['happy'], closeTo(0.25, 1e-6));
    });

    test('merges classes that share a tag and keeps the strongest', () {
      final mood = tiny(maxTags: 3).interpret(
        scores([0.5, 0.5, 0.1, 0.9, 0.5, 0.3], [0.5, 0.5, 0.1, 0.9, 0.5, 0.3]),
      );

      expect(mood.tags, ['vocals', 'piano', 'drums']);
    });

    test('drops tags below the threshold', () {
      final mood = tiny(threshold: 0.4, maxTags: 3).interpret(
        scores([0.5, 0.5, 0, 0, 0.5, 0.3], [0.5, 0.5, 0, 0, 0.5, 0.3]),
      );

      expect(mood.tags, ['piano']);
    });

    test('breaks score ties by allowlist order', () {
      final mood = tiny().interpret(
        scores([0.5, 0.5, 0, 0, 0.4, 0.4], [0.5, 0.5, 0, 0, 0.4, 0.4]),
      );

      expect(mood.tags, ['piano', 'drums']);
    });

    test('survives zero scores', () {
      final mood = tiny().interpret(
        scores(List.filled(6, 0), List.filled(6, 0)),
      );

      expect(mood.probabilities.values.every((p) => p.isFinite), isTrue);
    });

    test('rejects a malformed config', () {
      expect(
        () => YamnetMoodModel.fromJson(const {'mood': <String, Object?>{}}),
        throwsFormatException,
      );
      expect(
        () => YamnetMoodModel.fromJson(const {
          'mood': {
            'classes': [
              {'index': 'x', 'label': 'happy'},
            ],
            'logScoreMeans': <String, Object?>{},
            'epsilon': 1e-9,
          },
          'tags': {'classes': <Object?>[], 'threshold': null, 'max': 3},
        }),
        throwsFormatException,
      );
    });

    test('loads the shipped config', () {
      expect(model.moodClasses, hasLength(5));
      expect(model.tagClasses, hasLength(61));
      expect(model.tagThreshold, isNull);
      expect(model.maxTags, 3);
    });
  });
}
