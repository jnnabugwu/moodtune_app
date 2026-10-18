import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/analysis/data/datasources/analysis_datasource.dart';
import 'package:moodtune_app/features/analysis/data/datasources/audio_upload_datasource.dart';
import 'package:moodtune_app/features/analysis/data/models/models.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// User-facing message for a response the app could not parse. Generic on
/// purpose: the underlying error text is never shown.
const malformedResponseMessage = 'Unexpected response from the server';

class AnalysisRepositoryImpl implements AnalysisRepository {
  AnalysisRepositoryImpl({
    AnalysisRemoteDataSource? remoteDataSource,
    AudioUploadRemoteDataSource? uploadRemoteDataSource,
  }) : _remote = remoteDataSource ?? AnalysisRemoteDataSource(),
       _uploadRemote = uploadRemoteDataSource ?? AudioUploadRemoteDataSource();

  final AnalysisRemoteDataSource _remote;
  final AudioUploadRemoteDataSource _uploadRemote;

  @override
  ResultFuture<PlaylistAnalysis> analyzePlaylist(
    String playlistId, {
    int limit = 50,
  }) {
    return _guard(() async {
      final json = await _remote.analyzePlaylist(playlistId, limit: limit);
      final model = PlaylistAnalysisModel.fromJson(json);
      return model.toDomain();
    });
  }

  @override
  ResultFuture<List<HistoryEntry>> getHistory({
    int limit = 50,
    int offset = 0,
  }) {
    return _guard(() async {
      final raw = await _remote.getSongHistory(limit: limit, offset: offset);
      final entries =
          raw
              .map(SongHistoryEntryModel.fromJson)
              .map((m) => m.toDomain())
              .toList()
            // Newest first, whatever order the backend sends.
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    });
  }

  @override
  ResultFuture<bool> saveResultToHistory(ResultHistoryRecord record) {
    return _guard(() => _remote.saveResultToHistory(record.toJson()));
  }

  @override
  ResultFuture<PlaylistAnalysis> getAnalysisById(String analysisId) {
    return _guard(() async {
      final json = await _remote.getAnalysisById(analysisId);
      final model = PlaylistAnalysisModel.fromJson(json);
      return model.toDomain();
    });
  }

  @override
  ResultFuture<SongAnalysisResult> analyzeSong(String trackId) {
    return _guard(() async {
      final json = await _remote.analyzeSong(trackId);
      final model = SongAnalysisResultModel.fromJson(json);
      return model.toDomain();
    });
  }

  /// Runs [body] and maps whatever it throws to a [Failure].
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
    // A malformed payload fails while parsing with a TypeError or another
    // Error; report it as a failure instead of letting it escape.
    // ignore: avoid_catching_errors
    on Error {
      return const Left(ServerFailure(malformedResponseMessage));
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
    if (e.response?.statusCode == 429) {
      return RateLimitFailure(message ?? 'Too many requests');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkFailure(message ?? 'Network error');
    }
    return ServerFailure(message ?? 'Server error');
  }

  @override
  ResultFuture<AudioUploadAnalysis> analyzeUploadedAudio({
    required Uint8List bytes,
    required String filename,
    String? title,
    String? artist,
    String? album,
  }) {
    return _guard(() async {
      final json = await _uploadRemote.uploadAndAnalyzeAudio(
        bytes: bytes,
        filename: filename,
        title: title,
        artist: artist,
        album: album,
      );
      final model = AudioUploadAnalysisModel.fromJson(json);
      return model.toDomain();
    });
  }

  @override
  ResultFuture<AudioUploadAnalysis> analyzeCatalogTrack({
    required String audioUrl,
    required String trackId,
    required String trackName,
    required String artistName,
    required String jamendoPageUrl,
  }) {
    return _guard(() async {
      final json = await _uploadRemote.analyzeCatalogTrack(
        audioUrl: audioUrl,
        trackId: trackId,
        trackName: trackName,
        artistName: artistName,
        jamendoPageUrl: jamendoPageUrl,
      );
      final model = AudioUploadAnalysisModel.fromJson(json);
      return model.toDomain();
    });
  }
}
