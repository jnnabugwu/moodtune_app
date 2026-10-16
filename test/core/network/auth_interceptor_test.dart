import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/network/auth_interceptor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

class _MemoryLocalStorage extends LocalStorage {
  String? session;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => session != null;

  @override
  Future<String?> accessToken() async => session;

  @override
  Future<void> removePersistedSession() async => session = null;

  @override
  Future<void> persistSession(String persistSessionString) async =>
      session = persistSessionString;
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _items = {};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _items[key] = value;

  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);
}

Map<String, dynamic> _sessionJson(String accessToken) => {
  // Not a JWT, so gotrue treats it as never expiring.
  'access_token': accessToken,
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'refresh-$accessToken',
  'user': {
    'id': 'user-1',
    'aud': 'authenticated',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2025-01-01T00:00:00Z',
  },
};

/// In-process fake that plays both the Supabase auth server (token refresh)
/// and the app backend (the retried request). Bound to loopback only.
class _FakeBackend {
  late HttpServer _server;

  /// Status code returned by `POST /auth/v1/token`.
  int refreshStatus = 200;

  /// Status code returned for the retried API request.
  int retryStatus = 200;

  int refreshCalls = 0;
  final List<String?> retryAuthHeaders = [];

  String get url => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    await request.drain<void>();
    final res = request.response..headers.contentType = ContentType.json;
    if (request.uri.path == '/auth/v1/token') {
      refreshCalls++;
      res
        ..statusCode = refreshStatus
        ..write(
          jsonEncode(
            refreshStatus == 200
                ? _sessionJson('new-token')
                : {
                    'error': 'invalid_grant',
                    'error_description': 'Invalid Refresh Token',
                    'code': 'refresh_token_not_found',
                  },
          ),
        );
    } else {
      retryAuthHeaders.add(request.headers.value('authorization'));
      res
        ..statusCode = retryStatus
        ..write(jsonEncode({'retried': true, 'path': request.uri.path}));
    }
    await res.close();
  }
}

DioException _error({
  int? statusCode,
  String baseUrl = 'http://unused',
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final options = RequestOptions(
    path: '/protected',
    baseUrl: baseUrl,
    method: 'GET',
    headers: {'Authorization': 'Bearer old-token'},
  );
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  final backend = _FakeBackend();
  final storage = _MemoryLocalStorage();
  late AuthInterceptor interceptor;
  late _MockErrorHandler handler;
  HttpOverrides? previousOverrides;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The test binding stubs dart:io HttpClient; we need real loopback I/O.
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    registerFallbackValue(Response<dynamic>(requestOptions: RequestOptions()));
    registerFallbackValue(DioException(requestOptions: RequestOptions()));

    await backend.start();
    await Supabase.initialize(
      url: backend.url,
      anonKey: 'anon-key',
      debug: false,
      authOptions: FlutterAuthClientOptions(
        localStorage: storage,
        pkceAsyncStorage: _MemoryAsyncStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
  });

  // `very_good test --optimization` runs every file in one isolate, so put
  // global state back for the tests that run after this file.
  tearDownAll(() async {
    await Supabase.instance.dispose();
    HttpOverrides.global = previousOverrides;
    await backend.stop();
  });

  setUp(() async {
    backend
      ..refreshStatus = 200
      ..retryStatus = 200
      ..refreshCalls = 0
      ..retryAuthHeaders.clear();
    // Start every test with a known, valid session.
    await Supabase.instance.client.auth.recoverSession(
      jsonEncode(_sessionJson('old-token')),
    );
    interceptor = AuthInterceptor();
    handler = _MockErrorHandler();
  });

  group('AuthInterceptor', () {
    test('passes non-401 errors through without refreshing', () async {
      final err = _error(statusCode: 500);

      await interceptor.onError(err, handler);

      verify(() => handler.next(err)).called(1);
      verifyNever(() => handler.resolve(any()));
      expect(backend.refreshCalls, 0);
    });

    test('passes errors without a response through', () async {
      final err = _error(type: DioExceptionType.connectionError);

      await interceptor.onError(err, handler);

      verify(() => handler.next(err)).called(1);
      expect(backend.refreshCalls, 0);
    });

    test('on 401 refreshes the session and resolves with the retried '
        'response', () async {
      final err = _error(statusCode: 401, baseUrl: backend.url);

      await interceptor.onError(err, handler);

      expect(backend.refreshCalls, 1);
      expect(backend.retryAuthHeaders, ['Bearer new-token']);
      expect(err.requestOptions.headers['Authorization'], 'Bearer new-token');
      final resolved =
          verify(() => handler.resolve(captureAny())).captured.single
              as Response<dynamic>;
      expect(resolved.statusCode, 200);
      expect(resolved.data, {'retried': true, 'path': '/protected'});
      verifyNever(() => handler.next(any()));
      expect(
        Supabase.instance.client.auth.currentSession?.accessToken,
        'new-token',
      );
    });

    test('on 401 forwards the original error when refresh fails', () async {
      backend.refreshStatus = 400;
      final err = _error(statusCode: 401, baseUrl: backend.url);

      await interceptor.onError(err, handler);

      expect(backend.refreshCalls, 1);
      expect(backend.retryAuthHeaders, isEmpty);
      verify(() => handler.next(err)).called(1);
      verifyNever(() => handler.resolve(any()));
    });

    test('on 401 forwards the original error when the retry fails', () async {
      backend.retryStatus = 500;
      final err = _error(statusCode: 401, baseUrl: backend.url);

      await interceptor.onError(err, handler);

      expect(backend.retryAuthHeaders, ['Bearer new-token']);
      verify(() => handler.next(err)).called(1);
      verifyNever(() => handler.resolve(any()));
    });

    test('on 401 with no session forwards the original error', () async {
      await Supabase.instance.client.auth.signOut();
      final err = _error(statusCode: 401, baseUrl: backend.url);

      await interceptor.onError(err, handler);

      expect(backend.refreshCalls, 0);
      verify(() => handler.next(err)).called(1);
    });
  });
}
