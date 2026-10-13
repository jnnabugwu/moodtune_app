import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/data/models/mood_result_model.dart';

import '../analysis_data_fixtures.dart';

void main() {
  group('MoodResultModel', () {
    test('fromJson parses scalars and nested models', () {
      final model = MoodResultModel.fromJson(moodResultJson());

      expect(model.primaryMood, 'Happy');
      expect(model.moodCategory, 'positive');
      expect(model.moodDescriptors, ['upbeat', 'bright']);
      expect(model.confidence, 0.87);
      expect(model.averages.tempo, 120);
      expect(model.averages.valence, 0.6);
      expect(model.moodDistribution.happy, 0.4);
      expect(model.topTracks, hasLength(2));
      expect(model.topTracks.map((t) => t.trackId), ['t1', 't2']);
      expect(model.trackCount, 25);
    });

    test('fromJson falls back to camelCase trackCount', () {
      final json = moodResultJson()
        ..remove('track_count')
        ..['trackCount'] = 7;

      expect(MoodResultModel.fromJson(json).trackCount, 7);
    });

    test('snake_case track_count wins over camelCase trackCount', () {
      final json = moodResultJson()..['trackCount'] = 99;

      expect(MoodResultModel.fromJson(json).trackCount, 25);
    });

    test('fromJson tolerates an empty payload', () {
      final model = MoodResultModel.fromJson(<String, dynamic>{});

      expect(model.primaryMood, '');
      expect(model.moodCategory, '');
      expect(model.moodDescriptors, isEmpty);
      expect(model.confidence, 0);
      expect(model.averages.valence, 0);
      expect(model.averages.tempo, 0);
      expect(model.moodDistribution.happy, 0);
      expect(model.topTracks, isEmpty);
      expect(model.trackCount, 0);
    });

    test('fromJson throws when track_count is not an int', () {
      // Documents current behaviour: a float count (e.g. 25.0) is rejected
      // by the `as int?` cast rather than coerced.
      final json = moodResultJson()..['track_count'] = 25.0;

      expect(() => MoodResultModel.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('toDomain maps scalars and converts nested models', () {
      final entity = MoodResultModel.fromJson(moodResultJson()).toDomain();

      expect(entity.primaryMood, 'Happy');
      expect(entity.moodCategory, 'positive');
      expect(entity.moodDescriptors, ['upbeat', 'bright']);
      expect(entity.confidence, 0.87);
      expect(entity.averages.energy, 0.8);
      expect(entity.averages.instrumentalness, 0.05);
      expect(entity.moodDistribution.energetic, 0.3);
      expect(entity.topTracks.map((t) => t.trackName), ['Track One', 'Two']);
      expect(entity.topTracks.first.artists, ['Artist A', 'Artist B']);
      expect(entity.trackCount, 25);
    });
  });
}
