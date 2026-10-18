import 'package:dio/dio.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

typedef AccountTokenProvider = Future<String?> Function();

/// `DELETE /account`: deletes the signed-in user's account on the backend,
/// which holds the Supabase service role. The app never deletes users
/// itself.
///
/// The backend (moodtune-backend#15) answers 204 when the account was
/// deleted; 401 when the token is missing or invalid, which includes a retry
/// after a successful delete; and 500 `{"detail": "Could not delete
/// account"}` when a step failed (safe to retry). Non-2xx responses and
/// network errors surface as [DioException]s.
class AccountRemoteDataSource {
  AccountRemoteDataSource({
    Dio? dio,
    String baseUrl = defaultBaseUrl,
    AccountTokenProvider? tokenProvider,
  }) : _tokenProvider = tokenProvider ?? _noToken,
       _dio =
           dio ??
                 Dio(
                   BaseOptions(
                     baseUrl: baseUrl,
                     connectTimeout: const Duration(seconds: 10),
                     receiveTimeout: const Duration(seconds: 30),
                     sendTimeout: const Duration(seconds: 15),
                   ),
                 )
             ..addAuthInterceptor()
             ..interceptors.add(TalkerDioLogger(talker: talker))
             ..addSentry();

  static const defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
  final Dio _dio;
  final AccountTokenProvider _tokenProvider;

  static Future<String?> _noToken() async => null;

  Future<void> deleteAccount() async {
    final token = await _tokenProvider();
    await _dio.delete<void>(
      '/account',
      options: Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      ),
    );
  }
}
