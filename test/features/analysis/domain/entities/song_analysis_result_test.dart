import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/song_analysis_result.dart';

SongMoodResult _mood({
  String primaryMood = 'Calm',
  double confidence = 0.9,
  double valence = 0.3,
  double energy = 0.2,
}) => SongMoodResult(
  primaryMood: primaryMood,
  confidence: confidence,
  valence: valence,
  energy: energy,
);

SongAudioFeatures _features({
  double tempo = 90,
  double energy = 0.2,
  double valence = 0.3,
  double danceability = 0.4,
  double loudness = -7,
}) => SongAudioFeatures(
  tempo: tempo,
  energy: energy,
  valence: valence,
  danceability: danceability,
  loudness: loudness,
);

SongAnalysisResult _result({
  String trackName = 'Song',
  String artistName = 'Singer',
  String? trackId = 'trk',
  SongMoodResult? mood,
  SongAudioFeatures? features,
  bool success = true,
  String message = 'ok',
}) => SongAnalysisResult(
  trackName: trackName,
  artistName: artistName,
  trackId: trackId,
  mood: mood ?? _mood(),
  features: features ?? _features(),
  success: success,
  message: message,
);

void main() {
  group('SongMoodResult', () {
    test('equality and props', () {
      expect(_mood(), _mood());
      expect(_mood().props, ['Calm', 0.9, 0.3, 0.2]);
      for (final v in [
        _mood(primaryMood: 'x'),
        _mood(confidence: 0),
        _mood(valence: 0),
        _mood(energy: 0),
      ]) {
        expect(v, isNot(_mood()));
      }
    });
  });

  group('SongAudioFeatures', () {
    test('equality and props', () {
      expect(_features(), _features());
      expect(_features().props, [90.0, 0.2, 0.3, 0.4, -7.0]);
      for (final v in [
        _features(tempo: 0),
        _features(energy: 0),
        _features(valence: 0),
        _features(danceability: 0),
        _features(loudness: 0),
      ]) {
        expect(v, isNot(_features()));
      }
    });
  });

  group('SongAnalysisResult', () {
    test('message defaults to empty string', () {
      final result = SongAnalysisResult(
        trackName: 'a',
        artistName: 'b',
        trackId: null,
        mood: _mood(),
        features: _features(),
        success: false,
      );

      expect(result.message, '');
    });

    test('equality and props', () {
      expect(_result(), _result());
      expect(_result().hashCode, _result().hashCode);
      expect(_result().props, [
        'Song',
        'Singer',
        'trk',
        _mood(),
        _features(),
        true,
        'ok',
      ]);
    });

    test('every field participates in equality', () {
      for (final v in [
        _result(trackName: 'x'),
        _result(artistName: 'x'),
        _result(trackId: null),
        _result(mood: _mood(primaryMood: 'Sad')),
        _result(features: _features(tempo: 1)),
        _result(success: false),
        _result(message: 'x'),
      ]) {
        expect(v, isNot(_result()));
      }
    });
  });
}
