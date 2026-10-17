import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/features/auth/data/datasources/google_credential_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockAccount extends Mock implements GoogleSignInAccount {}

class _MockAuthorizationClient extends Mock
    implements GoogleSignInAuthorizationClient {}

const _ios = '1234-ios.apps.googleusercontent.com';
const _web = '5678-web.apps.googleusercontent.com';

void main() {
  late _MockGoogleSignIn signIn;
  late _MockAccount account;
  late _MockAuthorizationClient authorizationClient;

  setUp(() {
    signIn = _MockGoogleSignIn();
    account = _MockAccount();
    authorizationClient = _MockAuthorizationClient();
    when(
      () => signIn.initialize(
        clientId: any(named: 'clientId'),
        serverClientId: any(named: 'serverClientId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => signIn.authenticate(scopeHint: any(named: 'scopeHint')),
    ).thenAnswer((_) async => account);
    when(
      () => account.authentication,
    ).thenReturn(const GoogleSignInAuthentication(idToken: 'google-jwt'));
    when(() => account.authorizationClient).thenReturn(authorizationClient);
    when(() => authorizationClient.authorizationForScopes(any())).thenAnswer(
      (_) async => const GoogleSignInClientAuthorization(accessToken: 'at'),
    );
  });

  GoogleCredentialSource build({
    TargetPlatform platform = TargetPlatform.iOS,
    String ios = _ios,
    String web = _web,
  }) => GoogleCredentialSource(
    googleSignIn: signIn,
    iosClientId: ios,
    webClientId: web,
    platform: platform,
  );

  group('isAvailable', () {
    test('iOS needs both client IDs', () {
      expect(build().isAvailable, isTrue);
      expect(build(ios: '').isAvailable, isFalse);
      expect(build(web: '').isAvailable, isFalse);
    });

    test('Android needs the web client ID', () {
      expect(
        build(platform: TargetPlatform.android, ios: '').isAvailable,
        isTrue,
      );
      expect(
        build(platform: TargetPlatform.android, web: '').isAvailable,
        isFalse,
      );
    });

    test('is unavailable elsewhere', () {
      expect(build(platform: TargetPlatform.macOS).isAvailable, isFalse);
    });

    test('is unavailable when the dart-defines are unset', () {
      expect(
        GoogleCredentialSource(platform: TargetPlatform.iOS).isAvailable,
        isFalse,
      );
    });
  });

  test('returns the ID and access tokens', () async {
    final credential = await build().obtain();

    expect(credential?.idToken, 'google-jwt');
    expect(credential?.accessToken, 'at');
    expect(credential?.rawNonce, isNull);
    verify(
      () => signIn.initialize(clientId: _ios, serverClientId: _web),
    ).called(1);
  });

  test('passes no iOS client ID on Android', () async {
    await build(platform: TargetPlatform.android).obtain();

    verify(
      () => signIn.initialize(clientId: null, serverClientId: _web),
    ).called(1);
  });

  test('initializes Google Sign-In only once', () async {
    final source = build();

    await source.obtain();
    await source.obtain();

    verify(
      () => signIn.initialize(
        clientId: any(named: 'clientId'),
        serverClientId: any(named: 'serverClientId'),
      ),
    ).called(1);
  });

  test('retries initialization after it fails', () async {
    var calls = 0;
    when(
      () => signIn.initialize(
        clientId: any(named: 'clientId'),
        serverClientId: any(named: 'serverClientId'),
      ),
    ).thenAnswer((_) async {
      if (calls++ == 0) {
        throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        );
      }
    });
    final source = build();

    await expectLater(source.obtain(), throwsA(isA<AuthException>()));
    expect((await source.obtain())?.idToken, 'google-jwt');
    expect(calls, 2);
  });

  test('returns null when the user cancels', () async {
    when(
      () => signIn.authenticate(scopeHint: any(named: 'scopeHint')),
    ).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );

    expect(await build().obtain(), isNull);
  });

  test('turns other Google errors into a friendly AuthException', () async {
    when(
      () => signIn.authenticate(scopeHint: any(named: 'scopeHint')),
    ).thenThrow(
      const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'boom',
      ),
    );

    await expectLater(
      build().obtain(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Google sign-in failed. Please try again.',
        ),
      ),
    );
  });

  test('throws when Google returns no ID token', () async {
    when(
      () => account.authentication,
    ).thenReturn(const GoogleSignInAuthentication(idToken: null));

    await expectLater(build().obtain(), throwsA(isA<AuthException>()));
  });

  test('sends no access token when the scopes need consent', () async {
    when(
      () => authorizationClient.authorizationForScopes(any()),
    ).thenAnswer((_) async => null);

    expect((await build().obtain())?.accessToken, isNull);
  });
}
