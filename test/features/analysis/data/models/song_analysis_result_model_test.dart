import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/data/models/song_analysis_result_model.dart';
import 'package:moodtune_app/features/analysis/domain/entities/song_analysis_result.dart';

import '../analysis_data_fixtures.dart';

void main() {
  group('SongMoodResultModel', () {
    test('fromJson parses fields and defaults missing ones', () {
      final full = SongMoodResultModel.fromJson(<String, dynamic>{
        'primary_mood': 'Calm',
        'confidence': 1,
        'valence': 0.3,
        'energy': 0.2,
      });
      expect(full.primaryMood, 'Calm');
      expect(full.confidence, 1.0);
      expect(full.valence, 0.3);
      expect(full.energy, 0.2);

      final empty = SongMoodResultModel.fromJson(<String, dynamic>{});
      expect(empty.primaryMood, '');
      expect(empty.confidence, 0);
      expect(empty.valence, 0);
      expect(empty.energy, 0);
    });
  });

  group('SongAudioFeaturesModel', () {
    test('fromJson parses fields and defaults missing ones', () {
      final full = SongAudioFeaturesModel.fromJson(<String, dynamic>{
        'tempo': 90,
        'energy': 0.2,
        'valence': 0.3,
        'danceability': 0.4,
        'loudness': -7.5,
      });
      expect(full.tempo, 90.0);
      expect(full.energy, 0.2);
      expect(full.valence, 0.3);
      expect(full.danceability, 0.4);
      expect(full.loudness, -7.5);

      final empty = SongAudioFeaturesModel.fromJson(<String, dynamic>{});
      expect(empty.tempo, 0);
      expect(empty.energy, 0);
      expect(empty.valence, 0);
      expect(empty.danceability, 0);
      expect(empty.loudness, 0);
    });
  });

  group('SongAnalysisResultModel', () {
    test('fromJson parses top-level and nested fields', () {
      final model = SongAnalysisResultModel.fromJson(songAnalysisJson());

      expect(model.trackName, 'Song');
      expect(model.artistName, 'Singer');
      expect(model.trackId, 'trk-1');
      expect(model.success, isTrue);
      expect(model.message, 'ok');
      expect(model.mood.primaryMood, 'Calm');
      expect(model.features.loudness, -7.5);
    });

    test('fromJson tolerates an empty payload', () {
      final model = SongAnalysisResultModel.fromJson(<String, dynamic>{});

      expect(model.trackName, '');
      expect(model.artistName, '');
      expect(model.trackId, isNull);
      expect(model.success, isFalse);
      expect(model.message, '');
      expect(model.mood.primaryMood, '');
      expect(model.features.tempo, 0);
    });

    test('message defaults to empty string in the constructor', () {
      const model = SongAnalysisResultModel(
        trackName: 'a',
        artistName: 'b',
        trackId: null,
        mood: SongMoodResultModel(
          primaryMood: 'x',
          confidence: 0,
          valence: 0,
          energy: 0,
        ),
        features: SongAudioFeaturesModel(
          tempo: 0,
          energy: 0,
          valence: 0,
          danceability: 0,
          loudness: 0,
        ),
        success: true,
      );

      expect(model.message, '');
      expect(model.toDomain().message, '');
    });

    test('toDomain maps every field including nested entities', () {
      expect(
        SongAnalysisResultModel.fromJson(songAnalysisJson()).toDomain(),
        const SongAnalysisResult(
          trackName: 'Song',
          artistName: 'Singer',
          trackId: 'trk-1',
          mood: SongMoodResult(
            primaryMood: 'Calm',
            confidence: 0.9,
            valence: 0.3,
            energy: 0.2,
          ),
          features: SongAudioFeatures(
            tempo: 90,
            energy: 0.2,
            valence: 0.3,
            danceability: 0.4,
            loudness: -7.5,
          ),
          success: true,
          message: 'ok',
        ),
      );
    });
  });
}
