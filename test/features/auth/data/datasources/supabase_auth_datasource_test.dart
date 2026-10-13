import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockAuthResponse extends Mock implements AuthResponse {}

class _MockUser extends Mock implements User {}

class _MockSession extends Mock implements Session {}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;
  late SupabaseAuthDatasource datasource;

  const email = 'sam@example.com';
  const password = 'secret123';

  setUpAll(() {
    registerFallbackValue(OtpType.signup);
  });

  setUp(() {
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    datasource = SupabaseAuthDatasource(client: client);
  });

  _MockUser buildUser({String id = 'u1', String? email}) {
    final user = _MockUser();
    when(() => user.id).thenReturn(id);
    when(() => user.email).thenReturn(email);
    return user;
  }

  _MockAuthResponse responseWith(User? user) {
    final response = _MockAuthResponse();
    when(() => response.user).thenReturn(user);
    return response;
  }

  group('currentUser', () {
    test('returns null when there is no session', () async {
      when(() => auth.currentSession).thenReturn(null);
      expect(await datasource.currentUser(), isNull);
    });

    test('maps the session user to AppUser', () async {
      final session = _MockSession();
      final user = buildUser(email: email);
      when(() => session.user).thenReturn(user);
      when(() => auth.currentSession).thenReturn(session);

      expect(
        await datasource.currentUser(),
        const AppUser(id: 'u1', email: email),
      );
    });

    test('falls back to empty email when user has none', () async {
      final session = _MockSession();
      final user = buildUser();
      when(() => session.user).thenReturn(user);
      when(() => auth.currentSession).thenReturn(session);

      expect(
        await datasource.currentUser(),
        const AppUser(id: 'u1', email: ''),
      );
    });
  });

  group('signIn', () {
    test('returns AppUser from the response user', () async {
      final user = buildUser(email: 'server@example.com');
      when(
        () => auth.signInWithPassword(email: email, password: password),
      ).thenAnswer((_) async => responseWith(user));

      expect(
        await datasource.signIn(email: email, password: password),
        const AppUser(id: 'u1', email: 'server@example.com'),
      );
    });

    test('falls back to the input email when the user has none', () async {
      final user = buildUser();
      when(
        () => auth.signInWithPassword(email: email, password: password),
      ).thenAnswer((_) async => responseWith(user));

      expect(
        await datasource.signIn(email: email, password: password),
        const AppUser(id: 'u1', email: email),
      );
    });

    test('throws AuthException when no user is returned', () async {
      when(
        () => auth.signInWithPassword(email: email, password: password),
      ).thenAnswer((_) async => responseWith(null));

      await expectLater(
        datasource.signIn(email: email, password: password),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'No user returned from Supabase',
          ),
        ),
      );
    });
  });

  group('signUp', () {
    test('returns AppUser from the response user', () async {
      final user = buildUser(id: 'u2');
      when(
        () => auth.signUp(email: email, password: password),
      ).thenAnswer((_) async => responseWith(user));

      expect(
        await datasource.signUp(email: email, password: password),
        const AppUser(id: 'u2', email: email),
      );
    });

    test('throws AuthException when no user is returned', () async {
      when(
        () => auth.signUp(email: email, password: password),
      ).thenAnswer((_) async => responseWith(null));

      await expectLater(
        datasource.signUp(email: email, password: password),
        throwsA(isA<AuthException>()),
      );
    });
  });

  test('signOut delegates to GoTrueClient.signOut', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});
    await datasource.signOut();
    verify(() => auth.signOut()).called(1);
  });

  test('resendVerificationEmail resends a signup OTP to the email', () async {
    when(
      () => auth.resend(
        type: any(named: 'type'),
        email: any(named: 'email'),
      ),
    ).thenAnswer((_) async => ResendResponse());

    await datasource.resendVerificationEmail(email);

    verify(() => auth.resend(type: OtpType.signup, email: email)).called(1);
  });

  test('sendPasswordResetEmail delegates to resetPasswordForEmail', () async {
    when(() => auth.resetPasswordForEmail(email)).thenAnswer((_) async {});
    await datasource.sendPasswordResetEmail(email);
    verify(() => auth.resetPasswordForEmail(email)).called(1);
  });

  test('propagates AuthException thrown by Supabase', () async {
    when(
      () => auth.resetPasswordForEmail(email),
    ).thenThrow(const AuthException('rate limited'));

    await expectLater(
      datasource.sendPasswordResetEmail(email),
      throwsA(isA<AuthException>()),
    );
  });
}
