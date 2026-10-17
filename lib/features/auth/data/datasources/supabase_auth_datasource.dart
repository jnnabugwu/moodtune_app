import 'package:moodtune_app/features/auth/data/datasources/apple_credential_source.dart';
import 'package:moodtune_app/features/auth/data/datasources/google_credential_source.dart';
import 'package:moodtune_app/features/auth/data/datasources/social_credential_source.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/entities/auth_change.dart';
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

  /// Where Supabase email links (confirm sign-up, reset password) send the
  /// user. Must be listed under Authentication → URL Configuration →
  /// Redirect URLs in the Supabase dashboard. GoRouter sees the path as
  /// `RouteNames.loginCallback`; supabase_flutter exchanges the `code`.
  static const authRedirectUrl = 'moodtune://auth/login-callback';
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
      emailRedirectTo: authRedirectUrl,
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
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: authRedirectUrl,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: authRedirectUrl,
    );
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Stream<AuthChange> authChanges() {
    return _client.auth.onAuthStateChange
        .map((state) {
          final user = state.session?.user;
          if (user == null) return null;
          final type = switch (state.event) {
            AuthChangeEvent.signedIn => AuthChangeType.signedIn,
            AuthChangeEvent.passwordRecovery => AuthChangeType.passwordRecovery,
            _ => null,
          };
          if (type == null) return null;
          return AuthChange(
            type: type,
            user: AppUser(id: user.id, email: user.email ?? ''),
          );
        })
        .where((change) => change != null)
        .cast<AuthChange>()
        // Expired or invalid links surface as stream errors; the callback
        // page shows its own timeout, so drop them here.
        .handleError((Object _) {});
  }
}
