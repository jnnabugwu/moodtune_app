import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

const _averages = AudioFeaturesSummary(
  valence: 0.1,
  energy: 0.2,
  danceability: 0.3,
  tempo: 100,
  acousticness: 0.4,
  instrumentalness: 0.5,
);

const _distribution = MoodDistribution(
  happy: 0.2,
  sad: 0.2,
  energetic: 0.2,
  calm: 0.2,
  danceable: 0.2,
);

const _track = TrackAnalysis(
  trackId: 't',
  trackName: 'n',
  artists: ['a'],
  valence: 0,
  energy: 0,
  danceability: 0,
  moodLabel: 'm',
);

MoodResult _result({
  String primaryMood = 'Happy',
  String moodCategory = 'positive',
  List<String> moodDescriptors = const ['upbeat'],
  double confidence = 0.9,
  AudioFeaturesSummary averages = _averages,
  MoodDistribution moodDistribution = _distribution,
  List<TrackAnalysis> topTracks = const [_track],
  int trackCount = 10,
}) => MoodResult(
  primaryMood: primaryMood,
  moodCategory: moodCategory,
  moodDescriptors: moodDescriptors,
  confidence: confidence,
  averages: averages,
  moodDistribution: moodDistribution,
  topTracks: topTracks,
  trackCount: trackCount,
);

void main() {
  group('MoodResult', () {
    test('instances with equal values are equal', () {
      expect(_result(), _result());
      expect(_result().hashCode, _result().hashCode);
    });

    test('props lists fields in declaration order', () {
      expect(_result().props, [
        'Happy',
        'positive',
        ['upbeat'],
        0.9,
        _averages,
        _distribution,
        [_track],
        10,
      ]);
    });

    test('every field participates in equality', () {
      final variants = [
        _result(primaryMood: 'x'),
        _result(moodCategory: 'x'),
        _result(moodDescriptors: ['x']),
        _result(confidence: 0),
        _result(
          averages: const AudioFeaturesSummary(
            valence: 1,
            energy: 1,
            danceability: 1,
            tempo: 1,
            acousticness: 1,
            instrumentalness: 1,
          ),
        ),
        _result(
          moodDistribution: const MoodDistribution(
            happy: 1,
            sad: 0,
            energetic: 0,
            calm: 0,
            danceable: 0,
          ),
        ),
        _result(topTracks: const []),
        _result(trackCount: 0),
      ];
      for (final v in variants) {
        expect(v, isNot(_result()));
      }
    });
  });
}
