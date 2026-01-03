import 'package:dartz/dartz.dart';
import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({SupabaseAuthDatasource? datasource})
    : _datasource = datasource ?? SupabaseAuthDatasource();

  final SupabaseAuthDatasource _datasource;

  @override
  ResultFuture<AppUser?> getCurrentUser() async {
    try {
      final user = await _datasource.currentUser();
      return Right(user);
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> signOut() async {
    try {
      await _datasource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
