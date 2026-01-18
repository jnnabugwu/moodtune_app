import 'package:moodtune_app/features/analysis/data/models/mood_result_model.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

class PlaylistAnalysisModel {
  const PlaylistAnalysisModel({
    required this.id,
    required this.playlistId,
    required this.playlistName,
    required this.moodResult,
    required this.createdAt,
    this.userId,
  });

  factory PlaylistAnalysisModel.fromJson(Map<String, dynamic> json) {
    final moodResultJson =
        (json['mood_results'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return PlaylistAnalysisModel(
      id: json['id']?.toString() ?? '',
      playlistId: json['playlist_id'] as String? ?? '',
      playlistName: json['playlist_name'] as String? ?? '',
      moodResult: MoodResultModel.fromJson(moodResultJson),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      userId: json['user_id']?.toString(),
    );
  }

  final String id;
  final String playlistId;
  final String playlistName;
  final MoodResultModel moodResult;
  final DateTime createdAt;
  final String? userId;
  
  PlaylistAnalysis toDomain() {
    return PlaylistAnalysis(
      id: id,
      playlistId: playlistId,
      playlistName: playlistName,
      moodResult: moodResult.toDomain(),
      createdAt: createdAt,
      userId: userId,
    );
  }
}
