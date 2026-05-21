part of 'analysis_bloc.dart';

enum AnalysisStatus { initial, loading, analyzing, success, error }

enum UploadStatus { initial, uploading, success, error }

enum CatalogAnalysisStatus { initial, analyzing, success, error }

class AnalysisState extends Equatable {
  const AnalysisState({
    this.status = AnalysisStatus.initial,
    this.history = const [],
    this.filteredHistory = const [],
    this.historyMoodFilter,
    this.currentAnalysis,
    this.currentSongAnalysis,
    this.currentUploadAnalysis,
    this.error,
    this.historyLoading = false,
    this.historyError,
    this.uploadStatus = UploadStatus.initial,
    this.uploadError,
    this.catalogStatus = CatalogAnalysisStatus.initial,
    this.currentCatalogAnalysis,
    this.catalogError,
  });

  final AnalysisStatus status;

  /// Full list (up to 50 most recent), loaded from the API.
  final List<PlaylistAnalysis> history;

  /// Filtered view — derived in-memory from [history] when a mood filter
  /// is active. Equals [history] when [historyMoodFilter] is null.
  final List<PlaylistAnalysis> filteredHistory;

  /// Currently active mood filter, e.g. "happy". Null = show all.
  final String? historyMoodFilter;

  final PlaylistAnalysis? currentAnalysis;
  final SongAnalysisResult? currentSongAnalysis;
  final AudioUploadAnalysis? currentUploadAnalysis;
  final String? error;
  final bool historyLoading;
  final String? historyError;
  final UploadStatus uploadStatus;
  final String? uploadError;

  /// Catalog track analysis (Jamendo → /catalog/analyze → AudioUploadAnalysis).
  final CatalogAnalysisStatus catalogStatus;
  final AudioUploadAnalysis? currentCatalogAnalysis;
  final String? catalogError;

  AnalysisState copyWith({
    AnalysisStatus? status,
    List<PlaylistAnalysis>? history,
    List<PlaylistAnalysis>? filteredHistory,
    // Use a sentinel to distinguish "set to null" from "leave unchanged"
    Object? historyMoodFilter = _keep,
    PlaylistAnalysis? currentAnalysis,
    SongAnalysisResult? currentSongAnalysis,
    AudioUploadAnalysis? currentUploadAnalysis,
    String? error,
    bool? historyLoading,
    String? historyError,
    UploadStatus? uploadStatus,
    String? uploadError,
    CatalogAnalysisStatus? catalogStatus,
    AudioUploadAnalysis? currentCatalogAnalysis,
    String? catalogError,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      history: history ?? this.history,
      filteredHistory: filteredHistory ?? this.filteredHistory,
      historyMoodFilter: historyMoodFilter == _keep
          ? this.historyMoodFilter
          : historyMoodFilter as String?,
      currentAnalysis: currentAnalysis ?? this.currentAnalysis,
      currentSongAnalysis: currentSongAnalysis ?? this.currentSongAnalysis,
      currentUploadAnalysis:
          currentUploadAnalysis ?? this.currentUploadAnalysis,
      error: error,
      historyLoading: historyLoading ?? this.historyLoading,
      historyError: historyError,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadError: uploadError,
      catalogStatus: catalogStatus ?? this.catalogStatus,
      currentCatalogAnalysis:
          currentCatalogAnalysis ?? this.currentCatalogAnalysis,
      catalogError: catalogError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    history,
    filteredHistory,
    historyMoodFilter,
    currentAnalysis,
    currentSongAnalysis,
    currentUploadAnalysis,
    error,
    historyLoading,
    historyError,
    uploadStatus,
    uploadError,
    catalogStatus,
    currentCatalogAnalysis,
    catalogError,
  ];
}

/// Sentinel object used in copyWith to distinguish null from "no change".
const Object _keep = Object();
