part of 'analysis_bloc.dart';

enum AnalysisStatus { initial, loading, analyzing, success, error }
enum UploadStatus { initial, uploading, success, error }

class AnalysisState extends Equatable {
  const AnalysisState({
    this.status = AnalysisStatus.initial,
    this.history = const [],
    this.currentAnalysis,
    this.currentSongAnalysis,
    this.currentUploadAnalysis,
    this.error,
    this.historyLoading = false,
    this.historyError,
    this.uploadStatus = UploadStatus.initial,
    this.uploadError,
  });

  final AnalysisStatus status;
  final List<PlaylistAnalysis> history;
  final PlaylistAnalysis? currentAnalysis;
  final SongAnalysisResult? currentSongAnalysis;
  final AudioUploadAnalysis? currentUploadAnalysis;
  final String? error;
  final bool historyLoading;
  final String? historyError;
  final UploadStatus uploadStatus;
  final String? uploadError;

  AnalysisState copyWith({
    AnalysisStatus? status,
    List<PlaylistAnalysis>? history,
    PlaylistAnalysis? currentAnalysis,
    SongAnalysisResult? currentSongAnalysis,
    AudioUploadAnalysis? currentUploadAnalysis,
    String? error,
    bool? historyLoading,
    String? historyError,
    UploadStatus? uploadStatus,
    String? uploadError,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      history: history ?? this.history,
      currentAnalysis: currentAnalysis ?? this.currentAnalysis,
      currentSongAnalysis: currentSongAnalysis ?? this.currentSongAnalysis,
      currentUploadAnalysis:
          currentUploadAnalysis ?? this.currentUploadAnalysis,
      error: error,
      historyLoading: historyLoading ?? this.historyLoading,
      historyError: historyError,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadError: uploadError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    history,
    currentAnalysis,
    currentSongAnalysis,
    currentUploadAnalysis,
    error,
    historyLoading,
    historyError,
    uploadStatus,
    uploadError,
  ];
}
