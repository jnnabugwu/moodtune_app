import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/auth/data/datasources/social_credential_source.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef AppleCredentialRequest =
    Future<AuthorizationCredentialAppleID> Function({
      required List<AppleIDAuthorizationScopes> scopes,
      String? nonce,
    });

/// Sign in with Apple through the native iOS sheet. Needs the
/// `com.apple.developer.applesignin` entitlement (ios/Runner/Runner.entitlements)
/// and the capability on each App ID.
class AppleCredentialSource implements SocialCredentialSource {
  AppleCredentialSource({
    AppleCredentialRequest? request,
    String Function()? rawNonce,
    TargetPlatform? platform,
  }) : _request = request ?? SignInWithApple.getAppleIDCredential,
       _rawNonce = rawNonce ?? _randomNonce,
       _platform = platform;

  final AppleCredentialRequest _request;
  final String Function() _rawNonce;
  final TargetPlatform? _platform;

  @override
  bool get isAvailable =>
      (_platform ?? defaultTargetPlatform) == TargetPlatform.iOS;

  @override
  Future<SocialCredential?> obtain() async {
    final rawNonce = _rawNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await _request(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      talker.warning('Sign in with Apple failed: ${e.code} ${e.message}');
      throw const AuthException('Sign in with Apple failed. Please try again.');
    }

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple did not return an identity token.');
    }
    return SocialCredential(idToken: idToken, rawNonce: rawNonce);
  }

  static String _randomNonce() {
    final random = Random.secure();
    return base64Url.encode(List.generate(32, (_) => random.nextInt(256)));
  }
}
