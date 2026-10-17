/// What a provider's native sign-in sheet hands back, ready for Supabase's
/// `signInWithIdToken`.
class SocialCredential {
  const SocialCredential({
    required this.idToken,
    this.accessToken,
    this.rawNonce,
  });

  final String idToken;
  final String? accessToken;

  /// The unhashed nonce whose SHA-256 the provider embedded in [idToken];
  /// Supabase hashes it again to check the token was issued for this sign-in.
  final String? rawNonce;
}

/// Shows one provider's native sign-in sheet.
abstract interface class SocialCredentialSource {
  /// Whether this platform and build can use the provider at all.
  bool get isAvailable;

  /// Null when the user dismisses the sheet. Other failures throw an
  /// `AuthException` with a message fit to show.
  Future<SocialCredential?> obtain();
}
