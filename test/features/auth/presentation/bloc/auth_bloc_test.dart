import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/auth/domain/entities/auth_change.dart';
import 'package:moodtune_app/features/auth/domain/entities/social_provider.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../helpers/helpers.dart';
import '../../../blocs_fixtures.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(
      () => repository.authChanges(),
    ).thenAnswer((_) => const Stream.empty());
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

  test('starts with the social providers it was given', () {
    expect(
      AuthBloc(
        repository,
        socialProviders: const {SocialProvider.google},
      ).state.socialProviders,
      {SocialProvider.google},
    );
  });

  group('AuthSocialSignInRequested', () {
    const providers = {SocialProvider.apple, SocialProvider.google};
    AuthBloc buildSocial() => AuthBloc(repository, socialProviders: providers);

    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] on success',
      setUp: () => when(
        () => repository.signInWithProvider(SocialProvider.apple),
      ).thenAnswer((_) async => const Right(tAppUser)),
      build: buildSocial,
      act: (bloc) =>
          bloc.add(const AuthSocialSignInRequested(SocialProvider.apple)),
      expect: () => const [
        AuthState(status: AuthStatus.loading, socialProviders: providers),
        AuthState(
          status: AuthStatus.authenticated,
          user: tAppUser,
          socialProviders: providers,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'returns to unauthenticated without an error when cancelled',
      setUp: () => when(
        () => repository.signInWithProvider(SocialProvider.google),
      ).thenAnswer((_) async => const Right(null)),
      build: buildSocial,
      act: (bloc) =>
          bloc.add(const AuthSocialSignInRequested(SocialProvider.google)),
      expect: () => const [
        AuthState(status: AuthStatus.loading, socialProviders: providers),
        AuthState(
          status: AuthStatus.unauthenticated,
          socialProviders: providers,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] on failure',
      setUp: () => when(
        () => repository.signInWithProvider(SocialProvider.apple),
      ).thenAnswer((_) async => const Left(ServerFailure('nope'))),
      build: buildSocial,
      act: (bloc) =>
          bloc.add(const AuthSocialSignInRequested(SocialProvider.apple)),
      expect: () => const [
        AuthState(status: AuthStatus.loading, socialProviders: providers),
        AuthState(
          status: AuthStatus.error,
          error: 'nope',
          socialProviders: providers,
        ),
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
      'ends a password recovery',
      setUp: () => when(
        () => repository.signOut(),
      ).thenAnswer((_) async => const Right(null)),
      build: buildBloc,
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        passwordRecovery: true,
      ),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      skip: 1,
      expect: () => const [AuthState(status: AuthStatus.unauthenticated)],
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

  group('AuthChanged', () {
    const signedIn = AuthChange(type: AuthChangeType.signedIn, user: tAppUser);
    const recovery = AuthChange(
      type: AuthChangeType.passwordRecovery,
      user: tAppUser,
    );

    blocTest<AuthBloc, AuthState>(
      'confirmation link: authenticated and clears justSignedUp',
      setUp: () => when(
        () => repository.authChanges(),
      ).thenAnswer((_) => Stream.value(signedIn)),
      build: buildBloc,
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        user: tAppUser,
        justSignedUp: true,
        pendingVerificationEmail: email,
      ),
      expect: () => const [
        AuthState(
          status: AuthStatus.authenticated,
          user: tAppUser,
          pendingVerificationEmail: email,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'reset link: authenticated with passwordRecovery',
      setUp: () => when(
        () => repository.authChanges(),
      ).thenAnswer((_) => Stream.value(recovery)),
      build: buildBloc,
      expect: () => const [
        AuthState(
          status: AuthStatus.authenticated,
          user: tAppUser,
          passwordRecovery: true,
        ),
      ],
    );
  });

  group('PasswordUpdateRequested', () {
    const recovering = AuthState(
      status: AuthStatus.authenticated,
      user: tAppUser,
      passwordRecovery: true,
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] and clears passwordRecovery',
      setUp: () => when(
        () => repository.updatePassword(password),
      ).thenAnswer((_) async => const Right(null)),
      build: buildBloc,
      seed: () => recovering,
      act: (bloc) => bloc.add(const PasswordUpdateRequested(password)),
      expect: () => const [
        AuthState(
          status: AuthStatus.loading,
          user: tAppUser,
          passwordRecovery: true,
        ),
        AuthState(status: AuthStatus.authenticated, user: tAppUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'keeps passwordRecovery and reports the error on failure',
      setUp: () => when(
        () => repository.updatePassword(password),
      ).thenAnswer((_) async => const Left(ServerFailure('too weak'))),
      build: buildBloc,
      seed: () => recovering,
      act: (bloc) => bloc.add(const PasswordUpdateRequested(password)),
      expect: () => const [
        AuthState(
          status: AuthStatus.loading,
          user: tAppUser,
          passwordRecovery: true,
        ),
        AuthState(
          status: AuthStatus.authenticated,
          user: tAppUser,
          passwordRecovery: true,
          error: 'too weak',
        ),
      ],
    );
  });

  test('close cancels the auth change subscription', () async {
    final controller = StreamController<AuthChange>();
    when(() => repository.authChanges()).thenAnswer((_) => controller.stream);
    await buildBloc().close();
    expect(controller.hasListener, isFalse);
    await controller.close();
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
        false,
        <SocialProvider>{},
      ]);
    });

    test('copyWith keeps the social providers', () {
      const state = AuthState(socialProviders: {SocialProvider.apple});
      expect(state.copyWith(status: AuthStatus.loading).socialProviders, {
        SocialProvider.apple,
      });
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
    expect(PasswordUpdateRequested(a).props, ['a']);
    const change = AuthChange(type: AuthChangeType.signedIn, user: tAppUser);
    expect(const AuthChanged(change).props, [change]);
    expect(change.props, [AuthChangeType.signedIn, tAppUser]);
    expect(const AuthSocialSignInRequested(SocialProvider.google).props, [
      SocialProvider.google,
    ]);
    expect(AuthSignInRequested(a, 'b'), const AuthSignInRequested('a', 'b'));
    expect(
      const AuthSignInRequested('a', 'b'),
      isNot(const AuthSignInRequested('a', 'c')),
    );
  });
}
