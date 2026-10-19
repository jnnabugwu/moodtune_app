part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Progress of [AuthDeleteAccountRequested]. The user stays signed in until
/// it reaches [succeeded].
enum DeleteAccountStatus {
  idle,
  inProgress,
  succeeded,
  failed,

  /// The session expired; the user has to sign in again to delete.
  sessionExpired,
}

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
    this.deleteAccountStatus = DeleteAccountStatus.idle,
    this.deleteAccountError,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final bool justSignedUp;

  /// Set after sign-up so the Email Verify screen knows which address to show.
  final String? pendingVerificationEmail;

  /// True after a password-reset email has been dispatched successfully;
  /// reset to false when the next request starts.
  final bool passwordResetSent;

  /// True after a reset link opened the app; cleared once the new password
  /// is saved.
  final bool passwordRecovery;

  /// Social sign-in buttons to offer (fixed for the app's lifetime).
  final Set<SocialProvider> socialProviders;

  final DeleteAccountStatus deleteAccountStatus;

  /// Why the last account deletion failed; null unless
  /// [deleteAccountStatus] is [DeleteAccountStatus.failed].
  final String? deleteAccountError;

  AuthState copyWith({
    AuthStatus? status,
    Object? user = _keep,
    String? error,
    bool? justSignedUp,
    Object? pendingVerificationEmail = _keep,
    bool? passwordResetSent,
    bool? passwordRecovery,
    DeleteAccountStatus? deleteAccountStatus,
    Object? deleteAccountError = _keep,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user == _keep ? this.user : user as AppUser?,
      error: error,
      justSignedUp: justSignedUp ?? this.justSignedUp,
      pendingVerificationEmail: pendingVerificationEmail == _keep
          ? this.pendingVerificationEmail
          : pendingVerificationEmail as String?,
      passwordResetSent: passwordResetSent ?? this.passwordResetSent,
      passwordRecovery: passwordRecovery ?? this.passwordRecovery,
      socialProviders: socialProviders,
      deleteAccountStatus: deleteAccountStatus ?? this.deleteAccountStatus,
      deleteAccountError: deleteAccountError == _keep
          ? this.deleteAccountError
          : deleteAccountError as String?,
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
    deleteAccountStatus,
    deleteAccountError,
  ];
}

const Object _keep = Object();
