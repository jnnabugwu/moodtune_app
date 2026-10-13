import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Shared JSON payloads and HTTP fakes for analysis data-layer tests.

Map<String, dynamic> trackJson({
  String id = 't1',
  String name = 'Track One',
}) => <String, dynamic>{
  'track_id': id,
  'track_name': name,
  'artists': <dynamic>['Artist A', 'Artist B'],
  'valence': 0.7,
  'energy': 1,
  'danceability': 0.55,
  'mood_label': 'happy',
};

Map<String, dynamic> averagesJson() => <String, dynamic>{
  'valence': 0.6,
  'energy': 0.8,
  'danceability': 0.5,
  'tempo': 120,
  'acousticness': 0.1,
  'instrumentalness': 0.05,
};

Map<String, dynamic> moodDistributionJson() => <String, dynamic>{
  'happy': 0.4,
  'sad': 0.1,
  'energetic': 0.3,
  'calm': 0.1,
  'danceable': 0.1,
};

Map<String, dynamic> moodResultJson() => <String, dynamic>{
  'primary_mood': 'Happy',
  'mood_category': 'positive',
  'mood_descriptors': <dynamic>['upbeat', 'bright'],
  'confidence': 0.87,
  'averages': averagesJson(),
  'mood_distribution': moodDistributionJson(),
  'top_tracks': <dynamic>[trackJson(), trackJson(id: 't2', name: 'Two')],
  'track_count': 25,
};

Map<String, dynamic> playlistAnalysisJson() => <String, dynamic>{
  'id': 'analysis-1',
  'playlist_id': 'pl-1',
  'playlist_name': 'Road Trip',
  'mood_results': moodResultJson(),
  'created_at': '2025-01-02T03:04:05.000Z',
  'user_id': 'user-1',
};

Map<String, dynamic> songAnalysisJson() => <String, dynamic>{
  'track_name': 'Song',
  'artist_name': 'Singer',
  'track_id': 'trk-1',
  'mood': <String, dynamic>{
    'primary_mood': 'Calm',
    'confidence': 0.9,
    'valence': 0.3,
    'energy': 0.2,
  },
  'features': <String, dynamic>{
    'tempo': 90,
    'energy': 0.2,
    'valence': 0.3,
    'danceability': 0.4,
    'loudness': -7.5,
  },
  'success': true,
  'message': 'ok',
};

Map<String, dynamic> uploadFeaturesJson() => <String, dynamic>{
  'tempo': 128,
  'beat_strength': 0.9,
  'spectral_centroid': 2500.5,
  'spectral_rolloff': 4000,
  'spectral_bandwidth': 1800.25,
  'harmonic_ratio': 0.6,
  'zero_crossing_rate': 0.08,
  'rms_energy': 0.3,
  'dynamic_range': 12,
  'mfcc_mean': <dynamic>[1, 2.5, -3],
  'duration_seconds': 210.5,
  'energy_label': 'High (0.84)',
  'brightness_label': 'Bright',
  'texture_label': 'Smooth',
};

Map<String, dynamic> audioUploadJson() => <String, dynamic>{
  'id': 'up-1',
  'filename': 'song.mp3',
  'file_size_bytes': 123456,
  'duration_seconds': 210.5,
  'title': 'Title',
  'artist': 'Artist',
  'album': 'Album',
  'mood': <String, dynamic>{
    'primary_mood': 'Energetic',
    'mood_scores': <String, dynamic>{'energetic': 0.8, 'happy': 1},
    'confidence': 0.75,
    'reasoning': 'Fast tempo',
    'audio_features': uploadFeaturesJson(),
    'descriptors': <dynamic>['upbeat', 'danceable'],
  },
  'analysis_method': 'catalog',
  'processed_at': '2025-05-06T07:08:09.000Z',
  'processing_time_seconds': 4.2,
  'jamendo_track_url': 'https://jamendo.com/track/1',
};

Map<String, dynamic> songHistoryJson({String id = 'sh-1'}) => <String, dynamic>{
  'id': id,
  'track_name': 'Song',
  'artist_name': 'Singer',
  'mood_results': <String, dynamic>{
    'primary_mood': 'Sad',
    'confidence': 0.65,
  },
  'created_at': '2025-03-04T05:06:07.000Z',
};

Map<String, dynamic> playlistHistoryJson() => <String, dynamic>{
  'id': 'ph-1',
  'playlist_name': 'Chill',
  'mood_results': <String, dynamic>{'primary_mood': 'Calm', 'confidence': 1},
  'created_at': '2025-03-04T05:06:07.000Z',
};

/// A [HttpClientAdapter] that records every request and replies with a
/// canned JSON body / status code.
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter({this.statusCode = 200, this.body});

  int statusCode;

  /// JSON-encodable body. `null` produces an empty response body.
  Object? body;

  final List<RequestOptions> requests = [];
  final List<Uint8List> requestBodies = [];

  RequestOptions get lastRequest => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      final builder = BytesBuilder();
      await requestStream.forEach(builder.add);
      requestBodies.add(builder.takeBytes());
    }
    final encoded = body == null ? '' : jsonEncode(body);
    return ResponseBody.fromString(
      encoded,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Builds a [Dio] wired to [adapter], pointed at a fake base URL.
Dio fakeDio(FakeHttpClientAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = adapter;
