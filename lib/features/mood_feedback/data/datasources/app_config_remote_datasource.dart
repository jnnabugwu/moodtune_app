import 'package:dio/dio.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

/// `GET /config` (unauthenticated). Short timeouts: callers fall back to
/// defaults rather than wait on it.
class AppConfigRemoteDataSource {
  AppConfigRemoteDataSource({Dio? dio, String baseUrl = defaultBaseUrl})
    : _dio =
          dio ??
                Dio(
                  BaseOptions(
                    baseUrl: baseUrl,
                    connectTimeout: const Duration(seconds: 5),
                    receiveTimeout: const Duration(seconds: 5),
                  ),
                )
            ..addAuthInterceptor()
            ..interceptors.add(TalkerDioLogger(talker: talker))
            ..addSentry();

  static const defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
  final Dio _dio;

  Future<Map<String, dynamic>> fetchConfig() async {
    final response = await _dio.get<Map<String, dynamic>>('/config');
    return response.data ?? <String, dynamic>{};
  }
}
