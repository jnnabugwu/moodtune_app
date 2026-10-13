import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/data/models/track_analysis_model.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

import '../analysis_data_fixtures.dart';

void main() {
  group('TrackAnalysisModel', () {
    test('fromJson parses every field', () {
      final model = TrackAnalysisModel.fromJson(trackJson());

      expect(model.trackId, 't1');
      expect(model.trackName, 'Track One');
      expect(model.artists, ['Artist A', 'Artist B']);
      expect(model.valence, 0.7);
      expect(model.energy, 1.0);
      expect(model.energy, isA<double>());
      expect(model.danceability, 0.55);
      expect(model.moodLabel, 'happy');
    });

    test('fromJson falls back to empty defaults for missing fields', () {
      final model = TrackAnalysisModel.fromJson(<String, dynamic>{
        'track_id': null,
        'artists': null,
      });

      expect(model.trackId, '');
      expect(model.trackName, '');
      expect(model.artists, isEmpty);
      expect(model.valence, 0);
      expect(model.energy, 0);
      expect(model.danceability, 0);
      expect(model.moodLabel, '');
    });

    test('toDomain maps every field', () {
      expect(
        TrackAnalysisModel.fromJson(trackJson()).toDomain(),
        const TrackAnalysis(
          trackId: 't1',
          trackName: 'Track One',
          artists: ['Artist A', 'Artist B'],
          valence: 0.7,
          energy: 1,
          danceability: 0.55,
          moodLabel: 'happy',
        ),
      );
    });
  });
}
