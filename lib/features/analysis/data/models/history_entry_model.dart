import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/analysis/domain/entities/history_entry.dart';

/// Converts a song_analyses row (from GET /song/history) to [HistoryEntry].
///
/// Rows saved by POST /song/history also carry both engines' moods in
/// `mood_results` and the user's feedback at the top level.
class SongHistoryEntryModel {
  const SongHistoryEntryModel({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.primaryMood,
    required this.confidence,
    required this.createdAt,
    this.comparison,
  });

  factory SongHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    final moodResults =
        (json['mood_results'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return SongHistoryEntryModel(
      id: json['id'] as String? ?? '',
      trackName: json['track_name'] as String? ?? '',
      artistName: json['artist_name'] as String? ?? '',
      primaryMood: moodResults['primary_mood'] as String? ?? '',
      confidence: (moodResults['confidence'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      comparison: _comparison(json, moodResults),
    );
  }

  static EngineComparison? _comparison(
    Map<String, dynamic> json,
    Map<String, dynamic> moodResults,
  ) {
    final backendMood = moodResults['backend_mood'] as String?;
    if (backendMood == null) return null;
    return EngineComparison(
      backendMood: backendMood,
      onDeviceMood: moodResults['on_device_mood'] as String?,
      displayedSource: moodResults['displayed_source'] == 'on_device'
          ? MoodSource.onDevice
          : MoodSource.backend,
      agrees: json['agrees'] as bool?,
      userMood: json['user_mood'] as String?,
    );
  }

  final String id;
  final String trackName;
  final String artistName;
  final String primaryMood;
  final double? confidence;
  final DateTime createdAt;
  final EngineComparison? comparison;

  HistoryEntry toDomain() => HistoryEntry(
    id: id,
    title: trackName,
    // Uploads have no artist; keep the date as the subtitle instead.
    subtitle: artistName.isEmpty ? null : artistName,
    primaryMood: primaryMood,
    confidence: confidence,
    createdAt: createdAt,
    type: HistoryEntryType.song,
    comparison: comparison,
  );
}
