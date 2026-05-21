part of 'analysis_bloc.dart';

abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzePlaylistRequested extends AnalysisEvent {
  const AnalyzePlaylistRequested({
    required this.playlistId,
    this.limit = 50,
  });

  final String playlistId;
  final int limit;

  @override
  List<Object?> get props => [playlistId, limit];
}

class AnalysisHistoryRequested extends AnalysisEvent {
  const AnalysisHistoryRequested({
    // Default 50 so History screen has enough items to filter client-side
    this.limit = 50,
    this.offset = 0,
  });

  final int limit;
  final int offset;

  @override
  List<Object?> get props => [limit, offset];
}

/// Filters the already-loaded history list in memory.
/// Pass null to clear the filter and show all items.
class AnalysisHistoryFilterChanged extends AnalysisEvent {
  const AnalysisHistoryFilterChanged(this.mood);

  final String? mood;

  @override
  List<Object?> get props => [mood];
}

class AnalysisByIdRequested extends AnalysisEvent {
  const AnalysisByIdRequested(this.analysisId);

  final String analysisId;

  @override
  List<Object?> get props => [analysisId];
}

class AnalysisClearErrorRequested extends AnalysisEvent {
  const AnalysisClearErrorRequested();
}

class AnalyzeSongRequested extends AnalysisEvent {
  const AnalyzeSongRequested(this.trackId);

  final String trackId;

  @override
  List<Object?> get props => [trackId];
}

class CatalogTrackAnalyzeRequested extends AnalysisEvent {
  const CatalogTrackAnalyzeRequested({
    required this.audioUrl,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.jamendoPageUrl,
  });

  final String audioUrl;
  final String trackId;
  final String trackName;
  final String artistName;
  final String jamendoPageUrl;

  @override
  List<Object?> get props =>
      [audioUrl, trackId, trackName, artistName, jamendoPageUrl];
}

class AudioUploadRequested extends AnalysisEvent {
  const AudioUploadRequested({
    required this.bytes,
    required this.filename,
    this.title,
    this.artist,
    this.album,
  });

  final List<int> bytes;
  final String filename;
  final String? title;
  final String? artist;
  final String? album;

  @override
  List<Object?> get props => [bytes, filename, title, artist, album];
}
