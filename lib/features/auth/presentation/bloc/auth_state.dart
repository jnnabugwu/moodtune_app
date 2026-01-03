part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.justSignedUp = false,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final bool justSignedUp;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    bool? justSignedUp,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      justSignedUp: justSignedUp ?? this.justSignedUp,
    );
  }

  @override
  List<Object?> get props => [status, user, error, justSignedUp];
}
