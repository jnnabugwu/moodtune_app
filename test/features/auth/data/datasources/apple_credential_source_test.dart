import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/auth/data/datasources/apple_credential_source.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AuthorizationCredentialAppleID _credential({
  String? identityToken = 'apple-jwt',
}) => AuthorizationCredentialAppleID(
  userIdentifier: 'apple-user',
  givenName: null,
  familyName: null,
  authorizationCode: 'code',
  email: null,
  identityToken: identityToken,
  state: null,
);

void main() {
  List<AppleIDAuthorizationScopes>? requestedScopes;
  String? requestedNonce;

  AppleCredentialSource build({
    Future<AuthorizationCredentialAppleID> Function()? respond,
    TargetPlatform platform = TargetPlatform.iOS,
  }) => AppleCredentialSource(
    platform: platform,
    rawNonce: () => 'raw-nonce',
    request: ({required scopes, nonce}) {
      requestedScopes = scopes;
      requestedNonce = nonce;
      return respond?.call() ?? Future.value(_credential());
    },
  );

  setUp(() {
    requestedScopes = null;
    requestedNonce = null;
  });

  test('is available on iOS only', () {
    expect(build().isAvailable, isTrue);
    expect(build(platform: TargetPlatform.android).isAvailable, isFalse);
    expect(build(platform: TargetPlatform.macOS).isAvailable, isFalse);
  });

  test('asks Apple for the hashed nonce and returns the raw one', () async {
    final credential = await build().obtain();

    expect(credential?.idToken, 'apple-jwt');
    expect(credential?.rawNonce, 'raw-nonce');
    expect(credential?.accessToken, isNull);
    expect(requestedNonce, sha256.convert(utf8.encode('raw-nonce')).toString());
    expect(requestedScopes, [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ]);
  });

  test('returns null when the user cancels', () async {
    final source = build(
      respond: () => throw const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'canceled',
      ),
    );

    expect(await source.obtain(), isNull);
  });

  test('turns other Apple errors into a friendly AuthException', () async {
    final source = build(
      respond: () => throw const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.failed,
        message: 'ASAuthorizationError 1000',
      ),
    );

    await expectLater(
      source.obtain(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Sign in with Apple failed. Please try again.',
        ),
      ),
    );
  });

  test('throws when Apple returns no identity token', () async {
    final source = build(respond: () async => _credential(identityToken: null));

    await expectLater(source.obtain(), throwsA(isA<AuthException>()));
  });

  test('generates a different nonce for each attempt by default', () async {
    final nonces = <String?>[];
    final source = AppleCredentialSource(
      platform: TargetPlatform.iOS,
      request: ({required scopes, nonce}) async {
        nonces.add(nonce);
        return _credential();
      },
    );

    final first = await source.obtain();
    final second = await source.obtain();

    expect(first?.rawNonce, isNot(second?.rawNonce));
    expect(first!.rawNonce!.length, greaterThanOrEqualTo(32));
    expect(nonces.toSet(), hasLength(2));
  });
}
