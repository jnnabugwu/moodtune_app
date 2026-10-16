import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:moodtune_app/features/mood_feedback/data/datasources/app_config_remote_datasource.dart';
import 'package:moodtune_app/features/mood_feedback/data/datasources/mood_observation_remote_datasource.dart';

import '../../mood_feedback_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;

  // Keep test output readable: the datasources wire TalkerDioLogger.
  setUpAll(talker.disable);
  tearDownAll(talker.enable);

  setUp(() {
    adapter = FakeHttpClientAdapter(body: {'id': observationId});
  });

  group('MoodObservationRemoteDataSource', () {
    MoodObservationRemoteDataSource build({String? token}) =>
        MoodObservationRemoteDataSource(
          dio: fakeDio(adapter),
          tokenProvider: () async => token,
        );

    test('wires the standard interceptors', () {
      final dio = fakeDio(adapter);
      MoodObservationRemoteDataSource(dio: dio);

      expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
    });

    test('defaultBaseUrl points at the local backend', () {
      expect(
        MoodObservationRemoteDataSource.defaultBaseUrl,
        'http://127.0.0.1:8000/api/v1',
      );
    });

    test('recordObservation POSTs the body to /mood-observations', () async {
      adapter.statusCode = 201;
      await build(
        token: 'tok',
      ).recordObservation({'id': observationId, 'source': 'upload'});

      final req = adapter.lastRequest;
      expect(req.method, 'POST');
      expect(req.path, '/mood-observations');
      expect(req.headers['Authorization'], 'Bearer tok');
      expect(req.data, {'id': observationId, 'source': 'upload'});
    });

    test('omits Authorization for guests', () async {
      await build().recordObservation({'id': observationId});
      expect(adapter.lastRequest.headers.containsKey('Authorization'), false);

      await MoodObservationRemoteDataSource(
        dio: fakeDio(adapter),
      ).recordObservation({'id': observationId});
      expect(adapter.lastRequest.headers.containsKey('Authorization'), false);
    });

    test('sendFeedback PATCHes agrees + user_mood', () async {
      await build(
        token: 'tok',
      ).sendFeedback(id: observationId, agrees: false, userMood: 'serene');

      final req = adapter.lastRequest;
      expect(req.method, 'PATCH');
      expect(req.path, '/mood-observations/$observationId/feedback');
      expect(req.headers['Authorization'], 'Bearer tok');
      expect(req.data, {'agrees': false, 'user_mood': 'serene'});
    });

    test('sendFeedback sends a null user_mood when agreeing', () async {
      await build().sendFeedback(id: observationId, agrees: true);

      expect(adapter.lastRequest.data, {'agrees': true, 'user_mood': null});
    });

    test('throws DioException on an error status', () async {
      adapter
        ..statusCode = 404
        ..body = {'detail': 'Mood observation not found'};

      await expectLater(
        build().sendFeedback(id: observationId, agrees: true),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AppConfigRemoteDataSource', () {
    test('wires the standard interceptors', () {
      final dio = fakeDio(adapter);
      AppConfigRemoteDataSource(dio: dio);

      expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
    });

    test('defaultBaseUrl points at the local backend', () {
      expect(
        AppConfigRemoteDataSource.defaultBaseUrl,
        'http://127.0.0.1:8000/api/v1',
      );
    });

    test('fetchConfig GETs /config without auth', () async {
      adapter.body = {'on_device_mood': false};

      final json = await AppConfigRemoteDataSource(
        dio: fakeDio(adapter),
      ).fetchConfig();

      final req = adapter.lastRequest;
      expect(req.method, 'GET');
      expect(req.path, '/config');
      expect(req.headers.containsKey('Authorization'), false);
      expect(json, {'on_device_mood': false});
    });

    test('fetchConfig returns an empty map for an empty body', () async {
      adapter.body = null;

      expect(
        await AppConfigRemoteDataSource(dio: fakeDio(adapter)).fetchConfig(),
        isEmpty,
      );
    });
  });
}
