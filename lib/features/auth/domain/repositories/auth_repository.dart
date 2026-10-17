import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/entities/auth_change.dart';
import 'package:moodtune_app/features/auth/domain/entities/social_provider.dart';
import 'package:moodtune_app/utils/typedef.dart';

abstract class AuthRepository {
  ResultFuture<AppUser?> getCurrentUser();
  ResultFuture<AppUser> signIn({
    required String email,
    required String password,
  });
  ResultFuture<AppUser> signUp({
    required String email,
    required String password,
  });
  ResultFuture<void> signOut();

  /// Providers this build and platform can sign in with.
  Set<SocialProvider> get availableSocialProviders;

  /// Signs in through [provider]'s native sheet; `Right(null)` when the user
  /// cancels it.
  ResultFuture<AppUser?> signInWithProvider(SocialProvider provider);

  /// Re-sends the email confirmation link for [email].
  ResultFuture<void> resendVerificationEmail(String email);

  /// Sends a password-reset link to [email].
  ResultFuture<void> sendPasswordResetEmail(String email);

  /// Sets a new password for the signed-in user (after a reset link).
  ResultFuture<void> updatePassword(String password);

  /// Emits when an email link signs the user in or starts password recovery.
  Stream<AuthChange> authChanges();
}
