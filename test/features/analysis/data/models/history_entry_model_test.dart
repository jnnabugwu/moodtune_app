import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/data/models/history_entry_model.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/analysis/domain/entities/history_entry.dart';

import '../analysis_data_fixtures.dart';

void main() {
  group('SongHistoryEntryModel', () {
    test('fromJson reads track, artist and nested mood fields', () {
      final model = SongHistoryEntryModel.fromJson(songHistoryJson());

      expect(model.id, 'sh-1');
      expect(model.trackName, 'Song');
      expect(model.artistName, 'Singer');
      expect(model.primaryMood, 'Sad');
      expect(model.confidence, 0.65);
      expect(model.createdAt, DateTime.utc(2025, 3, 4, 5, 6, 7));
    });

    test('fromJson tolerates missing fields and bad dates', () {
      final before = DateTime.now();
      final model = SongHistoryEntryModel.fromJson(<String, dynamic>{
        'created_at': 'garbage',
        'mood_results': null,
      });

      expect(model.id, '');
      expect(model.trackName, '');
      expect(model.artistName, '');
      expect(model.primaryMood, '');
      // No confidence (on-device results) stays null instead of reading 0%.
      expect(model.confidence, isNull);
      expect(model.comparison, isNull);
      expect(model.createdAt.isBefore(before), isFalse);
    });

    test("fromJson reads both engines and the user's answer", () {
      final entry = SongHistoryEntryModel.fromJson(<String, dynamic>{
        'id': 'sh-2',
        'track_name': 'Inside Outside',
        'artist_name': '',
        'mood_results': {
          'primary_mood': 'calm',
          'confidence': null,
          'source': 'upload',
          'displayed_source': 'on_device',
          'backend_mood': 'happy',
          'on_device_mood': 'calm',
          'observation_id': 'o-1',
        },
        'agrees': false,
        'user_mood': 'reflective',
        'created_at': '2026-10-16T20:00:00Z',
      }).toDomain();

      expect(entry.subtitle, isNull); // uploads have no artist
      expect(entry.confidence, isNull);
      expect(
        entry.comparison,
        const EngineComparison(
          backendMood: 'happy',
          onDeviceMood: 'calm',
          displayedSource: MoodSource.onDevice,
          agrees: false,
          userMood: 'reflective',
        ),
      );
    });

    test('toDomain produces a song entry with artist as subtitle', () {
      expect(
        SongHistoryEntryModel.fromJson(songHistoryJson()).toDomain(),
        HistoryEntry(
          id: 'sh-1',
          title: 'Song',
          subtitle: 'Singer',
          primaryMood: 'Sad',
          confidence: 0.65,
          createdAt: DateTime.utc(2025, 3, 4, 5, 6, 7),
          type: HistoryEntryType.song,
        ),
      );
    });
  });
}
