import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/entities.dart';

/// Records requests and replies with [statusCode] + JSON [body].
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter({this.statusCode = 200, this.body});

  int statusCode;

  /// JSON-encodable body. `null` produces an empty response body.
  Object? body;

  final List<RequestOptions> requests = [];

  RequestOptions get lastRequest => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) await requestStream.drain<void>();
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

Dio fakeDio(FakeHttpClientAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = adapter;

const observationId = '7b0c5a52-3f0e-4d4a-9a59-0d7f6a3c2e11';

MoodObservation sampleObservation({
  String? platform,
  String? osVersion,
  String? deviceModel,
  String? appVersion,
}) => MoodObservation(
  id: observationId,
  source: MoodObservationSource.upload,
  analysisId: 'an-1',
  backendMood: 'happy',
  onDeviceMood: 'calm',
  onDeviceTags: const ['vocals', 'piano'],
  onDeviceProbabilities: const {'happy': 0.2, 'calm': 0.8},
  onDeviceLatencyMs: 840,
  displayedMood: 'calm',
  displayedSource: DisplayedMoodSource.onDevice,
  platform: platform,
  osVersion: osVersion,
  deviceModel: deviceModel,
  appVersion: appVersion,
);

const sampleDevice = DeviceDetails(
  platform: 'ios',
  osVersion: '18.1',
  deviceModel: 'iPhone15,2',
  appVersion: '1.0.0+7',
);
