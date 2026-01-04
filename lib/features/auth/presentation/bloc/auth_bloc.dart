import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
  }

  final AuthRepository _repository;

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
}
