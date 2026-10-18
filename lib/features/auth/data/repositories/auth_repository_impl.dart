import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/auth/data/datasources/account_remote_datasource.dart';
import 'package:moodtune_app/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/entities/auth_change.dart';
import 'package:moodtune_app/features/auth/domain/entities/social_provider.dart';
import 'package:moodtune_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  /// [clearLocalData] removes what this device stored for the user; it runs
  /// after the account is deleted.
  AuthRepositoryImpl({
    SupabaseAuthDatasource? datasource,
    AccountRemoteDataSource? accountDataSource,
    Future<void> Function()? clearLocalData,
  }) : _datasource = datasource ?? SupabaseAuthDatasource(),
       _accountDataSource = accountDataSource ?? AccountRemoteDataSource(),
       _clearLocalData = clearLocalData;

  final SupabaseAuthDatasource _datasource;
  final AccountRemoteDataSource _accountDataSource;
  final Future<void> Function()? _clearLocalData;

  @override
  ResultFuture<AppUser?> getCurrentUser() async {
    try {
      final user = await _datasource.currentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.signIn(email: email, password: password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.signUp(email: email, password: password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Set<SocialProvider> get availableSocialProviders =>
      _datasource.availableSocialProviders;

  @override
  ResultFuture<AppUser?> signInWithProvider(SocialProvider provider) async {
    try {
      final user = await _datasource.signInWithProvider(provider);
      return Right(user);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> signOut() async {
    try {
      await _datasource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> deleteAccount() async {
    try {
      await _accountDataSource.deleteAccount();
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }

    // The account is gone. Supabase drops the local session before it calls
    // the server, so a failure here still leaves the device signed out.
    try {
      await _datasource.signOut();
    } on Exception catch (e) {
      talker.warning('Sign-out after account deletion failed: $e');
    }
    try {
      await _clearLocalData?.call();
    } on Exception catch (e) {
      talker.warning('Clearing local data after account deletion failed: $e');
    }
    return const Right(null);
  }

  Failure _mapDioError(DioException e) {
    final data = e.response?.data;
    final detail = data is Map ? data['detail']?.toString() : null;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkFailure(detail ?? e.message ?? 'Network error');
    }
    return ServerFailure(detail ?? e.message ?? 'Server error');
  }

  @override
  ResultFuture<void> resendVerificationEmail(String email) async {
    try {
      await _datasource.resendVerificationEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> sendPasswordResetEmail(String email) async {
    try {
      await _datasource.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> updatePassword(String password) async {
    try {
      await _datasource.updatePassword(password);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<AuthChange> authChanges() => _datasource.authChanges();
}
