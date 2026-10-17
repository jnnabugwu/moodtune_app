part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.justSignedUp = false,
    this.pendingVerificationEmail,
    this.passwordResetSent = false,
    this.passwordRecovery = false,
    this.socialProviders = const {},
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final bool justSignedUp;

  /// Set after sign-up so the Email Verify screen knows which address to show.
  final String? pendingVerificationEmail;

  /// True after a password-reset email has been dispatched successfully.
  final bool passwordResetSent;

  /// True after a reset link opened the app; cleared once the new password
  /// is saved.
  final bool passwordRecovery;

  /// Social sign-in buttons to offer (fixed for the app's lifetime).
  final Set<SocialProvider> socialProviders;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    bool? justSignedUp,
    Object? pendingVerificationEmail = _keep,
    bool? passwordResetSent,
    bool? passwordRecovery,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      justSignedUp: justSignedUp ?? this.justSignedUp,
      pendingVerificationEmail: pendingVerificationEmail == _keep
          ? this.pendingVerificationEmail
          : pendingVerificationEmail as String?,
      passwordResetSent: passwordResetSent ?? this.passwordResetSent,
      passwordRecovery: passwordRecovery ?? this.passwordRecovery,
      socialProviders: socialProviders,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    error,
    justSignedUp,
    pendingVerificationEmail,
    passwordResetSent,
    passwordRecovery,
    socialProviders,
  ];
}

const Object _keep = Object();
