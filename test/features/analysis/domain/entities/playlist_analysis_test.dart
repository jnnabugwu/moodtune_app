import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

MoodResult _mood(String primary) => MoodResult(
  primaryMood: primary,
  moodCategory: 'c',
  moodDescriptors: const [],
  confidence: 0.5,
  averages: const AudioFeaturesSummary(
    valence: 0,
    energy: 0,
    danceability: 0,
    tempo: 0,
    acousticness: 0,
    instrumentalness: 0,
  ),
  moodDistribution: const MoodDistribution(
    happy: 0,
    sad: 0,
    energetic: 0,
    calm: 0,
    danceable: 0,
  ),
  topTracks: const [],
  trackCount: 0,
);

final _date = DateTime.utc(2025);

PlaylistAnalysis _analysis({
  String id = 'id',
  String playlistId = 'pl',
  String playlistName = 'name',
  MoodResult? moodResult,
  DateTime? createdAt,
  String? userId = 'u',
}) => PlaylistAnalysis(
  id: id,
  playlistId: playlistId,
  playlistName: playlistName,
  moodResult: moodResult ?? _mood('Happy'),
  createdAt: createdAt ?? _date,
  userId: userId,
);

void main() {
  group('PlaylistAnalysis', () {
    test('instances with equal values are equal', () {
      expect(_analysis(), _analysis());
      expect(_analysis().hashCode, _analysis().hashCode);
    });

    test('userId is optional and defaults to null', () {
      final analysis = PlaylistAnalysis(
        id: 'id',
        playlistId: 'pl',
        playlistName: 'name',
        moodResult: _mood('Happy'),
        createdAt: _date,
      );

      expect(analysis.userId, isNull);
      expect(analysis.props.last, isNull);
    });

    test('props lists fields in declaration order', () {
      expect(_analysis().props, [
        'id',
        'pl',
        'name',
        _mood('Happy'),
        _date,
        'u',
      ]);
    });

    test('every field participates in equality', () {
      final variants = [
        _analysis(id: 'x'),
        _analysis(playlistId: 'x'),
        _analysis(playlistName: 'x'),
        _analysis(moodResult: _mood('Sad')),
        _analysis(createdAt: DateTime.utc(2000)),
        _analysis(userId: null),
      ];
      for (final v in variants) {
        expect(v, isNot(_analysis()));
      }
    });
  });
}
