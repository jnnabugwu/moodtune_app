import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interceptor that handles token refresh on 401 errors.
///
/// The retry goes back through [_dio], the client that owns this
/// interceptor, so it keeps that client's logging and Sentry. A retried
/// request is marked with [retriedKey] in `extra`; a 401 on it is passed
/// through instead of refreshing again.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  /// `RequestOptions.extra` key set on the one retry after a refresh.
  static const retriedKey = 'auth_interceptor_retried';

  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    // Only handle 401 Unauthorized errors, and only once per request.
    if (err.response?.statusCode == 401 && options.extra[retriedKey] != true) {
      try {
        // Attempt to refresh the Supabase session
        final session = await Supabase.instance.client.auth.refreshSession();

        if (session.session != null) {
          // Update the original request with the new token
          options.headers['Authorization'] =
              'Bearer ${session.session!.accessToken}';
          options.extra[retriedKey] = true;

          // A sent FormData is finalized and can't be sent again; resend a
          // copy. The copy re-reads each file from its source, so build
          // uploads with `MultipartFile.fromBytes`/`fromFile`/`fromStream`,
          // not the deprecated single-use `MultipartFile()` constructor.
          final data = options.data;
          if (data is FormData) options.data = data.clone();

          // Same timeouts as the original: these are the original options.
          final response = await _dio.fetch<dynamic>(options);

          return handler.resolve(response);
        }
      } on Exception catch (_) {
        // If refresh or the retry fails, continue with the original error.
        // This will likely result in the user needing to re-authenticate.
      }
    }

    // For non-401 errors or if refresh failed, pass through the original error
    return handler.next(err);
  }
}

/// Adds an [AuthInterceptor] that retries through this [Dio].
extension AuthInterceptorDio on Dio {
  void addAuthInterceptor() => interceptors.add(AuthInterceptor(this));
}
