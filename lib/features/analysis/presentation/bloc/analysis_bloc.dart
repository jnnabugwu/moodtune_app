import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/analysis/domain/domain.dart';

part 'analysis_event.dart';
part 'analysis_state.dart';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  AnalysisBloc({
    required AnalysisRepository repository,
  }) : _repository = repository,
       super(const AnalysisState()) {
    on<AnalyzePlaylistRequested>(_onAnalyzeRequested);
    on<AnalysisHistoryRequested>(_onHistoryRequested);
    on<AnalysisByIdRequested>(_onAnalysisByIdRequested);
    on<AnalyzeSongRequested>(_onAnalyzeSongRequested);
    on<AnalysisClearErrorRequested>(_onClearError);
  }

  final AnalysisRepository _repository;

  Future<void> _onAnalyzeRequested(
    AnalyzePlaylistRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AnalysisStatus.analyzing,
        error: null,
      ),
    );

    final result = await _repository.analyzePlaylist(
      event.playlistId,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AnalysisStatus.error,
          error: failure.message,
        ),
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
    emit(
      state.copyWith(
        historyLoading: true,
        historyError: null,
      ),
    );

    final result = await _repository.getHistory(
      limit: event.limit,
      offset: event.offset,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          historyLoading: false,
          historyError: failure.message,
        ),
      ),
      (analyses) => emit(
        state.copyWith(
          historyLoading: false,
          history: analyses,
        ),
      ),
    );
  }

  Future<void> _onAnalysisByIdRequested(
    AnalysisByIdRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AnalysisStatus.loading,
        error: null,
      ),
    );

    final result = await _repository.getAnalysisById(event.analysisId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AnalysisStatus.error,
          error: failure.message,
        ),
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
    emit(
      state.copyWith(
        status: AnalysisStatus.analyzing,
        error: null,
      ),
    );

    final result = await _repository.analyzeSong(event.trackId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AnalysisStatus.error,
          error: failure.message,
        ),
      ),
      (analysis) => emit(
        state.copyWith(
          status: AnalysisStatus.success,
          currentSongAnalysis: analysis,
        ),
      ),
    );
  }

  void _onClearError(
    AnalysisClearErrorRequested event,
    Emitter<AnalysisState> emit,
  ) {
    emit(state.copyWith(error: null, historyError: null));
  }
}
