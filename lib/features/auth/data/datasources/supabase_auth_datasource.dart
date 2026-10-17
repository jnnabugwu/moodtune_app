import 'package:moodtune_app/features/auth/data/datasources/apple_credential_source.dart';
import 'package:moodtune_app/features/auth/data/datasources/google_credential_source.dart';
import 'package:moodtune_app/features/auth/data/datasources/social_credential_source.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/entities/social_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthDatasource {
  SupabaseAuthDatasource({
    SupabaseClient? client,
    SocialCredentialSource? apple,
    SocialCredentialSource? google,
  }) : _client = client ?? Supabase.instance.client,
       _social = {
         SocialProvider.apple: apple ?? AppleCredentialSource(),
         SocialProvider.google: google ?? GoogleCredentialSource(),
       };

  final SupabaseClient _client;
  final Map<SocialProvider, SocialCredentialSource> _social;

  Set<SocialProvider> get availableSocialProviders => {
    for (final MapEntry(:key, :value) in _social.entries)
      if (value.isAvailable) key,
  };

  /// Signs in through [provider]'s native sheet. Null when the user cancels.
  Future<AppUser?> signInWithProvider(SocialProvider provider) async {
    final credential = await _social[provider]!.obtain();
    if (credential == null) return null;
    final response = await _client.auth.signInWithIdToken(
      provider: switch (provider) {
        SocialProvider.apple => OAuthProvider.apple,
        SocialProvider.google => OAuthProvider.google,
      },
      idToken: credential.idToken,
      accessToken: credential.accessToken,
      nonce: credential.rawNonce,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('No user returned from Supabase');
    }
    return AppUser(id: user.id, email: user.email ?? '');
  }

  Future<AppUser?> currentUser() async {
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('No user returned from Supabase');
    }
    return AppUser(id: user.id, email: user.email ?? email);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('No user returned from Supabase');
    }
    return AppUser(id: user.id, email: user.email ?? email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resendVerificationEmail(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
