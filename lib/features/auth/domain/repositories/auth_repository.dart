import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/utils/typedef.dart';

abstract class AuthRepository {
  ResultFuture<AppUser?> getCurrentUser();
  ResultFuture<AppUser> signIn({
    required String email,
    required String password,
  });
  ResultFuture<AppUser> signUp({
    required String email,
    required String password,
  });
  ResultFuture<void> signOut();
}
