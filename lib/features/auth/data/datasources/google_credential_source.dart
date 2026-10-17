import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/auth/data/datasources/social_credential_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Google Sign-In through the native sheet (Credential Manager on Android).
///
/// Configured by two dart-defines: `GOOGLE_WEB_CLIENT_ID`, the client the ID
/// token is issued to and Supabase verifies, and `GOOGLE_IOS_CLIENT_ID`,
/// whose reversed form the iOS build registers as a URL scheme. Unavailable
/// until they're set, so builds without them simply hide the button.
class GoogleCredentialSource implements SocialCredentialSource {
  GoogleCredentialSource({
    GoogleSignIn? googleSignIn,
    this.iosClientId = const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    this.webClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    TargetPlatform? platform,
  }) : _googleSignIn = googleSignIn,
       _platform = platform;

  final String iosClientId;
  final String webClientId;
  final GoogleSignIn? _googleSignIn;
  final TargetPlatform? _platform;

  /// `GoogleSignIn.initialize` may only run once per app.
  Future<void>? _initialized;

  static const _scopes = ['email', 'profile'];

  TargetPlatform get _target => _platform ?? defaultTargetPlatform;

  @override
  bool get isAvailable => switch (_target) {
    TargetPlatform.iOS => iosClientId.isNotEmpty && webClientId.isNotEmpty,
    TargetPlatform.android => webClientId.isNotEmpty,
    _ => false,
  };

  Future<void> _initializeOnce(GoogleSignIn signIn) async {
    final pending = _initialized ??= signIn.initialize(
      clientId: _target == TargetPlatform.iOS ? iosClientId : null,
      serverClientId: webClientId,
    );
    try {
      await pending;
    } on Object {
      _initialized = null; // let the next attempt retry
      rethrow;
    }
  }

  @override
  Future<SocialCredential?> obtain() async {
    final signIn = _googleSignIn ?? GoogleSignIn.instance;
    try {
      await _initializeOnce(signIn);
      final account = await signIn.authenticate(scopeHint: _scopes);
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google did not return an ID token.');
      }
      final authorization = await account.authorizationClient
          .authorizationForScopes(_scopes);
      return SocialCredential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      talker.warning('Google sign-in failed: ${e.code} ${e.description}');
      throw const AuthException('Google sign-in failed. Please try again.');
    }
  }
}
