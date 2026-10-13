import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/forgot_password_page.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

import '../../../../helpers/helpers.dart';
import '../../auth_page_fixtures.dart';

void main() {
  const idle = AuthState(status: AuthStatus.unauthenticated);
  const sent = AuthState(
    status: AuthStatus.unauthenticated,
    passwordResetSent: true,
  );

  setUpAll(() => registerFallbackValue(const AuthCheckRequested()));

  Finder button(String label) => find.widgetWithText(CupertinoButton, label);

  /// Pumps the page and transitions it to the "sent" view.
  Future<MockAuthBloc> pumpSent(
    WidgetTester tester, {
    String prefill = testEmail,
  }) async {
    final bloc = mockAuthBloc();
    whenListen(bloc, Stream.fromIterable(const [sent]), initialState: idle);
    await tester.pumpApp(
      ForgotPasswordPage(prefillEmail: prefill),
      authBloc: bloc,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return bloc;
  }

  group('ForgotPasswordPage', () {
    testWidgets('pre-fills the email field', (tester) async {
      await tester.pumpApp(
        const ForgotPasswordPage(prefillEmail: testEmail),
        authBloc: mockAuthBloc(idle),
      );

      expect(find.text('Reset your password'), findsOneWidget);
      final field = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      expect(field.controller!.text, testEmail);
    });

    testWidgets('does not send when email is empty', (tester) async {
      final bloc = mockAuthBloc(idle);
      await tester.pumpApp(
        const ForgotPasswordPage(prefillEmail: ''),
        authBloc: bloc,
      );

      await tester.tap(button('Send reset link'));
      await tester.pump();

      verifyNever(() => bloc.add(any(that: isA<ForgotPasswordRequested>())));
    });

    testWidgets('send dispatches ForgotPasswordRequested with trimmed email', (
      tester,
    ) async {
      final bloc = mockAuthBloc(idle);
      await tester.pumpApp(
        const ForgotPasswordPage(prefillEmail: ''),
        authBloc: bloc,
      );

      await tester.enterText(find.byType(CupertinoTextField), ' $testEmail ');
      await tester.tap(button('Send reset link'));
      await tester.pump();

      verify(
        () => bloc.add(const ForgotPasswordRequested(testEmail)),
      ).called(1);
    });

    testWidgets('submitting the keyboard sends the reset link', (
      tester,
    ) async {
      final bloc = mockAuthBloc(idle);
      await tester.pumpApp(
        const ForgotPasswordPage(prefillEmail: testEmail),
        authBloc: bloc,
      );

      await tester.showKeyboard(find.byType(CupertinoTextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      verify(
        () => bloc.add(const ForgotPasswordRequested(testEmail)),
      ).called(1);
    });

    testWidgets('loading state disables input and shows a spinner', (
      tester,
    ) async {
      await tester.pumpApp(
        const ForgotPasswordPage(prefillEmail: testEmail),
        authBloc: mockAuthBloc(const AuthState(status: AuthStatus.loading)),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Send reset link'), findsNothing);
      expect(
        tester
            .widget<CupertinoTextField>(find.byType(CupertinoTextField))
            .enabled,
        isFalse,
      );
    });

    testWidgets('renders an error banner', (tester) async {
      await tester.pumpApp(
        const ForgotPasswordPage(prefillEmail: testEmail),
        authBloc: mockAuthBloc(
          const AuthState(status: AuthStatus.error, error: 'Unknown email'),
        ),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Unknown email'), findsOneWidget);
    });

    testWidgets('switches to sent view with a 60s resend cooldown', (
      tester,
    ) async {
      await pumpSent(tester);

      expect(find.text('Link sent'), findsNWidgets(2)); // nav title + heading
      expect(
        find.text('Check your email for a reset link. It expires in 1 hour.'),
        findsOneWidget,
      );
      expect(find.text('Resend in 60s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend in 59s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 59));
      expect(find.textContaining('Resend in'), findsNothing);
      expect(button('Resend'), findsOneWidget);
    });

    testWidgets('resend dispatches event and restarts cooldown', (
      tester,
    ) async {
      final bloc = await pumpSent(tester);
      await tester.pump(const Duration(seconds: 60));

      await tester.tap(button('Resend'));
      await tester.pump();

      verify(
        () => bloc.add(const ForgotPasswordRequested(testEmail)),
      ).called(1);
      expect(find.text('Resend in 60s'), findsOneWidget);

      // Dispose mid-cooldown so the periodic timer is cancelled.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('resend is a no-op when the email is empty', (tester) async {
      final bloc = await pumpSent(tester, prefill: '');
      await tester.pump(const Duration(seconds: 60));

      await tester.tap(button('Resend'));
      await tester.pump();

      verifyNever(() => bloc.add(any(that: isA<ForgotPasswordRequested>())));
      expect(button('Resend'), findsOneWidget);
    });

    testWidgets('sent view shows spinner for resend while loading', (
      tester,
    ) async {
      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      final bloc = mockAuthBloc();
      whenListen(bloc, controller.stream, initialState: idle);
      await tester.pumpApp(
        const ForgotPasswordPage(prefillEmail: testEmail),
        authBloc: bloc,
      );

      controller.add(sent);
      await tester.pump();
      await tester.pump(const Duration(seconds: 60));
      controller.add(
        const AuthState(status: AuthStatus.loading, passwordResetSent: true),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Link sent'), findsNWidgets(2));
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Resend'), findsNothing);
    });

    testWidgets('"Back to sign in" navigates to sign-in', (tester) async {
      await pumpSent(tester);

      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.signIn)), findsOneWidget);
    });

    testWidgets('back goes to sign-in when nothing to pop', (tester) async {
      await tester.pumpApp(
        const ForgotPasswordPage(prefillEmail: ''),
        authBloc: mockAuthBloc(idle),
      );

      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.signIn)), findsOneWidget);
    });

    testWidgets('back pops when a previous route exists', (tester) async {
      await tester.pumpApp(
        const PushLauncher(),
        authBloc: mockAuthBloc(idle),
        extraRoutes: [
          launchedRoute(const ForgotPasswordPage(prefillEmail: '')),
        ],
      );
      await tester.tap(find.text(launcherLabel));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordPage), findsNothing);
      expect(find.text(launcherLabel), findsOneWidget);
    });
  });
}
