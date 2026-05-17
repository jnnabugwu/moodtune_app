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
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final bool justSignedUp;

  /// Set after sign-up so the Email Verify screen knows which address to show.
  final String? pendingVerificationEmail;

  /// True after a password-reset email has been dispatched successfully.
  final bool passwordResetSent;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    bool? justSignedUp,
    Object? pendingVerificationEmail = _keep,
    bool? passwordResetSent,
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
      ];
}

const Object _keep = Object();
