import 'package:dio/dio.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

typedef MoodFeedbackTokenProvider = Future<String?> Function();

/// `POST /mood-observations` and `PATCH /mood-observations/{id}/feedback`.
///
/// Both endpoints accept guests; a token (when available) attributes the
/// observation to the signed-in user.
class MoodObservationRemoteDataSource {
  MoodObservationRemoteDataSource({
    Dio? dio,
    String baseUrl = defaultBaseUrl,
    MoodFeedbackTokenProvider? tokenProvider,
  }) : _tokenProvider = tokenProvider ?? _noToken,
       _dio =
           dio ??
                 Dio(
                   BaseOptions(
                     baseUrl: baseUrl,
                     connectTimeout: const Duration(seconds: 10),
                     receiveTimeout: const Duration(seconds: 15),
                     sendTimeout: const Duration(seconds: 15),
                   ),
                 )
             ..addAuthInterceptor()
             ..interceptors.add(TalkerDioLogger(talker: talker))
             ..addSentry();

  static const defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
  final Dio _dio;
  final MoodFeedbackTokenProvider _tokenProvider;

  static Future<String?> _noToken() async => null;

  Future<Options> _options() async {
    final token = await _tokenProvider();
    return Options(
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
  }

  /// Upserts one observation. [body] is `MoodObservation.toJson()`.
  Future<void> recordObservation(Map<String, dynamic> body) async {
    await _dio.post<Map<String, dynamic>>(
      '/mood-observations',
      data: body,
      options: await _options(),
    );
  }

  /// [userMood] is a `MoodIdentity` name (`upbeat`, `serene`, `charged`,
  /// `reflective`) or null.
  Future<void> sendFeedback({
    required String id,
    required bool agrees,
    String? userMood,
  }) async {
    await _dio.patch<Map<String, dynamic>>(
      '/mood-observations/${Uri.encodeComponent(id)}/feedback',
      data: {'agrees': agrees, 'user_mood': userMood},
      options: await _options(),
    );
  }
}
