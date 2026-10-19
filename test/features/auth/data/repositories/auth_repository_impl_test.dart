import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/auth/data/datasources/account_remote_datasource.dart';
import 'package:moodtune_app/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:moodtune_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/entities/auth_change.dart';
import 'package:moodtune_app/features/auth/domain/entities/social_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../blocs_fixtures.dart';

class _MockDatasource extends Mock implements SupabaseAuthDatasource {}

class _MockAccountDataSource extends Mock implements AccountRemoteDataSource {}

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

  group('deleteAccount', () {
    late _MockAccountDataSource account;
    late List<String> calls;

    AuthRepositoryImpl build({Future<void> Function()? clearLocalData}) =>
        AuthRepositoryImpl(
          datasource: datasource,
          accountDataSource: account,
          clearLocalData:
              clearLocalData ?? () async => calls.add('clearLocalData'),
        );

    DioException dioError({
      int? status,
      Object? data,
      DioExceptionType type = DioExceptionType.badResponse,
    }) {
      final options = RequestOptions(path: '/account', method: 'DELETE');
      return DioException(
        requestOptions: options,
        type: type,
        message: 'dio message',
        response: status == null
            ? null
            : Response<Object?>(
                requestOptions: options,
                statusCode: status,
                data: data,
              ),
      );
    }

    setUp(() {
      account = _MockAccountDataSource();
      calls = [];
      when(() => account.deleteAccount()).thenAnswer((_) async {
        calls.add('delete');
      });
      when(() => datasource.signOut()).thenAnswer((_) async {
        calls.add('signOut');
      });
    });

    test('deletes remotely, then signs out and clears local data', () async {
      expect(await build().deleteAccount(), const Right<Failure, void>(null));
      expect(calls, ['delete', 'signOut', 'clearLocalData']);
      verify(() => account.deleteAccount()).called(1);
    });

    test('still succeeds when sign-out or clearing fails afterwards', () async {
      when(
        () => datasource.signOut(),
      ).thenThrow(const AuthException('offline'));

      final repository = build(
        clearLocalData: () async => throw Exception('prefs'),
      );

      expect(
        await repository.deleteAccount(),
        const Right<Failure, void>(null),
      );
      verify(() => datasource.signOut()).called(1);
    });

    test('works without a clearLocalData callback', () async {
      final repository = AuthRepositoryImpl(
        datasource: datasource,
        accountDataSource: account,
      );
      expect(
        await repository.deleteAccount(),
        const Right<Failure, void>(null),
      );
    });

    // moodtune-backend#15: a deleted user's token no longer validates, so a
    // retry after a delete that may have succeeded gets 401 (after
    // AuthInterceptor's refresh fails). The account is gone: finish signing
    // out.
    for (final type in [
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.unknown,
    ]) {
      test('a 401 after a ${type.name} counts as already deleted', () async {
        final repository = build();
        when(() => account.deleteAccount()).thenThrow(dioError(type: type));
        expect(await repository.deleteAccount(), isA<Left<Failure, void>>());

        when(() => account.deleteAccount()).thenAnswer((_) async {
          calls.add('delete');
          throw dioError(status: 401, data: {'detail': 'Not authenticated'});
        });
        expect(
          await repository.deleteAccount(),
          const Right<Failure, void>(null),
        );
        expect(calls, ['delete', 'signOut', 'clearLocalData']);
      });
    }

    // Without an earlier attempt that may have deleted the account, a 401
    // only means the session expired: the account still exists.
    test(
      'a 401 on a first attempt is SessionExpiredFailure, no sign-out',
      () async {
        when(() => account.deleteAccount()).thenThrow(
          dioError(status: 401, data: {'detail': 'Not authenticated'}),
        );

        expect(
          await build().deleteAccount(),
          const Left<Failure, void>(
            SessionExpiredFailure('Session expired. Sign in again.'),
          ),
        );
        verifyNever(() => datasource.signOut());
        expect(calls, isEmpty);
      },
    );

    // A connect timeout never reached the backend, and any response other
    // than 401 proves the user still exists.
    for (final (name, first) in [
      ('connect timeout', dioError(type: DioExceptionType.connectionTimeout)),
      ('500 after a timeout', null),
    ]) {
      test('a 401 after a $name is still SessionExpiredFailure', () async {
        final repository = build();
        if (first == null) {
          when(
            () => account.deleteAccount(),
          ).thenThrow(dioError(type: DioExceptionType.receiveTimeout));
          await repository.deleteAccount();
          when(() => account.deleteAccount()).thenThrow(
            dioError(status: 500, data: {'detail': 'Could not delete account'}),
          );
          await repository.deleteAccount();
        } else {
          when(() => account.deleteAccount()).thenThrow(first);
          await repository.deleteAccount();
        }

        when(() => account.deleteAccount()).thenThrow(
          dioError(status: 401, data: {'detail': 'Not authenticated'}),
        );
        expect(
          await repository.deleteAccount(),
          isA<Left<Failure, void>>().having(
            (l) => l.value,
            'failure',
            isA<SessionExpiredFailure>(),
          ),
        );
        verifyNever(() => datasource.signOut());
      });
    }

    test('maps a 500 to ServerFailure(detail) without signing out', () async {
      when(() => account.deleteAccount()).thenThrow(
        dioError(status: 500, data: {'detail': 'Could not delete account'}),
      );

      expect(
        await build().deleteAccount(),
        const Left<Failure, void>(ServerFailure('Could not delete account')),
      );
      verifyNever(() => datasource.signOut());
      expect(calls, isEmpty);
    });

    test('falls back to the Dio message when there is no detail', () async {
      when(
        () => account.deleteAccount(),
      ).thenThrow(dioError(status: 502, data: ''));

      expect(
        await build().deleteAccount(),
        const Left<Failure, void>(ServerFailure('dio message')),
      );
      verifyNever(() => datasource.signOut());
    });

    test('maps network errors to NetworkFailure', () async {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        when(() => account.deleteAccount()).thenThrow(dioError(type: type));
        expect(
          await build().deleteAccount(),
          const Left<Failure, void>(NetworkFailure('dio message')),
          reason: '$type',
        );
      }
      verifyNever(() => datasource.signOut());
    });

    test('uses fixed messages when Dio has none', () async {
      final options = RequestOptions(path: '/account');
      when(() => account.deleteAccount()).thenThrow(
        DioException(requestOptions: options, type: DioExceptionType.unknown),
      );
      expect(
        await build().deleteAccount(),
        const Left<Failure, void>(ServerFailure('Server error')),
      );

      when(() => account.deleteAccount()).thenThrow(
        DioException.connectionTimeout(
          requestOptions: options,
          timeout: Duration.zero,
        ),
      );
      final result = await build().deleteAccount();
      expect(result.isLeft(), isTrue);
      result.leftMap((f) => expect(f, isA<NetworkFailure>()));
    });

    test('maps other Exceptions to ServerFailure(toString)', () async {
      final error = Exception('boom');
      when(() => account.deleteAccount()).thenThrow(error);
      expect(
        await build().deleteAccount(),
        Left<Failure, void>(ServerFailure(error.toString())),
      );
      verifyNever(() => datasource.signOut());
    });
  });

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
