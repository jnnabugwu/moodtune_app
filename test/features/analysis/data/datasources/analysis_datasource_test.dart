import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:moodtune_app/features/analysis/data/datasources/analysis_datasource.dart';

import '../analysis_data_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;

  // Keep test output readable: the datasource wires TalkerDioLogger.
  setUpAll(talker.disable);
  tearDownAll(talker.enable);

  setUp(() {
    adapter = FakeHttpClientAdapter(body: <String, dynamic>{'ok': true});
  });

  AnalysisRemoteDataSource build({String? token}) => AnalysisRemoteDataSource(
    dio: fakeDio(adapter),
    tokenProvider: () async => token,
  );

  group('AnalysisRemoteDataSource', () {
    test('also attaches its interceptors to an injected Dio', () {
      // Documents current behaviour: the `..interceptors.add` cascade binds
      // to the whole `dio ?? Dio(...)` expression, so a caller-supplied Dio
      // is mutated too.
      final dio = fakeDio(adapter);
      expect(dio.interceptors.whereType<AuthInterceptor>(), isEmpty);

      AnalysisRemoteDataSource(dio: dio);

      expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
    });

    test('defaultBaseUrl points at the local backend', () {
      expect(
        AnalysisRemoteDataSource.defaultBaseUrl,
        'http://127.0.0.1:8000/api/v1',
      );
    });

    group('auth header', () {
      test('adds Bearer token when the provider returns one', () async {
        await build(token: 'abc').analyzeSong('t1');

        expect(adapter.lastRequest.headers['Authorization'], 'Bearer abc');
      });

      test('omits Authorization when the provider returns null', () async {
        await build().analyzeSong('t1');

        expect(adapter.lastRequest.headers.containsKey('Authorization'), false);
      });

      test('omits Authorization when no provider is supplied', () async {
        await AnalysisRemoteDataSource(dio: fakeDio(adapter)).analyzeSong('t');

        expect(adapter.lastRequest.headers.containsKey('Authorization'), false);
      });

      test('reads the token fresh on every call', () async {
        var calls = 0;
        final ds = AnalysisRemoteDataSource(
          dio: fakeDio(adapter),
          tokenProvider: () async => 'tok${++calls}',
        );

        await ds.analyzeSong('a');
        await ds.analyzeSong('b');

        expect(adapter.requests.map((r) => r.headers['Authorization']), [
          'Bearer tok1',
          'Bearer tok2',
        ]);
      });
    });

    group('analyzePlaylist', () {
      test('POSTs to /analysis/analyze/{id} with default limit', () async {
        adapter.body = playlistAnalysisJson();

        final result = await build().analyzePlaylist('pl-9');

        expect(adapter.lastRequest.method, 'POST');
        expect(adapter.lastRequest.path, '/analysis/analyze/pl-9');
        expect(adapter.lastRequest.queryParameters, {'limit': 50});
        expect(result['playlist_name'], 'Road Trip');
      });

      test('forwards a custom limit', () async {
        await build().analyzePlaylist('pl', limit: 5);

        expect(adapter.lastRequest.queryParameters, {'limit': 5});
      });

      test('returns an empty map when the body is empty', () async {
        adapter.body = null;

        expect(await build().analyzePlaylist('pl'), isEmpty);
      });
    });

    group('getHistory', () {
      test('GETs /analysis/history and unwraps analyses', () async {
        adapter.body = <String, dynamic>{
          'analyses': [playlistHistoryJson()],
        };

        final result = await build().getHistory();

        expect(adapter.lastRequest.method, 'GET');
        expect(adapter.lastRequest.path, '/analysis/history');
        expect(adapter.lastRequest.queryParameters, {'limit': 3, 'offset': 0});
        expect(result, hasLength(1));
        expect(result.single['playlist_name'], 'Chill');
      });

      test('forwards limit and offset', () async {
        adapter.body = <String, dynamic>{'analyses': <dynamic>[]};

        await build().getHistory(limit: 10, offset: 20);

        expect(adapter.lastRequest.queryParameters, {
          'limit': 10,
          'offset': 20,
        });
      });

      test('returns empty list when analyses key is missing', () async {
        adapter.body = <String, dynamic>{};

        expect(await build().getHistory(), isEmpty);
      });

      test('returns empty list when body is empty', () async {
        adapter.body = null;

        expect(await build().getHistory(), isEmpty);
      });
    });

    group('getAnalysisById', () {
      test('GETs /analysis/{id}', () async {
        adapter.body = playlistAnalysisJson();

        final result = await build().getAnalysisById('a-1');

        expect(adapter.lastRequest.method, 'GET');
        expect(adapter.lastRequest.path, '/analysis/a-1');
        expect(result['id'], 'analysis-1');
      });

      test('returns an empty map when the body is empty', () async {
        adapter.body = null;

        expect(await build().getAnalysisById('a'), isEmpty);
      });
    });

    group('analyzeSong', () {
      test('POSTs to /song/analyze/{trackId}', () async {
        adapter.body = songAnalysisJson();

        final result = await build().analyzeSong('trk-1');

        expect(adapter.lastRequest.method, 'POST');
        expect(adapter.lastRequest.path, '/song/analyze/trk-1');
        expect(result['track_name'], 'Song');
      });

      test('returns an empty map when the body is empty', () async {
        adapter.body = null;

        expect(await build().analyzeSong('t'), isEmpty);
      });
    });

    group('getSongHistory', () {
      test('GETs /song/history with default paging', () async {
        adapter.body = <String, dynamic>{
          'analyses': [songHistoryJson(), songHistoryJson(id: 'sh-2')],
        };

        final result = await build().getSongHistory();

        expect(adapter.lastRequest.method, 'GET');
        expect(adapter.lastRequest.path, '/song/history');
        expect(adapter.lastRequest.queryParameters, {
          'limit': 50,
          'offset': 0,
        });
        expect(result.map((e) => e['id']), ['sh-1', 'sh-2']);
      });

      test('forwards limit and offset', () async {
        adapter.body = <String, dynamic>{'analyses': <dynamic>[]};

        await build().getSongHistory(limit: 2, offset: 4);

        expect(adapter.lastRequest.queryParameters, {'limit': 2, 'offset': 4});
      });

      test('returns empty list for empty body or missing key', () async {
        adapter.body = null;
        expect(await build().getSongHistory(), isEmpty);

        adapter.body = <String, dynamic>{'other': 1};
        expect(await build().getSongHistory(), isEmpty);
      });
    });

    test('non-2xx responses surface as DioException', () async {
      adapter
        ..statusCode = 404
        ..body = <String, dynamic>{'detail': 'Not found'};

      await expectLater(
        build().getAnalysisById('missing'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.badResponse)
              .having((e) => e.response?.statusCode, 'status', 404),
        ),
      );
    });
  });

  group('AnalysisRemoteDataSource with default Dio', () {
    late HttpServer server;
    late List<HttpHeaders> seenHeaders;
    late List<Uri> seenUris;
    HttpOverrides? previousOverrides;

    setUp(() async {
      // Widget tests sharing this isolate install a stub HttpClient that
      // answers 400; these tests need real loopback I/O.
      previousOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      seenHeaders = [];
      seenUris = [];
      server = (await HttpServer.bind(InternetAddress.loopbackIPv4, 0))
        ..listen((request) async {
          seenHeaders.add(request.headers);
          seenUris.add(request.uri);
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(songAnalysisJson()));
          await request.response.close();
        });
    });

    tearDown(() async {
      HttpOverrides.global = previousOverrides;
      await server.close(force: true);
    });

    test('builds a working client against the provided baseUrl', () async {
      final ds = AnalysisRemoteDataSource(
        baseUrl: 'http://127.0.0.1:${server.port}/api/v1',
        tokenProvider: () async => 'real-token',
      );

      final result = await ds.analyzeSong('trk-1');

      expect(result['track_name'], 'Song');
      expect(seenUris.single.path, '/api/v1/song/analyze/trk-1');
      expect(seenHeaders.single.value('authorization'), 'Bearer real-token');
    });
  });
}
