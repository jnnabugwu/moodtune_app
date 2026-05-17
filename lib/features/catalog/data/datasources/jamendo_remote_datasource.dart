import 'package:dio/dio.dart';
import 'package:moodtune_app/core/error/exceptions.dart';
import 'package:moodtune_app/features/catalog/data/models/jamendo_track_model.dart';

/// Talks directly to the Jamendo API v3.
///
/// Client ID is injected at construction time from the JAMENDO_CLIENT_ID
/// env var (passed via --dart-define-from-file=.env).
class JamendoRemoteDataSource {
  JamendoRemoteDataSource({
    required this.clientId,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.jamendo.com/v3.0',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  static const _limit = 20;

  final String clientId;
  final Dio _dio;

  /// Searches tracks by free-text [query] and/or [moodTag].
  /// Returns raw models — the repository filters by audiodownloadAllowed.
  Future<List<JamendoTrackModel>> searchTracks({
    String? query,
    String? moodTag,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'client_id': clientId,
        'format': 'json',
        'limit': _limit,
        'include': 'musicinfo',
        // Jamendo only accepts preset sizes; 50 is closest to the 48px target
        'imagesize': 50,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['namesearch'] = query;
      }
      if (moodTag != null && moodTag.isNotEmpty) {
        queryParams['tags'] = moodTag;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/tracks/',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data == null) throw const ServerException('Empty response');

      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .map(
            (e) =>
                JamendoTrackModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?.toString() ?? e.message ?? 'Jamendo API error',
      );
    }
  }
}
