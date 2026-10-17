import 'package:equatable/equatable.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';

/// Session changes the app reacts to, typically after an email link
/// (sign-up confirmation or password reset) opens the app.
enum AuthChangeType { signedIn, passwordRecovery }

class AuthChange extends Equatable {
  const AuthChange({required this.type, required this.user});

  final AuthChangeType type;
  final AppUser user;

  @override
  List<Object?> get props => [type, user];
}
