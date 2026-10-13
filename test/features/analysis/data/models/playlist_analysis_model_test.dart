import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/data/models/playlist_analysis_model.dart';

import '../analysis_data_fixtures.dart';

void main() {
  group('PlaylistAnalysisModel', () {
    test('fromJson parses top-level fields and mood_results', () {
      final model = PlaylistAnalysisModel.fromJson(playlistAnalysisJson());

      expect(model.id, 'analysis-1');
      expect(model.playlistId, 'pl-1');
      expect(model.playlistName, 'Road Trip');
      expect(model.createdAt, DateTime.utc(2025, 1, 2, 3, 4, 5));
      expect(model.userId, 'user-1');
      expect(model.moodResult.primaryMood, 'Happy');
      expect(model.moodResult.trackCount, 25);
    });

    test('fromJson stringifies numeric id and user_id', () {
      final json = playlistAnalysisJson()
        ..['id'] = 42
        ..['user_id'] = 7;

      final model = PlaylistAnalysisModel.fromJson(json);

      expect(model.id, '42');
      expect(model.userId, '7');
    });

    test('fromJson tolerates missing fields', () {
      final before = DateTime.now();
      final model = PlaylistAnalysisModel.fromJson(<String, dynamic>{});
      final after = DateTime.now();

      expect(model.id, '');
      expect(model.playlistId, '');
      expect(model.playlistName, '');
      expect(model.userId, isNull);
      expect(model.moodResult.primaryMood, '');
      expect(model.moodResult.topTracks, isEmpty);
      // Missing created_at falls back to "now".
      expect(model.createdAt.isBefore(before), isFalse);
      expect(model.createdAt.isAfter(after), isFalse);
    });

    test('fromJson falls back to now for an unparseable created_at', () {
      final before = DateTime.now();
      final model = PlaylistAnalysisModel.fromJson(
        playlistAnalysisJson()..['created_at'] = 'not-a-date',
      );

      expect(model.createdAt.isBefore(before), isFalse);
    });

    test('toDomain maps all fields', () {
      final entity = PlaylistAnalysisModel.fromJson(
        playlistAnalysisJson(),
      ).toDomain();

      expect(entity.id, 'analysis-1');
      expect(entity.playlistId, 'pl-1');
      expect(entity.playlistName, 'Road Trip');
      expect(entity.createdAt, DateTime.utc(2025, 1, 2, 3, 4, 5));
      expect(entity.userId, 'user-1');
      expect(entity.moodResult.moodCategory, 'positive');
      expect(entity.moodResult.topTracks, hasLength(2));
    });
  });
}
