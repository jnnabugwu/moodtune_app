import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/features/auth/data/datasources/social_credential_source.dart';
import 'package:moodtune_app/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/domain/entities/auth_change.dart';
import 'package:moodtune_app/features/auth/domain/entities/social_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockAuthResponse extends Mock implements AuthResponse {}

class _MockUser extends Mock implements User {}

class _MockSession extends Mock implements Session {}

class _FakeSource implements SocialCredentialSource {
  _FakeSource({this.isAvailable = true, this.credential});

  @override
  final bool isAvailable;
  final SocialCredential? credential;

  @override
  Future<SocialCredential?> obtain() async => credential;
}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;
  late SupabaseAuthDatasource datasource;

  const email = 'sam@example.com';
  const password = 'secret123';

  setUpAll(() {
    registerFallbackValue(OtpType.signup);
    registerFallbackValue(OAuthProvider.google);
    registerFallbackValue(UserAttributes());
  });

  // Pinned literally: it must match the Redirect URLs allowlist in Supabase
  // and the deep links the app registers.
  const redirect = 'moodtune://auth/login-callback';

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
        () => auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: redirect,
        ),
      ).thenAnswer((_) async => responseWith(user));

      expect(
        await datasource.signUp(email: email, password: password),
        const AppUser(id: 'u2', email: email),
      );
    });

    test('throws AuthException when no user is returned', () async {
      when(
        () => auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: redirect,
        ),
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
        emailRedirectTo: any(named: 'emailRedirectTo'),
      ),
    ).thenAnswer((_) async => ResendResponse());

    await datasource.resendVerificationEmail(email);

    verify(
      () => auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: redirect,
      ),
    ).called(1);
  });

  test('sendPasswordResetEmail delegates to resetPasswordForEmail', () async {
    when(
      () => auth.resetPasswordForEmail(email, redirectTo: redirect),
    ).thenAnswer((_) async {});
    await datasource.sendPasswordResetEmail(email);
    verify(
      () => auth.resetPasswordForEmail(email, redirectTo: redirect),
    ).called(1);
  });

  test('propagates AuthException thrown by Supabase', () async {
    when(
      () => auth.resetPasswordForEmail(email, redirectTo: redirect),
    ).thenThrow(const AuthException('rate limited'));

    await expectLater(
      datasource.sendPasswordResetEmail(email),
      throwsA(isA<AuthException>()),
    );
  });

  group('social sign-in', () {
    SupabaseAuthDatasource withSources({
      SocialCredentialSource? apple,
      SocialCredentialSource? google,
    }) => SupabaseAuthDatasource(
      client: client,
      apple: apple ?? _FakeSource(),
      google: google ?? _FakeSource(),
    );

    void stubIdTokenSignIn(User? user) => when(
      () => auth.signInWithIdToken(
        provider: any(named: 'provider'),
        idToken: any(named: 'idToken'),
        accessToken: any(named: 'accessToken'),
        nonce: any(named: 'nonce'),
      ),
    ).thenAnswer((_) async => responseWith(user));

    test('lists only the available providers', () {
      expect(
        withSources(
          google: _FakeSource(isAvailable: false),
        ).availableSocialProviders,
        {SocialProvider.apple},
      );
      expect(withSources().availableSocialProviders, {
        SocialProvider.apple,
        SocialProvider.google,
      });
    });

    test('signs in to Supabase with the Apple token and raw nonce', () async {
      stubIdTokenSignIn(buildUser(email: email));
      final datasource = withSources(
        apple: _FakeSource(
          credential: const SocialCredential(idToken: 'jwt', rawNonce: 'n'),
        ),
      );

      final user = await datasource.signInWithProvider(SocialProvider.apple);

      expect(user, const AppUser(id: 'u1', email: email));
      verify(
        () => auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: 'jwt',
          nonce: 'n',
        ),
      ).called(1);
    });

    test('passes Google tokens through and maps a missing email', () async {
      stubIdTokenSignIn(buildUser());
      final datasource = withSources(
        google: _FakeSource(
          credential: const SocialCredential(idToken: 'g', accessToken: 'a'),
        ),
      );

      final user = await datasource.signInWithProvider(SocialProvider.google);

      expect(user, const AppUser(id: 'u1', email: ''));
      verify(
        () => auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: 'g',
          accessToken: 'a',
        ),
      ).called(1);
    });

    test('returns null without calling Supabase when cancelled', () async {
      final user = await withSources().signInWithProvider(SocialProvider.apple);

      expect(user, isNull);
      verifyNever(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
        ),
      );
    });

    test('throws when Supabase returns no user', () async {
      stubIdTokenSignIn(null);
      final datasource = withSources(
        apple: _FakeSource(credential: const SocialCredential(idToken: 'j')),
      );

      await expectLater(
        datasource.signInWithProvider(SocialProvider.apple),
        throwsA(isA<AuthException>()),
      );
    });

    test('builds its own sources by default', () {
      // No dart-defines in tests, so Google is unavailable; Apple depends on
      // the host platform.
      expect(
        SupabaseAuthDatasource(client: client).availableSocialProviders,
        isNot(contains(SocialProvider.google)),
      );
    });
  });

  test('updatePassword sets the new password on the user', () async {
    when(
      () => auth.updateUser(any()),
    ).thenAnswer((_) async => UserResponse.fromJson({'id': 'u1'}));

    await datasource.updatePassword('new-secret');

    final attrs =
        verify(() => auth.updateUser(captureAny())).captured.single
            as UserAttributes;
    expect(attrs.password, 'new-secret');
  });

  group('authChanges', () {
    AuthState stateFor(AuthChangeEvent event, {User? user}) {
      Session? session;
      if (user != null) {
        session = _MockSession();
        when(() => session!.user).thenReturn(user);
      }
      return AuthState(event, session);
    }

    test('maps signedIn and passwordRecovery, drops everything else', () {
      final user = buildUser(email: email);
      when(() => auth.onAuthStateChange).thenAnswer(
        (_) => Stream.fromIterable([
          stateFor(AuthChangeEvent.initialSession, user: user),
          stateFor(AuthChangeEvent.signedIn, user: user),
          stateFor(AuthChangeEvent.tokenRefreshed, user: user),
          stateFor(AuthChangeEvent.signedIn),
          stateFor(AuthChangeEvent.passwordRecovery, user: user),
        ]),
      );

      const appUser = AppUser(id: 'u1', email: email);
      expect(
        datasource.authChanges(),
        emitsInOrder([
          const AuthChange(type: AuthChangeType.signedIn, user: appUser),
          const AuthChange(
            type: AuthChangeType.passwordRecovery,
            user: appUser,
          ),
          emitsDone,
        ]),
      );
    });

    test('keeps going after an unexpected stream error', () {
      final user = buildUser(email: email);
      when(() => auth.onAuthStateChange).thenAnswer(
        (_) => Stream.multi((controller) {
          controller
            ..addError(StateError('boom'))
            ..add(stateFor(AuthChangeEvent.signedIn, user: user))
            ..closeSync();
        }),
      );

      expect(
        datasource.authChanges(),
        emitsInOrder([
          const AuthChange(
            type: AuthChangeType.signedIn,
            user: AppUser(id: 'u1', email: email),
          ),
          emitsDone,
        ]),
      );
    });

    test('swallows stream errors from bad links', () {
      when(
        () => auth.onAuthStateChange,
      ).thenAnswer((_) => Stream.error(const AuthException('otp_expired')));
      expect(datasource.authChanges(), emitsDone);
    });
  });
}
