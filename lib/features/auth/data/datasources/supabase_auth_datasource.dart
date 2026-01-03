import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthDatasource {
  SupabaseAuthDatasource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AppUser?> currentUser() async {
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('No user returned from Supabase');
    }
    return AppUser(id: user.id, email: user.email ?? email);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('No user returned from Supabase');
    }
    return AppUser(id: user.id, email: user.email ?? email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
