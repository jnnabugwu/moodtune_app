import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_features_summary.dart';

AudioFeaturesSummary _summary({
  double valence = 0.1,
  double energy = 0.2,
  double danceability = 0.3,
  double tempo = 120,
  double acousticness = 0.4,
  double instrumentalness = 0.5,
}) => AudioFeaturesSummary(
  valence: valence,
  energy: energy,
  danceability: danceability,
  tempo: tempo,
  acousticness: acousticness,
  instrumentalness: instrumentalness,
);

void main() {
  group('AudioFeaturesSummary', () {
    test('instances with equal values are equal', () {
      expect(_summary(), _summary());
      expect(_summary().hashCode, _summary().hashCode);
    });

    test('props lists fields in declaration order', () {
      expect(_summary().props, [0.1, 0.2, 0.3, 120.0, 0.4, 0.5]);
    });

    test('every field participates in equality', () {
      final variants = [
        _summary(valence: 9),
        _summary(energy: 9),
        _summary(danceability: 9),
        _summary(tempo: 9),
        _summary(acousticness: 9),
        _summary(instrumentalness: 9),
      ];
      for (final v in variants) {
        expect(v, isNot(_summary()));
      }
    });
  });
}
