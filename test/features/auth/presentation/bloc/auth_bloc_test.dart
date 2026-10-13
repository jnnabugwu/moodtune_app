import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../helpers/helpers.dart';
import '../../../blocs_fixtures.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  AuthBloc buildBloc() => AuthBloc(repository);

  const email = 'sam@example.com';
  const password = 'secret123';

  test('initial state is AuthState()', () {
    expect(buildBloc().state, const AuthState());
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when a user exists',
      setUp: () => when(
        () => repository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(tAppUser)),
      build: buildBloc,
      seed: () => const AuthState(justSignedUp: true, error: 'old'),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.authenticated, user: tAppUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] when no user',
      setUp: () => when(
        () => repository.getCurrentUser(),
      ).thenAnswer((_) async => const Right(null)),
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated + error] on failure',
      setUp: () => when(
        () => repository.getCurrentUser(),
      ).thenAnswer((_) async => const Left(ServerFailure('expired'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.unauthenticated, error: 'expired'),
      ],
    );
  });

  group('AuthSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] on success',
      setUp: () => when(
        () => repository.signIn(email: email, password: password),
      ).thenAnswer((_) async => const Right(tAppUser)),
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthSignInRequested(email, password)),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.authenticated, user: tAppUser),
      ],
      verify: (_) => verify(
        () => repository.signIn(email: email, password: password),
      ).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] on failure',
      setUp: () => when(
        () => repository.signIn(email: email, password: password),
      ).thenAnswer((_) async => const Left(ServerFailure('bad creds'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthSignInRequested(email, password)),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.error, error: 'bad creds'),
      ],
    );
  });

  group('AuthSignUpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated + justSignedUp + pending email]',
      setUp: () => when(
        () => repository.signUp(email: email, password: password),
      ).thenAnswer((_) async => const Right(tAppUser)),
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthSignUpRequested(email, password)),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.authenticated,
          user: tAppUser,
          justSignedUp: true,
          pendingVerificationEmail: email,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] on failure',
      setUp: () => when(
        () => repository.signUp(email: email, password: password),
      ).thenAnswer((_) async => const Left(ServerFailure('taken'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthSignUpRequested(email, password)),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.error, error: 'taken'),
      ],
    );
  });

  group('AuthSignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] on success',
      setUp: () => when(
        () => repository.signOut(),
      ).thenAnswer((_) async => const Right(null)),
      build: buildBloc,
      seed: () => const AuthState(status: AuthStatus.authenticated),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.unauthenticated),
      ],
      verify: (_) => verify(() => repository.signOut()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] on failure',
      setUp: () => when(
        () => repository.signOut(),
      ).thenAnswer((_) async => const Left(ServerFailure('net'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.error, error: 'net'),
      ],
    );
  });

  group('ResendVerificationRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated + pending email] on success',
      setUp: () => when(
        () => repository.resendVerificationEmail(email),
      ).thenAnswer((_) async => const Right(null)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ResendVerificationRequested(email)),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(
          status: AuthStatus.unauthenticated,
          pendingVerificationEmail: email,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated + error] on failure',
      setUp: () => when(
        () => repository.resendVerificationEmail(email),
      ).thenAnswer((_) async => const Left(ServerFailure('rate limited'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const ResendVerificationRequested(email)),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.unauthenticated, error: 'rate limited'),
      ],
    );
  });

  group('ForgotPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated + passwordResetSent] on success',
      setUp: () => when(
        () => repository.sendPasswordResetEmail(email),
      ).thenAnswer((_) async => const Right(null)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ForgotPasswordRequested(email)),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.unauthenticated, passwordResetSent: true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated + error] on failure',
      setUp: () => when(
        () => repository.sendPasswordResetEmail(email),
      ).thenAnswer((_) async => const Left(ServerFailure('unknown email'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const ForgotPasswordRequested(email)),
      expect: () => const [
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.unauthenticated, error: 'unknown email'),
      ],
    );
  });

  group('AuthState', () {
    test('copyWith keeps values when no args and clears error', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        user: tAppUser,
        error: 'e',
        justSignedUp: true,
        pendingVerificationEmail: email,
        passwordResetSent: true,
      );
      expect(
        state.copyWith(),
        const AuthState(
          status: AuthStatus.authenticated,
          user: tAppUser,
          justSignedUp: true,
          pendingVerificationEmail: email,
          passwordResetSent: true,
        ),
      );
    });

    test('copyWith can clear pendingVerificationEmail', () {
      const state = AuthState(pendingVerificationEmail: email);
      expect(
        state.copyWith(pendingVerificationEmail: null).pendingVerificationEmail,
        isNull,
      );
    });

    test('props', () {
      expect(const AuthState().props, [
        AuthStatus.initial,
        null,
        null,
        false,
        null,
        false,
      ]);
    });
  });

  test('AuthEvent props', () {
    // Built at runtime (non-const) so value equality is exercised on fresh
    // instances rather than canonicalized constants.
    final a = String.fromCharCode(97);
    // Non-const on purpose: exercises the runtime constructors.
    // ignore: prefer_const_constructors
    expect(AuthCheckRequested().props, isEmpty);
    // Non-const on purpose: exercises the runtime constructors.
    // ignore: prefer_const_constructors
    expect(AuthSignOutRequested().props, isEmpty);
    expect(AuthSignInRequested(a, 'b').props, ['a', 'b']);
    expect(AuthSignUpRequested(a, 'b').props, ['a', 'b']);
    expect(ResendVerificationRequested(a).props, ['a']);
    expect(ForgotPasswordRequested(a).props, ['a']);
    expect(AuthSignInRequested(a, 'b'), const AuthSignInRequested('a', 'b'));
    expect(
      const AuthSignInRequested('a', 'b'),
      isNot(const AuthSignInRequested('a', 'c')),
    );
  });
}
