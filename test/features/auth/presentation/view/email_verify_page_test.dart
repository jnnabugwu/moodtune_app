import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/email_verify_page.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

import '../../../../helpers/helpers.dart';
import '../../auth_page_fixtures.dart';

void main() {
  const pendingState = AuthState(
    status: AuthStatus.authenticated,
    user: testUser,
    justSignedUp: true,
    pendingVerificationEmail: testEmail,
  );

  setUpAll(() => registerFallbackValue(const AuthCheckRequested()));

  Finder resendButton() => find.widgetWithText(CupertinoButton, 'Resend email');

  group('EmailVerifyPage', () {
    testWidgets('shows the pending email address', (tester) async {
      await tester.pumpApp(
        const EmailVerifyPage(),
        authBloc: mockAuthBloc(pendingState),
      );

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(
        find.textContaining(testEmail, findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(ErrorBanner), findsNothing);
    });

    testWidgets('falls back to "your email" and disables resend', (
      tester,
    ) async {
      final bloc = mockAuthBloc(
        const AuthState(status: AuthStatus.unauthenticated),
      );
      await tester.pumpApp(const EmailVerifyPage(), authBloc: bloc);

      expect(
        find.textContaining('your email', findRichText: true),
        findsOneWidget,
      );
      expect(tester.widget<CupertinoButton>(resendButton()).onPressed, isNull);

      await tester.tap(resendButton());
      await tester.pump();
      verifyNever(
        () => bloc.add(any(that: isA<ResendVerificationRequested>())),
      );
    });

    testWidgets('resend dispatches event and runs a 60s cooldown', (
      tester,
    ) async {
      final bloc = mockAuthBloc(pendingState);
      await tester.pumpApp(const EmailVerifyPage(), authBloc: bloc);

      await tester.tap(resendButton());
      await tester.pump();

      verify(
        () => bloc.add(const ResendVerificationRequested(testEmail)),
      ).called(1);
      expect(find.text('Resend in 60s'), findsOneWidget);
      expect(resendButton(), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend in 59s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 59));
      expect(find.textContaining('Resend in'), findsNothing);
      expect(resendButton(), findsOneWidget);
    });

    testWidgets('disposing mid-cooldown cancels the timer', (tester) async {
      await tester.pumpApp(
        const EmailVerifyPage(),
        authBloc: mockAuthBloc(pendingState),
      );

      await tester.tap(resendButton());
      await tester.pump();
      expect(find.text('Resend in 60s'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('loading state shows a spinner instead of resend', (
      tester,
    ) async {
      await tester.pumpApp(
        const EmailVerifyPage(),
        authBloc: mockAuthBloc(
          const AuthState(
            status: AuthStatus.loading,
            pendingVerificationEmail: testEmail,
          ),
        ),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Resend email'), findsNothing);
    });

    testWidgets('renders an error banner when state has an error', (
      tester,
    ) async {
      await tester.pumpApp(
        const EmailVerifyPage(),
        authBloc: mockAuthBloc(
          const AuthState(
            status: AuthStatus.error,
            error: 'Could not resend',
            pendingVerificationEmail: testEmail,
          ),
        ),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Could not resend'), findsOneWidget);
    });

    testWidgets('navigates home once a verified session is active', (
      tester,
    ) async {
      final bloc = mockAuthBloc();
      whenListen(
        bloc,
        Stream.fromIterable(const [
          AuthState(status: AuthStatus.authenticated, user: testUser),
        ]),
        initialState: const AuthState(
          status: AuthStatus.loading,
          pendingVerificationEmail: testEmail,
        ),
      );
      await tester.pumpApp(const EmailVerifyPage(), authBloc: bloc);
      await tester.pump();
      await tester.pump();

      expect(find.text(navigatedTo(RouteNames.homeAuth)), findsOneWidget);
    });

    testWidgets('stays put when authenticated but just signed up', (
      tester,
    ) async {
      final bloc = mockAuthBloc();
      whenListen(
        bloc,
        Stream.fromIterable(const [pendingState]),
        initialState: const AuthState(status: AuthStatus.loading),
      );
      await tester.pumpApp(const EmailVerifyPage(), authBloc: bloc);
      await tester.pump();
      await tester.pump();

      expect(find.byType(EmailVerifyPage), findsOneWidget);
    });

    testWidgets('"Wrong email?" pops back', (tester) async {
      await tester.pumpApp(
        const PushLauncher(),
        authBloc: mockAuthBloc(pendingState),
        extraRoutes: [launchedRoute(const EmailVerifyPage())],
      );
      await tester.tap(find.text(launcherLabel));
      await tester.pumpAndSettle();
      expect(find.byType(EmailVerifyPage), findsOneWidget);

      await tester.tap(find.text('Wrong email? Go back'));
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerifyPage), findsNothing);
      expect(find.text(launcherLabel), findsOneWidget);
    });
  });
}
