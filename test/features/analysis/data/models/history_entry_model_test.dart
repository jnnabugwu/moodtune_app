import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/data/models/history_entry_model.dart';
import 'package:moodtune_app/features/analysis/domain/entities/history_entry.dart';

import '../analysis_data_fixtures.dart';

void main() {
  group('PlaylistHistoryEntryModel', () {
    test('fromJson reads mood fields from nested mood_results', () {
      final model = PlaylistHistoryEntryModel.fromJson(playlistHistoryJson());

      expect(model.id, 'ph-1');
      expect(model.playlistName, 'Chill');
      expect(model.primaryMood, 'Calm');
      expect(model.confidence, 1.0);
      expect(model.confidence, isA<double>());
      expect(model.createdAt, DateTime.utc(2025, 3, 4, 5, 6, 7));
    });

    test('fromJson tolerates missing mood_results and created_at', () {
      final before = DateTime.now();
      final model = PlaylistHistoryEntryModel.fromJson(<String, dynamic>{});

      expect(model.id, '');
      expect(model.playlistName, '');
      expect(model.primaryMood, '');
      expect(model.confidence, 0);
      expect(model.createdAt.isBefore(before), isFalse);
    });

    test('toDomain produces a playlist entry without subtitle', () {
      expect(
        PlaylistHistoryEntryModel.fromJson(playlistHistoryJson()).toDomain(),
        HistoryEntry(
          id: 'ph-1',
          title: 'Chill',
          primaryMood: 'Calm',
          confidence: 1,
          createdAt: DateTime.utc(2025, 3, 4, 5, 6, 7),
          type: HistoryEntryType.playlist,
        ),
      );
    });
  });

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
      expect(model.confidence, 0);
      expect(model.createdAt.isBefore(before), isFalse);
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
