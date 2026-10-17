import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:moodtune_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/entities/auth_change.dart';
import 'package:moodtune_app/features/auth/domain/entities/social_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../blocs_fixtures.dart';

class _MockDatasource extends Mock implements SupabaseAuthDatasource {}

void main() {
  late _MockDatasource datasource;
  late AuthRepositoryImpl repository;

  const email = 'sam@example.com';
  const password = 'secret123';

  setUp(() {
    datasource = _MockDatasource();
    repository = AuthRepositoryImpl(datasource: datasource);
  });

  /// Runs the shared failure-mapping assertions for one repository method.
  void failureMapping({
    required String name,
    required void Function() Function(Object error) stub,
    required Future<Either<Failure, Object?>> Function() call,
  }) {
    group('$name failure mapping', () {
      test('maps AuthException to ServerFailure with its message', () async {
        stub(const AuthException('auth broke'))();
        expect(
          await call(),
          const Left<Failure, Object?>(ServerFailure('auth broke')),
        );
      });

      test('maps other Exceptions to ServerFailure(toString)', () async {
        final error = Exception('generic');
        stub(error)();
        expect(
          await call(),
          Left<Failure, Object?>(ServerFailure(error.toString())),
        );
      });
    });
  }

  group('getCurrentUser', () {
    test('returns Right(user)', () async {
      when(() => datasource.currentUser()).thenAnswer((_) async => tAppUser);
      expect(
        await repository.getCurrentUser(),
        const Right<Failure, AppUser?>(tAppUser),
      );
    });

    test('returns Right(null) when signed out', () async {
      when(() => datasource.currentUser()).thenAnswer((_) async => null);
      expect(
        await repository.getCurrentUser(),
        const Right<Failure, AppUser?>(null),
      );
    });
  });

  failureMapping(
    name: 'getCurrentUser',
    stub: (e) =>
        () => when(() => datasource.currentUser()).thenThrow(e),
    call: () => repository.getCurrentUser(),
  );

  test('signIn returns Right(user)', () async {
    when(
      () => datasource.signIn(email: email, password: password),
    ).thenAnswer((_) async => tAppUser);
    expect(
      await repository.signIn(email: email, password: password),
      const Right<Failure, AppUser>(tAppUser),
    );
  });

  failureMapping(
    name: 'signIn',
    stub: (e) =>
        () => when(
          () => datasource.signIn(email: email, password: password),
        ).thenThrow(e),
    call: () => repository.signIn(email: email, password: password),
  );

  test('signUp returns Right(user)', () async {
    when(
      () => datasource.signUp(email: email, password: password),
    ).thenAnswer((_) async => tAppUser);
    expect(
      await repository.signUp(email: email, password: password),
      const Right<Failure, AppUser>(tAppUser),
    );
  });

  failureMapping(
    name: 'signUp',
    stub: (e) =>
        () => when(
          () => datasource.signUp(email: email, password: password),
        ).thenThrow(e),
    call: () => repository.signUp(email: email, password: password),
  );

  test('signOut returns Right(null)', () async {
    when(() => datasource.signOut()).thenAnswer((_) async {});
    expect(await repository.signOut(), const Right<Failure, void>(null));
    verify(() => datasource.signOut()).called(1);
  });

  failureMapping(
    name: 'signOut',
    stub: (e) =>
        () => when(() => datasource.signOut()).thenThrow(e),
    call: () => repository.signOut(),
  );

  test('resendVerificationEmail returns Right(null)', () async {
    when(
      () => datasource.resendVerificationEmail(email),
    ).thenAnswer((_) async {});
    expect(
      await repository.resendVerificationEmail(email),
      const Right<Failure, void>(null),
    );
    verify(() => datasource.resendVerificationEmail(email)).called(1);
  });

  failureMapping(
    name: 'resendVerificationEmail',
    stub: (e) =>
        () =>
            when(() => datasource.resendVerificationEmail(email)).thenThrow(e),
    call: () => repository.resendVerificationEmail(email),
  );

  test('sendPasswordResetEmail returns Right(null)', () async {
    when(
      () => datasource.sendPasswordResetEmail(email),
    ).thenAnswer((_) async {});
    expect(
      await repository.sendPasswordResetEmail(email),
      const Right<Failure, void>(null),
    );
    verify(() => datasource.sendPasswordResetEmail(email)).called(1);
  });

  failureMapping(
    name: 'sendPasswordResetEmail',
    stub: (e) =>
        () => when(() => datasource.sendPasswordResetEmail(email)).thenThrow(e),
    call: () => repository.sendPasswordResetEmail(email),
  );

  group('social sign-in', () {
    test('exposes the datasource providers', () {
      when(
        () => datasource.availableSocialProviders,
      ).thenReturn({SocialProvider.apple});

      expect(repository.availableSocialProviders, {SocialProvider.apple});
    });

    test('returns the signed-in user', () async {
      when(
        () => datasource.signInWithProvider(SocialProvider.google),
      ).thenAnswer((_) async => const AppUser(id: 'u1', email: email));

      expect(
        await repository.signInWithProvider(SocialProvider.google),
        const Right<Failure, AppUser?>(AppUser(id: 'u1', email: email)),
      );
    });

    test('returns Right(null) when cancelled', () async {
      when(
        () => datasource.signInWithProvider(SocialProvider.apple),
      ).thenAnswer((_) async => null);

      expect(
        await repository.signInWithProvider(SocialProvider.apple),
        const Right<Failure, AppUser?>(null),
      );
    });
  });

  failureMapping(
    name: 'signInWithProvider',
    stub: (e) =>
        () => when(
          () => datasource.signInWithProvider(SocialProvider.apple),
        ).thenThrow(e),
    call: () => repository.signInWithProvider(SocialProvider.apple),
  );

  test('updatePassword returns Right(null)', () async {
    when(() => datasource.updatePassword(password)).thenAnswer((_) async {});
    expect(
      await repository.updatePassword(password),
      const Right<Failure, void>(null),
    );
    verify(() => datasource.updatePassword(password)).called(1);
  });

  failureMapping(
    name: 'updatePassword',
    stub: (e) =>
        () => when(() => datasource.updatePassword(password)).thenThrow(e),
    call: () => repository.updatePassword(password),
  );

  test('authChanges forwards the datasource stream', () {
    const change = AuthChange(type: AuthChangeType.signedIn, user: tAppUser);
    when(
      () => datasource.authChanges(),
    ).thenAnswer((_) => Stream.value(change));
    expect(repository.authChanges(), emitsInOrder([change, emitsDone]));
  });
}
