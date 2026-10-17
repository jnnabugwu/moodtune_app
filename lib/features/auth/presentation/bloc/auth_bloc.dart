import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/entities/auth_change.dart';
import 'package:moodtune_app/features/auth/domain/entities/social_provider.dart';
import 'package:moodtune_app/features/auth/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// [socialProviders] are the sign-in buttons to offer; see
  /// [AuthRepository.availableSocialProviders].
  AuthBloc(this._repository, {Set<SocialProvider> socialProviders = const {}})
    : super(AuthState(socialProviders: socialProviders)) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSocialSignInRequested>(_onSocialSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<ResendVerificationRequested>(_onResendVerification);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<PasswordUpdateRequested>(_onPasswordUpdate);
    on<AuthChanged>(_onAuthChanged);
    _authChanges = _repository.authChanges().listen(
      (change) => add(AuthChanged(change)),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthChange> _authChanges;

  @override
  Future<void> close() async {
    await _authChanges.cancel();
    return await super.close();
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        error: null,
        justSignedUp: false,
      ),
    );
    final result = await _repository.getCurrentUser();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          error: failure.message,
          justSignedUp: false,
        ),
      ),
      (user) => emit(
        state.copyWith(
          status: user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: user,
          error: null,
          justSignedUp: false,
        ),
      ),
    );
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        error: null,
        justSignedUp: false,
      ),
    );
    final result = await _repository.signIn(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          error: failure.message,
          user: null,
          justSignedUp: false,
        ),
      ),
      (user) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          error: null,
          justSignedUp: false,
        ),
      ),
    );
  }

  Future<void> _onSocialSignInRequested(
    AuthSocialSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        error: null,
        justSignedUp: false,
      ),
    );
    final result = await _repository.signInWithProvider(event.provider);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          error: failure.message,
          justSignedUp: false,
        ),
      ),
      (user) => emit(
        // A dismissed sheet is not an error: back to where the user was.
        user == null
            ? state.copyWith(status: AuthStatus.unauthenticated)
            : state.copyWith(
                status: AuthStatus.authenticated,
                user: user,
                justSignedUp: false,
              ),
      ),
    );
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        error: null,
        justSignedUp: false,
      ),
    );
    final result = await _repository.signUp(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          error: failure.message,
          user: null,
          justSignedUp: false,
        ),
      ),
      (user) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          error: null,
          justSignedUp: true,
          // Keep the email so Email Verify screen can display it
          pendingVerificationEmail: event.email,
        ),
      ),
    );
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        error: null,
        justSignedUp: false,
      ),
    );
    final result = await _repository.signOut();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          error: failure.message,
          justSignedUp: false,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          error: null,
          justSignedUp: false,
        ),
      ),
    );
  }

  Future<void> _onResendVerification(
    ResendVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));
    final result = await _repository.resendVerificationEmail(event.email);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          pendingVerificationEmail: event.email,
        ),
      ),
    );
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));
    final result = await _repository.sendPasswordResetEmail(event.email);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          passwordResetSent: true,
        ),
      ),
    );
  }

  Future<void> _onPasswordUpdate(
    PasswordUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));
    final result = await _repository.updatePassword(event.password);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          error: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          passwordRecovery: false,
        ),
      ),
    );
  }

  /// An email link opened the app and Supabase created a session.
  void _onAuthChanged(AuthChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: event.change.user,
        justSignedUp: false,
        passwordRecovery: event.change.type == AuthChangeType.passwordRecovery,
      ),
    );
  }
}
