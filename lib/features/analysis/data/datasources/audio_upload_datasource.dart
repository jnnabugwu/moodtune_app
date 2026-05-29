import 'package:dio/dio.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

typedef AudioUploadTokenProvider = Future<String?> Function();

class AudioUploadRemoteDataSource {
  AudioUploadRemoteDataSource({
    Dio? dio,
    String baseUrl = defaultBaseUrl,
    AudioUploadTokenProvider? tokenProvider,
  }) : _tokenProvider = tokenProvider ?? _noToken,
       _dio =
           dio ??
                 Dio(
                   BaseOptions(
                     baseUrl: baseUrl,
                     connectTimeout: const Duration(seconds: 30),
                     receiveTimeout: const Duration(seconds: 90),
                     sendTimeout: const Duration(seconds: 90),
                   ),
                 )
             ..interceptors.add(AuthInterceptor())
             ..interceptors.add(TalkerDioLogger(talker: talker))
             ..addSentry();

  static const defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
  final Dio _dio;
  final AudioUploadTokenProvider _tokenProvider;

  static Future<String?> _noToken() async => null;

  Future<Options> _options() async {
    final token = await _tokenProvider();
    return Options(
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
  }

  Future<Map<String, dynamic>> analyzeCatalogTrack({
    required String audioUrl,
    required String trackId,
    required String trackName,
    required String artistName,
    required String jamendoPageUrl,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/catalog/analyze',
      data: {
        'audio_url': audioUrl,
        'track_id': trackId,
        'track_name': trackName,
        'artist_name': artistName,
        'jamendo_page_url': jamendoPageUrl,
      },
      options: await _options(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> uploadAndAnalyzeAudio({
    required List<int> bytes,
    required String filename,
    String? title,
    String? artist,
    String? album,
  }) async {
    final data = FormData.fromMap({
      'audio_file': MultipartFile.fromBytes(bytes, filename: filename),
      if (title != null && title.isNotEmpty) 'title': title,
      if (artist != null && artist.isNotEmpty) 'artist': artist,
      if (album != null && album.isNotEmpty) 'album': album,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/audio-upload/analyze',
      data: data,
      options: await _options(),
    );
    return response.data ?? <String, dynamic>{};
  }
}
