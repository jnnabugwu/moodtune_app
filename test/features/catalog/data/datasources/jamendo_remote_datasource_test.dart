import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/exceptions.dart';
import 'package:moodtune_app/features/catalog/data/datasources/jamendo_remote_datasource.dart';

import '../../catalog_fixtures.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late JamendoRemoteDataSource dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = JamendoRemoteDataSource(clientId: 'cid', dio: dio);
  });

  Response<Map<String, dynamic>> ok(Map<String, dynamic>? data) => Response(
    requestOptions: RequestOptions(path: '/tracks/'),
    data: data,
    statusCode: 200,
  );

  /// Stubs GET /tracks/ so the response depends on the query params.
  void stubGet(
    Map<String, dynamic>? Function(Map<String, dynamic> params) respond,
  ) {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/tracks/',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((invocation) async {
      final params =
          invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
      return ok(respond(params));
    });
  }

  List<Map<String, dynamic>> capturedParams() => verify(
    () => dio.get<Map<String, dynamic>>(
      '/tracks/',
      queryParameters: captureAny(named: 'queryParameters'),
    ),
  ).captured.cast<Map<String, dynamic>>();

  test('creates a default Dio when none is injected', () {
    expect(
      JamendoRemoteDataSource(clientId: 'x').clientId,
      'x',
    );
  });

  group('mood tag only', () {
    test('fires a single request with base params and the mood tag', () async {
      stubGet(
        (_) => {
          'results': [buildJamendoJson()],
        },
      );

      final result = await dataSource.searchTracks(moodTag: 'serene');

      expect(result.map((m) => m.id), ['1']);
      final params = capturedParams().single;
      expect(params, {
        'client_id': 'cid',
        'format': 'json',
        'limit': 20,
        'include': 'musicinfo',
        'imagesize': 50,
        'tags': 'serene',
      });
    });

    test('empty query is treated like no query', () async {
      stubGet((_) => {'results': <dynamic>[]});

      await dataSource.searchTracks(query: '', moodTag: '');

      final params = capturedParams().single;
      expect(params.containsKey('search'), isFalse);
      expect(params.containsKey('tags'), isFalse);
    });

    test('missing results key yields an empty list', () async {
      stubGet((_) => <String, dynamic>{});
      expect(await dataSource.searchTracks(), isEmpty);
    });
  });

  group('text query', () {
    test('fires search + tags requests and merges deduplicated', () async {
      stubGet((params) {
        if (params.containsKey('search')) {
          return {
            'results': [
              buildJamendoJson(name: 'A'),
              buildJamendoJson(id: 2, name: 'B'),
            ],
          };
        }
        return {
          'results': [
            buildJamendoJson(id: 2, name: 'B-dup'),
            buildJamendoJson(id: 3, name: 'C'),
          ],
        };
      });

      final result = await dataSource.searchTracks(query: 'jazz');

      expect(result.map((m) => m.id), ['1', '2', '3']);
      // Text-search results win on duplicates.
      expect(result[1].name, 'B');

      final params = capturedParams();
      expect(params, hasLength(2));
      final search = params.firstWhere((p) => p.containsKey('search'));
      final tags = params.firstWhere((p) => !p.containsKey('search'));
      expect(search['search'], 'jazz');
      expect(search.containsKey('tags'), isFalse);
      expect(tags['tags'], 'jazz');
    });

    test('appends mood tag to both requests', () async {
      stubGet((_) => {'results': <dynamic>[]});

      await dataSource.searchTracks(query: 'rock', moodTag: 'charged');

      final params = capturedParams();
      final search = params.firstWhere((p) => p.containsKey('search'));
      final tags = params.firstWhere((p) => !p.containsKey('search'));
      expect(search['tags'], 'charged');
      expect(tags['tags'], 'rock charged');
    });
  });

  group('errors', () {
    test('null body throws ServerException("Empty response")', () async {
      stubGet((_) => null);

      await expectLater(
        dataSource.searchTracks(moodTag: 'x'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Empty response',
          ),
        ),
      );
    });

    DioException dioError({Object? body, String? message}) => DioException(
      requestOptions: RequestOptions(path: '/tracks/'),
      message: message,
      response: body == null
          ? null
          : Response<dynamic>(
              requestOptions: RequestOptions(path: '/tracks/'),
              data: body,
              statusCode: 500,
            ),
    );

    void stubThrow(DioException e) {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/tracks/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(e);
    }

    test('DioException with body maps to ServerException(body)', () async {
      stubThrow(dioError(body: {'error': 'bad client'}));

      await expectLater(
        dataSource.searchTracks(query: 'q'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            '{error: bad client}',
          ),
        ),
      );
    });

    test('DioException on mood-only search maps to ServerException', () async {
      stubThrow(dioError(message: 'timeout'));

      await expectLater(
        dataSource.searchTracks(moodTag: 'serene'),
        throwsA(
          isA<ServerException>().having((e) => e.message, 'message', 'timeout'),
        ),
      );
    });

    test('DioException without body uses its message', () async {
      stubThrow(dioError(message: 'timeout'));

      await expectLater(
        dataSource.searchTracks(query: 'q'),
        throwsA(
          isA<ServerException>().having((e) => e.message, 'message', 'timeout'),
        ),
      );
    });

    test('DioException without body or message uses fallback', () async {
      stubThrow(dioError());

      await expectLater(
        dataSource.searchTracks(query: 'q'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Jamendo API error',
          ),
        ),
      );
    });
  });
}
