import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:moodtune_app/features/auth/data/datasources/account_remote_datasource.dart';

import '../../../mood_feedback/mood_feedback_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;

  // Keep test output readable: the datasource wires TalkerDioLogger.
  setUpAll(talker.disable);
  tearDownAll(talker.enable);

  setUp(() => adapter = FakeHttpClientAdapter(statusCode: 204));

  AccountRemoteDataSource build({String? token}) => AccountRemoteDataSource(
    dio: fakeDio(adapter),
    tokenProvider: () async => token,
  );

  test('wires the standard interceptors', () {
    final dio = fakeDio(adapter);
    AccountRemoteDataSource(dio: dio);

    expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
  });

  test('defaultBaseUrl points at the local backend', () {
    expect(
      AccountRemoteDataSource.defaultBaseUrl,
      'http://127.0.0.1:8000/api/v1',
    );
  });

  test('builds its own client from baseUrl', () {
    expect(
      () => AccountRemoteDataSource(baseUrl: 'https://api.test/v1'),
      returnsNormally,
    );
  });

  test('deleteAccount sends DELETE /account with the Bearer token', () async {
    await build(token: 'tok').deleteAccount();

    expect(adapter.requests, hasLength(1));
    final req = adapter.lastRequest;
    expect(req.method, 'DELETE');
    expect(req.path, '/account');
    expect(req.headers['Authorization'], 'Bearer tok');
  });

  test('omits Authorization when there is no session', () async {
    await build().deleteAccount();
    expect(adapter.lastRequest.headers.containsKey('Authorization'), false);

    await AccountRemoteDataSource(dio: fakeDio(adapter)).deleteAccount();
    expect(adapter.lastRequest.headers.containsKey('Authorization'), false);
  });

  test('throws a bad-response DioException on 500', () async {
    adapter
      ..statusCode = 500
      ..body = {'detail': 'Account deletion failed'};

    await expectLater(
      build(token: 'tok').deleteAccount(),
      throwsA(
        isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.badResponse)
            .having((e) => e.response?.statusCode, 'status', 500),
      ),
    );
  });

  test('throws a connection DioException when the network fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = _FailingAdapter();

    await expectLater(
      AccountRemoteDataSource(dio: dio).deleteAccount(),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
  });
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => Future.error(
    DioException.connectionError(requestOptions: options, reason: 'offline'),
  );

  @override
  void close({bool force = false}) {}
}
