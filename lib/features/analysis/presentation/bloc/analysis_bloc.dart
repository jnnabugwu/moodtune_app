import 'dart:async';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/analysis/domain/domain.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/mood_switchover.dart';

part 'analysis_event.dart';
part 'analysis_state.dart';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  AnalysisBloc({
    required AnalysisRepository repository,
    MoodSwitchover? switchover,
    this.onDeviceGrace = const Duration(seconds: 3),
  }) : _repository = repository,
       _switchover = switchover,
       super(const AnalysisState()) {
    on<AnalyzePlaylistRequested>(_onAnalyzeRequested);
    on<AnalysisHistoryRequested>(_onHistoryRequested);
    on<AnalysisHistoryFilterChanged>(_onHistoryFilterChanged);
    on<AnalysisByIdRequested>(_onAnalysisByIdRequested);
    on<AnalyzeSongRequested>(_onAnalyzeSongRequested);
    on<AnalysisClearErrorRequested>(_onClearError);
    on<AudioUploadRequested>(_onAudioUploadRequested);
    on<CatalogTrackAnalyzeRequested>(_onCatalogTrackAnalyzeRequested);
  }

  final AnalysisRepository _repository;

  /// Shows the on-device mood instead of the backend's for uploads and
  /// catalog tracks. Null (tests, platforms without it) keeps the backend's.
  final MoodSwitchover? _switchover;

  /// How long to keep waiting for on-device classification once the backend
  /// has answered, so a slow phone or download never holds the result back.
  final Duration onDeviceGrace;

  Future<void> _onAnalyzeRequested(
    AnalyzePlaylistRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(state.copyWith(status: AnalysisStatus.analyzing, error: null));

    final result = await _repository.analyzePlaylist(
      event.playlistId,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: AnalysisStatus.error, error: failure.message),
      ),
      (analysis) => emit(
        state.copyWith(
          status: AnalysisStatus.success,
          currentAnalysis: analysis,
        ),
      ),
    );
  }

  Future<void> _onHistoryRequested(
    AnalysisHistoryRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(state.copyWith(historyLoading: true, historyError: null));

    final result = await _repository.getHistory(
      limit: event.limit,
      offset: event.offset,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(historyLoading: false, historyError: failure.message),
      ),
      (analyses) => emit(
        state.copyWith(
          historyLoading: false,
          history: analyses,
          // Reset filtered view to full list on fresh load
          filteredHistory: analyses,
          historyMoodFilter: null,
        ),
      ),
    );
  }

  void _onHistoryFilterChanged(
    AnalysisHistoryFilterChanged event,
    Emitter<AnalysisState> emit,
  ) {
    final mood = event.mood;
    final filtered = mood == null || mood.isEmpty
        ? state.history
        : state.history
              .where((a) => a.primaryMood.toLowerCase() == mood.toLowerCase())
              .toList();

    emit(state.copyWith(filteredHistory: filtered, historyMoodFilter: mood));
  }

  Future<void> _onAnalysisByIdRequested(
    AnalysisByIdRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(state.copyWith(status: AnalysisStatus.loading, error: null));

    final result = await _repository.getAnalysisById(event.analysisId);

    result.fold(
      (failure) => emit(
        state.copyWith(status: AnalysisStatus.error, error: failure.message),
      ),
      (analysis) => emit(
        state.copyWith(
          status: AnalysisStatus.success,
          currentAnalysis: analysis,
        ),
      ),
    );
  }

  Future<void> _onAnalyzeSongRequested(
    AnalyzeSongRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(state.copyWith(status: AnalysisStatus.analyzing, error: null));

    final result = await _repository.analyzeSong(event.trackId);

    result.fold(
      (failure) => emit(
        state.copyWith(status: AnalysisStatus.error, error: failure.message),
      ),
      (analysis) => emit(
        state.copyWith(
          status: AnalysisStatus.success,
          currentSongAnalysis: analysis,
        ),
      ),
    );
  }

  Future<void> _onAudioUploadRequested(
    AudioUploadRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(
      state.copyWith(
        uploadStatus: UploadStatus.uploading,
        uploadError: null,
        currentUploadAnalysis: null,
      ),
    );

    final path = event.path;
    final switchover = _switchover;
    // Started before the backend call so the two run side by side.
    final onDevice = path == null || switchover == null
        ? null
        : switchover.classifyFile(path);

    final result = await _repository.analyzeUploadedAudio(
      bytes: Uint8List.fromList(event.bytes),
      filename: event.filename,
      title: event.title,
      artist: event.artist,
      album: event.album,
    );
    final attempt = await _settle(onDevice);

    result.fold(
      (failure) => emit(
        state.copyWith(
          uploadStatus: UploadStatus.error,
          uploadError: failure.message,
          currentUploadAnalysis: null,
        ),
      ),
      (analysis) => emit(
        state.copyWith(
          uploadStatus: UploadStatus.success,
          currentUploadAnalysis: MoodSwitchover.apply(analysis, attempt),
          uploadError: null,
          onDeviceAttempt: attempt,
        ),
      ),
    );
  }

  void _onClearError(
    AnalysisClearErrorRequested event,
    Emitter<AnalysisState> emit,
  ) {
    emit(state.copyWith(error: null, historyError: null, uploadError: null));
  }

  Future<void> _onCatalogTrackAnalyzeRequested(
    CatalogTrackAnalyzeRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(
      state.copyWith(
        catalogStatus: CatalogAnalysisStatus.analyzing,
        catalogError: null,
        currentCatalogAnalysis: null,
      ),
    );

    final onDevice = _switchover?.classifyUrl(event.audioUrl);

    final result = await _repository.analyzeCatalogTrack(
      audioUrl: event.audioUrl,
      trackId: event.trackId,
      trackName: event.trackName,
      artistName: event.artistName,
      jamendoPageUrl: event.jamendoPageUrl,
    );
    final attempt = await _settle(onDevice);

    result.fold(
      (failure) => emit(
        state.copyWith(
          catalogStatus: CatalogAnalysisStatus.error,
          catalogError: failure.message,
        ),
      ),
      (analysis) => emit(
        state.copyWith(
          catalogStatus: CatalogAnalysisStatus.success,
          currentCatalogAnalysis: MoodSwitchover.apply(analysis, attempt),
          onDeviceAttempt: attempt,
        ),
      ),
    );
  }

  /// Waits up to [onDeviceGrace] for on-device classification that is
  /// still running when the backend answers.
  Future<OnDeviceMoodAttempt?> _settle(
    Future<OnDeviceMoodAttempt>? pending,
  ) async {
    if (pending == null) return null;
    try {
      return await pending.timeout(onDeviceGrace);
    } on TimeoutException {
      talker.warning(
        'On-device mood not ready ${onDeviceGrace.inMilliseconds}ms after '
        'the backend; showing backend mood',
      );
      return OnDeviceMoodAttempt(elapsed: onDeviceGrace, failure: 'late');
    }
  }
}
