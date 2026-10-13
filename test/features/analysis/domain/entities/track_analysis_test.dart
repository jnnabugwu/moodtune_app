import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/track_analysis.dart';

TrackAnalysis _track({
  String trackId = 'id',
  String trackName = 'name',
  List<String> artists = const ['a'],
  double valence = 0.1,
  double energy = 0.2,
  double danceability = 0.3,
  String moodLabel = 'happy',
}) => TrackAnalysis(
  trackId: trackId,
  trackName: trackName,
  artists: artists,
  valence: valence,
  energy: energy,
  danceability: danceability,
  moodLabel: moodLabel,
);

void main() {
  group('TrackAnalysis', () {
    test('instances with equal values are equal (deep list equality)', () {
      expect(_track(artists: ['a', 'b']), _track(artists: ['a', 'b']));
      expect(_track().hashCode, _track().hashCode);
    });

    test('props lists fields in declaration order', () {
      expect(_track().props, [
        'id',
        'name',
        ['a'],
        0.1,
        0.2,
        0.3,
        'happy',
      ]);
    });

    test('every field participates in equality', () {
      final variants = [
        _track(trackId: 'x'),
        _track(trackName: 'x'),
        _track(artists: ['x']),
        _track(valence: 9),
        _track(energy: 9),
        _track(danceability: 9),
        _track(moodLabel: 'x'),
      ];
      for (final v in variants) {
        expect(v, isNot(_track()));
      }
    });
  });
}
