import 'package:equatable/equatable.dart';
import 'package:moodtune_app/features/analysis/domain/entities/mood_result.dart';

class PlaylistAnalysis extends Equatable {
  const PlaylistAnalysis({
    required this.id,
    required this.playlistId,
    required this.playlistName,
    required this.moodResult,
    required this.createdAt,
    this.userId,
  });

  final String id;
  final String playlistId;
  final String playlistName;
  final MoodResult moodResult;
  final DateTime createdAt;
  final String? userId;

  @override
  List<Object?> get props => [
    id,
    playlistId,
    playlistName,
    moodResult,
    createdAt,
    userId,
  ];
}
