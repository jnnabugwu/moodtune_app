import 'package:moodtune_app/features/analysis/domain/entities/history_entry.dart';

/// Converts a playlist_analyses row (from GET /analysis/history) to [HistoryEntry].
class PlaylistHistoryEntryModel {
  const PlaylistHistoryEntryModel({
    required this.id,
    required this.playlistName,
    required this.primaryMood,
    required this.confidence,
    required this.createdAt,
  });

  factory PlaylistHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    final moodResults =
        (json['mood_results'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return PlaylistHistoryEntryModel(
      id: json['id'] as String? ?? '',
      playlistName: json['playlist_name'] as String? ?? '',
      primaryMood: moodResults['primary_mood'] as String? ?? '',
      confidence: (moodResults['confidence'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String playlistName;
  final String primaryMood;
  final double confidence;
  final DateTime createdAt;

  HistoryEntry toDomain() => HistoryEntry(
        id: id,
        title: playlistName,
        primaryMood: primaryMood,
        confidence: confidence,
        createdAt: createdAt,
        type: HistoryEntryType.playlist,
      );
}

/// Converts a song_analyses row (from GET /song/history) to [HistoryEntry].
class SongHistoryEntryModel {
  const SongHistoryEntryModel({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.primaryMood,
    required this.confidence,
    required this.createdAt,
  });

  factory SongHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    final moodResults =
        (json['mood_results'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return SongHistoryEntryModel(
      id: json['id'] as String? ?? '',
      trackName: json['track_name'] as String? ?? '',
      artistName: json['artist_name'] as String? ?? '',
      primaryMood: moodResults['primary_mood'] as String? ?? '',
      confidence: (moodResults['confidence'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String trackName;
  final String artistName;
  final String primaryMood;
  final double confidence;
  final DateTime createdAt;

  HistoryEntry toDomain() => HistoryEntry(
        id: id,
        title: trackName,
        subtitle: artistName,
        primaryMood: primaryMood,
        confidence: confidence,
        createdAt: createdAt,
        type: HistoryEntryType.song,
      );
}
