part of 'analysis_bloc.dart';

enum AnalysisStatus { initial, loading, analyzing, success, error }

class AnalysisState extends Equatable {
  const AnalysisState({
    this.status = AnalysisStatus.initial,
    this.history = const [],
    this.currentAnalysis,
    this.currentSongAnalysis,
    this.error,
    this.historyLoading = false,
    this.historyError,
  });

  final AnalysisStatus status;
  final List<PlaylistAnalysis> history;
  final PlaylistAnalysis? currentAnalysis;
  final SongAnalysisResult? currentSongAnalysis;
  final String? error;
  final bool historyLoading;
  final String? historyError;

  AnalysisState copyWith({
    AnalysisStatus? status,
    List<PlaylistAnalysis>? history,
    PlaylistAnalysis? currentAnalysis,
    SongAnalysisResult? currentSongAnalysis,
    String? error,
    bool? historyLoading,
    String? historyError,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      history: history ?? this.history,
      currentAnalysis: currentAnalysis ?? this.currentAnalysis,
      currentSongAnalysis: currentSongAnalysis ?? this.currentSongAnalysis,
      error: error,
      historyLoading: historyLoading ?? this.historyLoading,
      historyError: historyError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    history,
    currentAnalysis,
    currentSongAnalysis,
    error,
    historyLoading,
    historyError,
  ];
}
