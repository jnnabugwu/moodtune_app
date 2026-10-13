import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/signup_page.dart';

import '../../../../helpers/helpers.dart';
import '../../auth_page_fixtures.dart';

void main() {
  late MockAuthBloc authBloc;

  const verifyBannerText =
      'Check your email to verify your address before signing in.';

  setUpAll(() => registerFallbackValue(const AuthCheckRequested()));

  setUp(() {
    authBloc = mockAuthBloc(
      const AuthState(status: AuthStatus.unauthenticated),
    );
  });

  Finder field(int index) => find.byType(CupertinoTextField).at(index);
  Finder button(String label) => find.widgetWithText(CupertinoButton, label);

  group('SignupPage', () {
    testWidgets('dispatches AuthCheckRequested on init and renders form', (
      tester,
    ) async {
      await tester.pumpApp(const SignupPage(), authBloc: authBloc);

      verify(() => authBloc.add(const AuthCheckRequested())).called(1);
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsNWidgets(2));
      expect(find.text(verifyBannerText), findsNothing);
    });

    testWidgets('does not submit when fields are empty', (tester) async {
      await tester.pumpApp(const SignupPage(), authBloc: authBloc);

      await tester.enterText(field(0), testEmail);
      await tester.tap(button('Sign up'));
      await tester.pump();

      verifyNever(() => authBloc.add(any(that: isA<AuthSignUpRequested>())));
    });

    testWidgets('submits AuthSignUpRequested with trimmed values', (
      tester,
    ) async {
      await tester.pumpApp(const SignupPage(), authBloc: authBloc);

      await tester.enterText(field(0), ' $testEmail ');
      await tester.enterText(field(1), ' $testPassword ');
      await tester.tap(button('Sign up'));
      await tester.pump();

      verify(
        () => authBloc.add(const AuthSignUpRequested(testEmail, testPassword)),
      ).called(1);
    });

    testWidgets('sign in button navigates to /login', (tester) async {
      await tester.pumpApp(const SignupPage(), authBloc: authBloc);

      await tester.tap(button('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.login)), findsOneWidget);
    });

    testWidgets('shows verify banner after sign-up', (tester) async {
      final bloc = mockAuthBloc(
        const AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
          justSignedUp: true,
        ),
      );
      await tester.pumpApp(const SignupPage(), authBloc: bloc);

      expect(find.text(verifyBannerText), findsOneWidget);
    });

    testWidgets('loading state shows spinners and disables inputs', (
      tester,
    ) async {
      final bloc = mockAuthBloc(const AuthState(status: AuthStatus.loading));
      await tester.pumpApp(const SignupPage(), authBloc: bloc);

      expect(find.byType(CupertinoActivityIndicator), findsNWidgets(2));
      for (final f in tester.widgetList<CupertinoTextField>(
        find.byType(CupertinoTextField),
      )) {
        expect(f.enabled, isFalse);
      }
    });

    testWidgets('shows an error dialog that can be dismissed', (tester) async {
      whenListen(
        authBloc,
        Stream.fromIterable(const [
          AuthState(status: AuthStatus.error, error: 'Email taken'),
        ]),
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );
      await tester.pumpApp(const SignupPage(), authBloc: authBloc);
      await tester.pumpAndSettle();

      expect(find.text('Auth error'), findsOneWidget);
      expect(find.text('Email taken'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });
  });
}
