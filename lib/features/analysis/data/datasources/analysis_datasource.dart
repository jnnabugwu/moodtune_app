import 'package:dio/dio.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

typedef AnalysisTokenProvider = Future<String?> Function();

class AnalysisRemoteDataSource {
  AnalysisRemoteDataSource({
    Dio? dio,
    String baseUrl = defaultBaseUrl,
    AnalysisTokenProvider? tokenProvider,
  }) : _tokenProvider = tokenProvider ?? _noToken,
       _dio =
           dio ??
                 Dio(
                   BaseOptions(
                     baseUrl: baseUrl,
                     connectTimeout: const Duration(seconds: 10),
                     receiveTimeout: const Duration(seconds: 10),
                   ),
                 )
            ..interceptors.add(AuthInterceptor())
            ..interceptors.add(TalkerDioLogger(talker: talker))
            ..addSentry();

  static const defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
  final Dio _dio;
  final AnalysisTokenProvider _tokenProvider;

  static Future<String?> _noToken() async => null;

  Future<Options> _options() async {
    final token = await _tokenProvider();
    return Options(
      headers: token != null
          ? {
              'Authorization': 'Bearer $token',
            }
          : null,
    );
  }

  Future<Map<String, dynamic>> analyzePlaylist(
    String playlistId, {
    int limit = 50,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/analysis/analyze/$playlistId',
      queryParameters: {
        'limit': limit,
      },
      options: await _options(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getHistory({
    int limit = 3,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/analysis/history',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
      options: await _options(),
    );
    final data = response.data ?? <String, dynamic>{};
    return (data['analyses'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getAnalysisById(String analysisId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/analysis/$analysisId',
      options: await _options(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> analyzeSong(String trackId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/song/analyze/$trackId',
      options: await _options(),
    );
    return response.data ?? <String, dynamic>{};
  }
}
