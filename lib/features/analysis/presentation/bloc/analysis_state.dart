part of 'analysis_bloc.dart';

enum AnalysisStatus { initial, loading, analyzing, success, error }

enum UploadStatus { initial, uploading, success, error }

enum CatalogAnalysisStatus { initial, analyzing, success, error }

/// What kind of failure an upload or catalog analysis hit, so the UI can pick
/// its error screen from the failure type rather than its message text.
enum AnalysisErrorKind {
  network,
  rateLimit,
  other;

  static AnalysisErrorKind fromFailure(Failure failure) => switch (failure) {
    NetworkFailure() => network,
    RateLimitFailure() => rateLimit,
    _ => other,
  };
}

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
    this.historyLoaded = false,
    this.historyError,
    this.uploadStatus = UploadStatus.initial,
    this.uploadError,
    this.uploadErrorKind,
    this.uploadSaved = false,
    this.catalogStatus = CatalogAnalysisStatus.initial,
    this.currentCatalogAnalysis,
    this.catalogError,
    this.catalogErrorKind,
    this.onDeviceAttempt,
    this.observationId,
  });

  final AnalysisStatus status;

  /// Full list (up to 50 most recent), loaded from the API.
  final List<HistoryEntry> history;

  /// Filtered view — derived in-memory from [history] when a mood filter
  /// is active. Equals [history] when [historyMoodFilter] is null.
  final List<HistoryEntry> filteredHistory;

  /// Currently active mood filter, e.g. "happy". Null = show all.
  final String? historyMoodFilter;

  final PlaylistAnalysis? currentAnalysis;
  final SongAnalysisResult? currentSongAnalysis;
  final AudioUploadAnalysis? currentUploadAnalysis;
  final String? error;
  final bool historyLoading;

  /// True once history has loaded successfully, even if it came back empty.
  final bool historyLoaded;
  final String? historyError;
  final UploadStatus uploadStatus;
  final String? uploadError;

  /// Type of the failure behind [uploadError].
  final AnalysisErrorKind? uploadErrorKind;

  /// True once the shown upload result is saved to the signed-in user's
  /// history. Reset by each new upload; drives the "Saved to history" notice.
  final bool uploadSaved;

  /// Catalog track analysis (Jamendo → /catalog/analyze → AudioUploadAnalysis).
  final CatalogAnalysisStatus catalogStatus;
  final AudioUploadAnalysis? currentCatalogAnalysis;
  final String? catalogError;

  /// Type of the failure behind [catalogError].
  final AnalysisErrorKind? catalogErrorKind;

  /// The on-device classification behind the latest upload or catalog
  /// result, kept to compare engines (ROADMAP OD-4). Null when it didn't run.
  final OnDeviceMoodAttempt? onDeviceAttempt;

  /// Id of the recorded observation for the shown result, used to send
  /// "Does this feel right?" feedback. Null when nothing was recorded.
  final String? observationId;

  /// Fields typed `Object?` default to [_keep]: omit one to leave it
  /// unchanged, pass `null` to clear it.
  AnalysisState copyWith({
    AnalysisStatus? status,
    List<HistoryEntry>? history,
    List<HistoryEntry>? filteredHistory,
    Object? historyMoodFilter = _keep,
    PlaylistAnalysis? currentAnalysis,
    SongAnalysisResult? currentSongAnalysis,
    Object? currentUploadAnalysis = _keep,
    Object? error = _keep,
    bool? historyLoading,
    bool? historyLoaded,
    Object? historyError = _keep,
    UploadStatus? uploadStatus,
    Object? uploadError = _keep,
    Object? uploadErrorKind = _keep,
    bool? uploadSaved,
    CatalogAnalysisStatus? catalogStatus,
    Object? currentCatalogAnalysis = _keep,
    Object? catalogError = _keep,
    Object? catalogErrorKind = _keep,
    Object? onDeviceAttempt = _keep,
    Object? observationId = _keep,
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
      currentUploadAnalysis: currentUploadAnalysis == _keep
          ? this.currentUploadAnalysis
          : currentUploadAnalysis as AudioUploadAnalysis?,
      error: error == _keep ? this.error : error as String?,
      historyLoading: historyLoading ?? this.historyLoading,
      historyLoaded: historyLoaded ?? this.historyLoaded,
      historyError: historyError == _keep
          ? this.historyError
          : historyError as String?,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadError: uploadError == _keep
          ? this.uploadError
          : uploadError as String?,
      uploadErrorKind: uploadErrorKind == _keep
          ? this.uploadErrorKind
          : uploadErrorKind as AnalysisErrorKind?,
      uploadSaved: uploadSaved ?? this.uploadSaved,
      catalogStatus: catalogStatus ?? this.catalogStatus,
      currentCatalogAnalysis: currentCatalogAnalysis == _keep
          ? this.currentCatalogAnalysis
          : currentCatalogAnalysis as AudioUploadAnalysis?,
      catalogError: catalogError == _keep
          ? this.catalogError
          : catalogError as String?,
      catalogErrorKind: catalogErrorKind == _keep
          ? this.catalogErrorKind
          : catalogErrorKind as AnalysisErrorKind?,
      onDeviceAttempt: onDeviceAttempt == _keep
          ? this.onDeviceAttempt
          : onDeviceAttempt as OnDeviceMoodAttempt?,
      observationId: observationId == _keep
          ? this.observationId
          : observationId as String?,
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
    historyLoaded,
    historyError,
    uploadStatus,
    uploadError,
    uploadErrorKind,
    uploadSaved,
    catalogStatus,
    currentCatalogAnalysis,
    catalogError,
    catalogErrorKind,
    onDeviceAttempt,
    observationId,
  ];
}

/// Sentinel object used in copyWith to distinguish null from "no change".
const Object _keep = Object();
