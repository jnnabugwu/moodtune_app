import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/analysis/data/datasources/analysis_datasource.dart';
import 'package:moodtune_app/features/analysis/data/models/models.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

class AnalysisRepositoryImpl implements AnalysisRepository {
  AnalysisRepositoryImpl({
    AnalysisRemoteDataSource? remoteDataSource,
  }) : _remote = remoteDataSource ?? AnalysisRemoteDataSource();

  final AnalysisRemoteDataSource _remote;

  @override
  ResultFuture<PlaylistAnalysis> analyzePlaylist(
    String playlistId, {
    int limit = 50,
  }) async {
    try {
      final json = await _remote.analyzePlaylist(playlistId, limit: limit);
      final model = PlaylistAnalysisModel.fromJson(json);
      return Right(model.toDomain());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  ResultFuture<List<PlaylistAnalysis>> getHistory({
    int limit = 3,
    int offset = 0,
  }) async {
    try {
      final items = await _remote.getHistory(limit: limit, offset: offset);
      final analyses = items
          .map(PlaylistAnalysisModel.fromJson)
          .map((m) => m.toDomain())
          .toList();
      return Right(analyses);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<PlaylistAnalysis> getAnalysisById(String analysisId) async {
    try {
      final json = await _remote.getAnalysisById(analysisId);
      final model = PlaylistAnalysisModel.fromJson(json);
      return Right(model.toDomain());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<SongAnalysisResult> analyzeSong(String trackId) async {
    try {
      final json = await _remote.analyzeSong(trackId);
      final model = SongAnalysisResultModel.fromJson(json);
      return Right(model.toDomain());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _mapDioError(DioException e) {
    String? message;
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      final msg = data['message'];
      message = (detail ?? msg)?.toString();
    }
    message ??= e.message;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkFailure(message ?? 'Network error');
    }
    return ServerFailure(message ?? 'Server error');
  }
}
