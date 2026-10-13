import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:moodtune_app/features/analysis/data/datasources/audio_upload_datasource.dart';

import '../analysis_data_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;

  // Keep test output readable: the datasource wires TalkerDioLogger.
  setUpAll(talker.disable);
  tearDownAll(talker.enable);

  setUp(() {
    adapter = FakeHttpClientAdapter(body: audioUploadJson());
  });

  AudioUploadRemoteDataSource build({String? token}) =>
      AudioUploadRemoteDataSource(
        dio: fakeDio(adapter),
        tokenProvider: () async => token,
      );

  group('AudioUploadRemoteDataSource', () {
    test('also attaches its interceptors to an injected Dio', () {
      // Documents current behaviour: the `..interceptors.add` cascade binds
      // to the whole `dio ?? Dio(...)` expression, so a caller-supplied Dio
      // is mutated too.
      final dio = fakeDio(adapter);
      expect(dio.interceptors.whereType<AuthInterceptor>(), isEmpty);

      AudioUploadRemoteDataSource(dio: dio);

      expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
    });

    test('defaultBaseUrl points at the local backend', () {
      expect(
        AudioUploadRemoteDataSource.defaultBaseUrl,
        'http://127.0.0.1:8000/api/v1',
      );
    });

    group('analyzeCatalogTrack', () {
      Future<Map<String, dynamic>> call(AudioUploadRemoteDataSource ds) =>
          ds.analyzeCatalogTrack(
            audioUrl: 'https://cdn/a.mp3',
            trackId: 'j1',
            trackName: 'Name',
            artistName: 'Artist',
            jamendoPageUrl: 'https://jamendo/j1',
          );

      test('POSTs snake_case JSON body to /catalog/analyze', () async {
        final result = await call(build(token: 'tok'));

        final req = adapter.lastRequest;
        expect(req.method, 'POST');
        expect(req.path, '/catalog/analyze');
        expect(req.headers['Authorization'], 'Bearer tok');
        expect(req.data, {
          'audio_url': 'https://cdn/a.mp3',
          'track_id': 'j1',
          'track_name': 'Name',
          'artist_name': 'Artist',
          'jamendo_page_url': 'https://jamendo/j1',
        });
        expect(result['id'], 'up-1');
      });

      test('omits Authorization without a token', () async {
        await call(build());

        expect(adapter.lastRequest.headers.containsKey('Authorization'), false);
      });

      test('omits Authorization when no provider is supplied', () async {
        await call(AudioUploadRemoteDataSource(dio: fakeDio(adapter)));

        expect(adapter.lastRequest.headers.containsKey('Authorization'), false);
      });

      test('returns an empty map when the body is empty', () async {
        adapter.body = null;

        expect(await call(build()), isEmpty);
      });
    });

    group('uploadAndAnalyzeAudio', () {
      test('POSTs multipart form with file and metadata', () async {
        final result = await build(token: 'tok').uploadAndAnalyzeAudio(
          bytes: utf8.encode('audio-bytes'),
          filename: 'song.mp3',
          title: 'Title',
          artist: 'Artist',
          album: 'Album',
        );

        final req = adapter.lastRequest;
        expect(req.method, 'POST');
        expect(req.path, '/audio-upload/analyze');
        expect(req.headers['Authorization'], 'Bearer tok');
        expect(req.contentType, startsWith('multipart/form-data'));

        final form = req.data as FormData;
        expect(form.files.single.key, 'audio_file');
        expect(form.files.single.value.filename, 'song.mp3');
        expect(form.files.single.value.length, 'audio-bytes'.length);
        expect(Map.fromEntries(form.fields), {
          'title': 'Title',
          'artist': 'Artist',
          'album': 'Album',
        });

        final sentBody = utf8.decode(adapter.requestBodies.single);
        expect(sentBody, contains('audio-bytes'));
        expect(sentBody, contains('filename="song.mp3"'));
        expect(result['filename'], 'song.mp3');
      });

      test('omits null metadata fields', () async {
        await build().uploadAndAnalyzeAudio(bytes: [1, 2, 3], filename: 'a');

        final form = adapter.lastRequest.data as FormData;
        expect(form.fields, isEmpty);
        expect(form.files, hasLength(1));
        expect(adapter.lastRequest.headers.containsKey('Authorization'), false);
      });

      test('omits empty-string metadata fields', () async {
        await build().uploadAndAnalyzeAudio(
          bytes: [1],
          filename: 'a',
          title: '',
          artist: '',
          album: 'Kept',
        );

        final form = adapter.lastRequest.data as FormData;
        expect(Map.fromEntries(form.fields), {'album': 'Kept'});
      });

      test('returns an empty map when the body is empty', () async {
        adapter.body = null;

        expect(
          await build().uploadAndAnalyzeAudio(bytes: [1], filename: 'a'),
          isEmpty,
        );
      });

      test('non-2xx responses surface as DioException', () async {
        adapter
          ..statusCode = 413
          ..body = <String, dynamic>{'detail': 'File too large'};

        await expectLater(
          build().uploadAndAnalyzeAudio(bytes: [1], filename: 'a'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              413,
            ),
          ),
        );
      });
    });
  });

  group('AudioUploadRemoteDataSource with default Dio', () {
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
          await request.drain<void>();
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(audioUploadJson()));
          await request.response.close();
        });
    });

    tearDown(() async {
      HttpOverrides.global = previousOverrides;
      await server.close(force: true);
    });

    test('builds a working client against the provided baseUrl', () async {
      final ds = AudioUploadRemoteDataSource(
        baseUrl: 'http://127.0.0.1:${server.port}/api/v1',
        tokenProvider: () async => 'real-token',
      );

      final result = await ds.uploadAndAnalyzeAudio(
        bytes: [1, 2, 3],
        filename: 'x.mp3',
      );

      expect(result['id'], 'up-1');
      expect(seenUris.single.path, '/api/v1/audio-upload/analyze');
      expect(seenHeaders.single.value('authorization'), 'Bearer real-token');
      expect(seenHeaders.single.contentType?.mimeType, 'multipart/form-data');
    });
  });
}
