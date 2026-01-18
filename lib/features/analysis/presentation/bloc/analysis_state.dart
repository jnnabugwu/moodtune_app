part of 'analysis_bloc.dart';

enum AnalysisStatus { initial, loading, analyzing, success, error }

class AnalysisState extends Equatable {
  const AnalysisState({
    this.status = AnalysisStatus.initial,
    this.history = const [],
    this.currentAnalysis,
    this.error,
    this.historyLoading = false,
    this.historyError,
  });

  final AnalysisStatus status;
  final List<PlaylistAnalysis> history;
  final PlaylistAnalysis? currentAnalysis;
  final String? error;
  final bool historyLoading;
  final String? historyError;

  AnalysisState copyWith({
    AnalysisStatus? status,
    List<PlaylistAnalysis>? history,
    PlaylistAnalysis? currentAnalysis,
    String? error,
    bool? historyLoading,
    String? historyError,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      history: history ?? this.history,
      currentAnalysis: currentAnalysis ?? this.currentAnalysis,
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
    error,
    historyLoading,
    historyError,
  ];
}
