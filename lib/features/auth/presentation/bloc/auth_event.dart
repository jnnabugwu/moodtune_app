part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested(this.email, this.password);

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested(this.email, this.password);

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class ResendVerificationRequested extends AuthEvent {
  const ResendVerificationRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class ForgotPasswordRequested extends AuthEvent {
  const ForgotPasswordRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
