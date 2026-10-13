import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/sign_in_page.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

import '../../../../helpers/helpers.dart';
import '../../auth_page_fixtures.dart';

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() => registerFallbackValue(const AuthCheckRequested()));

  setUp(() {
    authBloc = mockAuthBloc(
      const AuthState(status: AuthStatus.unauthenticated),
    );
  });

  Finder field(int index) => find.byType(CupertinoTextField).at(index);
  Finder submitButton(String label) =>
      find.widgetWithText(CupertinoButton, label);

  Future<void> switchToSignUp(WidgetTester tester) async {
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
  }

  group('SignInPage', () {
    testWidgets('renders sign-in mode by default', (tester) async {
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);

      expect(find.byType(CupertinoTextField), findsNWidgets(2));
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Confirm password'), findsNothing);
      expect(submitButton('Sign in'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.byType(ErrorBanner), findsNothing);
    });

    testWidgets('shows validation error when fields are empty', (
      tester,
    ) async {
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);

      await tester.tap(submitButton('Sign in'));
      await tester.pump();

      expect(find.text('Please fill in all fields.'), findsOneWidget);
      verifyNever(() => authBloc.add(any(that: isA<AuthSignInRequested>())));
    });

    testWidgets('dispatches AuthSignInRequested with trimmed values', (
      tester,
    ) async {
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);

      await tester.enterText(field(0), '  $testEmail ');
      await tester.enterText(field(1), ' $testPassword ');
      await tester.tap(submitButton('Sign in'));
      await tester.pump();

      verify(
        () => authBloc.add(const AuthSignInRequested(testEmail, testPassword)),
      ).called(1);
      expect(find.byType(ErrorBanner), findsNothing);
    });

    testWidgets('switching to sign-up shows confirm field and clears error', (
      tester,
    ) async {
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);

      await tester.tap(submitButton('Sign in'));
      await tester.pump();
      expect(find.text('Please fill in all fields.'), findsOneWidget);

      await switchToSignUp(tester);

      expect(find.text('Please fill in all fields.'), findsNothing);
      expect(find.byType(CupertinoTextField), findsNWidgets(3));
      expect(find.text('Forgot password?'), findsNothing);
      expect(submitButton('Sign up'), findsOneWidget);

      // Tapping the already-active tab is a no-op.
      await tester.tap(find.text('Sign up').first);
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoTextField), findsNWidgets(3));

      // Switching back restores sign-in mode.
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoTextField), findsNWidgets(2));
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('sign-up shows error when passwords do not match', (
      tester,
    ) async {
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);
      await switchToSignUp(tester);

      await tester.enterText(field(0), testEmail);
      await tester.enterText(field(1), testPassword);
      await tester.enterText(field(2), 'different');
      await tester.tap(submitButton('Sign up'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      verifyNever(() => authBloc.add(any(that: isA<AuthSignUpRequested>())));
    });

    testWidgets('sign-up dispatches AuthSignUpRequested when valid', (
      tester,
    ) async {
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);
      await switchToSignUp(tester);

      await tester.enterText(field(0), testEmail);
      await tester.enterText(field(1), testPassword);
      await tester.enterText(field(2), testPassword);
      await tester.tap(submitButton('Sign up'));
      await tester.pump();

      verify(
        () => authBloc.add(const AuthSignUpRequested(testEmail, testPassword)),
      ).called(1);
      expect(find.byType(ErrorBanner), findsNothing);
    });

    testWidgets('loading state shows spinner and disables inputs', (
      tester,
    ) async {
      final bloc = mockAuthBloc(const AuthState(status: AuthStatus.loading));
      await tester.pumpApp(const SignInPage(), authBloc: bloc);

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      for (final f in tester.widgetList<CupertinoTextField>(
        find.byType(CupertinoTextField),
      )) {
        expect(f.enabled, isFalse);
      }

      // Mode toggle is disabled while loading.
      await tester.tap(find.text('Sign up'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CupertinoTextField), findsNWidgets(2));

      // Forgot password link is disabled while loading.
      await tester.tap(find.text('Forgot password?'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('renders bloc error in an ErrorBanner', (tester) async {
      whenListen(
        authBloc,
        Stream.fromIterable(const [
          AuthState(status: AuthStatus.error, error: 'Invalid credentials'),
        ]),
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);
      await tester.pump();

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('navigates home when authenticated after sign-in', (
      tester,
    ) async {
      whenListen(
        authBloc,
        Stream.fromIterable(const [
          AuthState(status: AuthStatus.authenticated, user: testUser),
        ]),
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.homeAuth)), findsOneWidget);
    });

    testWidgets('pushes email verify when authenticated after sign-up', (
      tester,
    ) async {
      whenListen(
        authBloc,
        Stream.fromIterable(const [
          AuthState(
            status: AuthStatus.authenticated,
            user: testUser,
            justSignedUp: true,
          ),
        ]),
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );
      await tester.pumpApp(
        const SignInPage(),
        authBloc: authBloc,
        extraRoutes: [stubRoute(RouteNames.emailVerify)],
      );
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.emailVerify)), findsOneWidget);
    });

    testWidgets('forgot password pushes route with entered email', (
      tester,
    ) async {
      await tester.pumpApp(
        const SignInPage(),
        authBloc: authBloc,
        extraRoutes: [stubRoute(RouteNames.forgotPassword)],
      );

      await tester.enterText(field(0), ' $testEmail ');
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(
        find.text(navigatedTo(RouteNames.forgotPassword)),
        findsOneWidget,
      );
      expect(find.text(extraText(testEmail)), findsOneWidget);
    });

    testWidgets('back goes to landing when nothing to pop', (tester) async {
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);

      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.landing)), findsOneWidget);
    });

    testWidgets('back pops when a previous route exists', (tester) async {
      await tester.pumpApp(
        const PushLauncher(),
        authBloc: authBloc,
        extraRoutes: [launchedRoute(const SignInPage())],
      );
      await tester.tap(find.text(launcherLabel));
      await tester.pumpAndSettle();
      expect(find.byType(SignInPage), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsNothing);
      expect(find.text(launcherLabel), findsOneWidget);
    });

    testWidgets('error clears on next submit attempt', (tester) async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      whenListen(
        authBloc,
        controller.stream,
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );
      await tester.pumpApp(const SignInPage(), authBloc: authBloc);

      controller.add(
        const AuthState(status: AuthStatus.error, error: 'Bad password'),
      );
      await tester.pump();
      expect(find.text('Bad password'), findsOneWidget);

      await tester.enterText(field(0), testEmail);
      await tester.enterText(field(1), testPassword);
      await tester.tap(submitButton('Sign in'));
      await tester.pump();

      expect(find.text('Bad password'), findsNothing);
    });
  });
}
