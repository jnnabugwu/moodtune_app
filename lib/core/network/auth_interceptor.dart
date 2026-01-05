import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interceptor that handles token refresh on 401 errors
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      try {
        // Attempt to refresh the Supabase session
        final session = await Supabase.instance.client.auth.refreshSession();
        
        if (session.session != null) {
          // Get the new access token
          final newToken = session.session!.accessToken;
          
          // Update the original request with the new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          
          // Retry the original request using a new Dio instance with same config
          final dio = Dio(BaseOptions(
            baseUrl: options.baseUrl,
            connectTimeout: options.connectTimeout,
            receiveTimeout: options.receiveTimeout,
          ));
          
          final response = await dio.fetch<dynamic>(options);
          
          return handler.resolve(response);
        }
      } catch (e) {
        // If refresh fails, continue with the original error
        // This will likely result in the user needing to re-authenticate
      }
    }
    
    // For non-401 errors or if refresh failed, pass through the original error
    return handler.next(err);
  }
}
