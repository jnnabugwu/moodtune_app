import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/catalog/data/models/jamendo_track_model.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';

import '../../catalog_fixtures.dart';

void main() {
  group('JamendoTrackModel.fromJson', () {
    test('parses all fields', () {
      final model = JamendoTrackModel.fromJson(buildJamendoJson(id: 42));

      expect(model.id, '42');
      expect(model.name, 'Sunny Day');
      expect(model.artistName, 'The Testers');
      expect(model.albumImageUrl, 'https://img.example/42.jpg');
      expect(model.durationSeconds, 125);
      expect(model.audioUrl, 'https://audio.example/42.mp3');
      expect(model.jamendoPageUrl, 'https://jamendo.example/track/42');
      expect(model.audiodownloadAllowed, isTrue);
    });

    test('takes vartags first then genres, capped at two', () {
      final model = JamendoTrackModel.fromJson(
        buildJamendoJson(vartags: ['chill'], genres: ['jazz', 'lounge']),
      );
      expect(model.tags, ['chill', 'jazz']);

      final vartagsOnly = JamendoTrackModel.fromJson(
        buildJamendoJson(vartags: ['a', 'b', 'c'], genres: ['d']),
      );
      expect(vartagsOnly.tags, ['a', 'b']);
    });

    for (final (raw, expected) in [
      (true, true),
      (1, true),
      ('1', true),
      (false, false),
      (0, false),
      ('0', false),
      (null, false),
    ]) {
      test('audiodownload_allowed=$raw -> $expected', () {
        final model = JamendoTrackModel.fromJson(
          buildJamendoJson(audiodownloadAllowed: raw),
        );
        expect(model.audiodownloadAllowed, expected);
      });
    }

    test('falls back to defaults when fields are missing', () {
      final model = JamendoTrackModel.fromJson(const <String, dynamic>{});

      expect(model.id, '');
      expect(model.name, '');
      expect(model.artistName, '');
      expect(model.albumImageUrl, '');
      expect(model.durationSeconds, 0);
      expect(model.tags, isEmpty);
      expect(model.audioUrl, '');
      expect(model.jamendoPageUrl, '');
      expect(model.audiodownloadAllowed, isFalse);
    });

    test('handles musicinfo without tags and non-int duration', () {
      final model = JamendoTrackModel.fromJson(const {
        'id': 'abc',
        'duration': 61.9,
        'musicinfo': <String, dynamic>{},
      });
      expect(model.id, 'abc');
      expect(model.durationSeconds, 61);
      expect(model.tags, isEmpty);
    });
  });

  test('toDomain maps to JamendoTrack with Duration', () {
    final domain = JamendoTrackModel.fromJson(buildJamendoJson()).toDomain();

    expect(
      domain,
      const JamendoTrack(
        id: '1',
        name: 'Sunny Day',
        artistName: 'The Testers',
        albumImageUrl: 'https://img.example/1.jpg',
        duration: Duration(seconds: 125),
        tags: ['happy', 'pop'],
        audioUrl: 'https://audio.example/1.mp3',
        jamendoPageUrl: 'https://jamendo.example/track/1',
        audiodownloadAllowed: true,
      ),
    );
  });
}
