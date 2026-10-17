import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_page.dart';

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
  Finder button(String label) => find.widgetWithText(CupertinoButton, label);

  group('AuthPage', () {
    testWidgets('dispatches AuthCheckRequested on init', (tester) async {
      await tester.pumpApp(const AuthPage(), authBloc: authBloc);

      verify(() => authBloc.add(const AuthCheckRequested())).called(1);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('shows the user email when present', (tester) async {
      final bloc = mockAuthBloc(
        const AuthState(status: AuthStatus.unauthenticated, user: testUser),
      );
      await tester.pumpApp(const AuthPage(), authBloc: bloc);

      expect(find.text(testEmail), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
    });

    testWidgets('does not submit when fields are empty', (tester) async {
      await tester.pumpApp(const AuthPage(), authBloc: authBloc);

      await tester.tap(button('Sign in'));
      await tester.pump();

      verifyNever(() => authBloc.add(any(that: isA<AuthSignInRequested>())));
    });

    testWidgets('submits AuthSignInRequested with trimmed values', (
      tester,
    ) async {
      await tester.pumpApp(const AuthPage(), authBloc: authBloc);

      await tester.enterText(field(0), ' $testEmail ');
      await tester.enterText(field(1), ' $testPassword ');
      await tester.tap(button('Sign in'));
      await tester.pump();

      verify(
        () => authBloc.add(const AuthSignInRequested(testEmail, testPassword)),
      ).called(1);
    });

    testWidgets('sign up button navigates to /signup', (tester) async {
      await tester.pumpApp(const AuthPage(), authBloc: authBloc);

      await tester.tap(button('Sign up'));
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.signup)), findsOneWidget);
    });

    testWidgets('continue as guest navigates to /guest', (tester) async {
      await tester.pumpApp(const AuthPage(), authBloc: authBloc);

      await tester.tap(button('Continue as guest'));
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.guest)), findsOneWidget);
    });

    testWidgets('loading state shows spinners and disables actions', (
      tester,
    ) async {
      final bloc = mockAuthBloc(const AuthState(status: AuthStatus.loading));
      await tester.pumpApp(const AuthPage(), authBloc: bloc);

      expect(find.byType(CupertinoActivityIndicator), findsNWidgets(2));
      expect(find.text('Sign in'), findsOneWidget); // nav title only
      for (final f in tester.widgetList<CupertinoTextField>(
        find.byType(CupertinoTextField),
      )) {
        expect(f.enabled, isFalse);
      }

      await tester.tap(button('Continue as guest'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AuthPage), findsOneWidget);
    });

    testWidgets('shows an error dialog that can be dismissed', (tester) async {
      whenListen(
        authBloc,
        Stream.fromIterable(const [
          AuthState(status: AuthStatus.error, error: 'Invalid login'),
        ]),
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );
      await tester.pumpApp(const AuthPage(), authBloc: authBloc);
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('Auth error'), findsOneWidget);
      expect(find.text('Invalid login'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    testWidgets('navigates to /home when authenticated', (tester) async {
      whenListen(
        authBloc,
        Stream.fromIterable(const [
          AuthState(status: AuthStatus.authenticated, user: testUser),
        ]),
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );
      await tester.pumpApp(const AuthPage(), authBloc: authBloc);
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.homeAuth)), findsOneWidget);
      expect(find.text(navigatedTo(RouteNames.guest)), findsNothing);
    });
  });
}
