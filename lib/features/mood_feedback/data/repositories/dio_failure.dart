import 'package:dio/dio.dart';
import 'package:moodtune_app/core/error/error.dart';

/// Maps a [DioException] to a [Failure], preferring the backend's `detail`.
/// Mirrors `AnalysisRepositoryImpl`'s mapping.
Failure mapDioFailure(DioException e) {
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
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return NetworkFailure(message ?? 'Network error');
  }
  return ServerFailure(message ?? 'Server error');
}
