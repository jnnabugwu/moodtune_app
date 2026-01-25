import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/utils/typedef.dart';

abstract class AnalysisRepository {
  ResultFuture<PlaylistAnalysis> analyzePlaylist(
    String playlistId, {
    int limit = 50,
  });

  ResultFuture<List<PlaylistAnalysis>> getHistory({
    int limit = 3,
    int offset = 0,
  });

  ResultFuture<PlaylistAnalysis> getAnalysisById(String analysisId);

  ResultFuture<SongAnalysisResult> analyzeSong(String trackId);
}
