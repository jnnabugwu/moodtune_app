import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/data/models/audio_features_summary_model.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

import '../analysis_data_fixtures.dart';

void main() {
  group('AudioFeaturesSummaryModel', () {
    test('fromJson parses every field and coerces ints to doubles', () {
      final model = AudioFeaturesSummaryModel.fromJson(averagesJson());

      expect(model.valence, 0.6);
      expect(model.energy, 0.8);
      expect(model.danceability, 0.5);
      expect(model.tempo, 120.0);
      expect(model.tempo, isA<double>());
      expect(model.acousticness, 0.1);
      expect(model.instrumentalness, 0.05);
    });

    test('fromJson defaults missing and null fields to 0', () {
      final model = AudioFeaturesSummaryModel.fromJson(<String, dynamic>{
        'valence': null,
      });

      expect(model.valence, 0);
      expect(model.energy, 0);
      expect(model.danceability, 0);
      expect(model.tempo, 0);
      expect(model.acousticness, 0);
      expect(model.instrumentalness, 0);
    });

    test('toDomain maps every field', () {
      final entity = AudioFeaturesSummaryModel.fromJson(
        averagesJson(),
      ).toDomain();

      expect(
        entity,
        const AudioFeaturesSummary(
          valence: 0.6,
          energy: 0.8,
          danceability: 0.5,
          tempo: 120,
          acousticness: 0.1,
          instrumentalness: 0.05,
        ),
      );
    });
  });
}
