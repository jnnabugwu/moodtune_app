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
  }) : _dio =
           dio ??
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
  ///
  /// When a [query] is provided we fire two requests in parallel:
  ///   1. `search=<query>` — matches track name + artist name
  ///   2. `tags=<query>`   — matches Jamendo genre/mood tags
  /// Results are merged and deduplicated by track ID so that genre words
  /// like "tropical" or "jazz" return results even if no track is *named*
  /// that way. A [moodTag] (from the chip row) is applied on top of both
  /// requests.
  ///
  /// Returns raw models — the repository filters by audiodownloadAllowed.
  Future<List<JamendoTrackModel>> searchTracks({
    String? query,
    String? moodTag,
  }) async {
    try {
      if (query != null && query.isNotEmpty) {
        // Fire text-search and tag-search in parallel.
        final results = await Future.wait([
          _fetchTracks(search: query, moodTag: moodTag),
          _fetchTracks(tags: query, moodTag: moodTag),
        ]);
        // Merge and deduplicate by track ID; text-search results come first.
        final seen = <String>{};
        return [
          ...results[0],
          ...results[1],
        ].where((t) => seen.add(t.id)).toList();
      }

      // No text query — mood chip only.
      return _fetchTracks(moodTag: moodTag);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?.toString() ?? e.message ?? 'Jamendo API error',
      );
    }
  }

  /// Low-level GET /tracks/ call. [search] uses Jamendo's name+artist search;
  /// [tags] filters by genre/mood tag; [moodTag] is an additional tag filter.
  Future<List<JamendoTrackModel>> _fetchTracks({
    String? search,
    String? tags,
    String? moodTag,
  }) async {
    final queryParams = <String, dynamic>{
      'client_id': clientId,
      'format': 'json',
      'limit': _limit,
      'include': 'musicinfo',
      // Jamendo only accepts preset sizes; 50 is closest to the 48px target
      'imagesize': 50,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (tags != null && tags.isNotEmpty) {
      queryParams['tags'] = tags;
    }
    if (moodTag != null && moodTag.isNotEmpty) {
      // Append to any existing tags value with a space (Jamendo treats as AND)
      final existing = queryParams['tags'] as String?;
      queryParams['tags'] =
          existing != null ? '$existing $moodTag' : moodTag;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/tracks/',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data == null) throw const ServerException('Empty response');

    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => JamendoTrackModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
