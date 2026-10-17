import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_callback_page.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

import '../../../../helpers/helpers.dart';
import '../../auth_page_fixtures.dart';

void main() {
  final linkUri = Uri.parse('/login-callback?code=abc');

  const pendingVerify = AuthState(
    status: AuthStatus.authenticated,
    user: testUser,
    justSignedUp: true,
  );
  const signedIn = AuthState(status: AuthStatus.authenticated, user: testUser);
  const recovering = AuthState(
    status: AuthStatus.authenticated,
    user: testUser,
    passwordRecovery: true,
  );

  group('AuthCallbackPage', () {
    testWidgets('shows a spinner while the link is exchanged', (tester) async {
      await tester.pumpApp(
        AuthCallbackPage(uri: linkUri),
        authBloc: mockAuthBloc(pendingVerify),
      );

      expect(find.text('Signing you in…'), findsOneWidget);
      expect(find.byType(ErrorBanner), findsNothing);
      await tester.pump(AuthCallbackPage.timeout);
    });

    testWidgets('goes home once the confirmation signs the user in', (
      tester,
    ) async {
      final bloc = mockAuthBloc();
      whenListen(
        bloc,
        Stream.fromIterable(const [signedIn]),
        initialState: pendingVerify,
      );
      await tester.pumpApp(AuthCallbackPage(uri: linkUri), authBloc: bloc);
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.homeAuth)), findsOneWidget);
    });

    testWidgets('goes to reset password on a recovery link', (tester) async {
      final bloc = mockAuthBloc();
      whenListen(
        bloc,
        Stream.fromIterable(const [recovering]),
        initialState: signedIn,
      );
      await tester.pumpApp(AuthCallbackPage(uri: linkUri), authBloc: bloc);
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.resetPassword)), findsOneWidget);
    });

    testWidgets('goes to reset password if recovery landed first', (
      tester,
    ) async {
      await tester.pumpApp(
        AuthCallbackPage(uri: linkUri),
        authBloc: mockAuthBloc(recovering),
      );
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.resetPassword)), findsOneWidget);
    });

    testWidgets('shows the link error from the query', (tester) async {
      await tester.pumpApp(
        AuthCallbackPage(
          uri: Uri.parse(
            '/login-callback?error=access_denied'
            '&error_description=Email+link+is+invalid+or+has+expired',
          ),
        ),
        authBloc: mockAuthBloc(pendingVerify),
      );

      expect(find.text('Email link is invalid or has expired'), findsOneWidget);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.text(navigatedTo(RouteNames.signIn)), findsOneWidget);
    });

    testWidgets('shows the link error from the fragment', (tester) async {
      await tester.pumpApp(
        AuthCallbackPage(
          uri: Uri.parse('/login-callback#error_description=Token+expired'),
        ),
        authBloc: mockAuthBloc(pendingVerify),
      );

      expect(find.text('Token expired'), findsOneWidget);
    });

    testWidgets('times out to an error when no session arrives', (
      tester,
    ) async {
      await tester.pumpApp(
        AuthCallbackPage(uri: linkUri),
        authBloc: mockAuthBloc(pendingVerify),
      );
      await tester.pump(AuthCallbackPage.timeout);

      expect(find.textContaining('invalid or has expired'), findsOneWidget);
    });

    testWidgets('times out to home when already signed in', (tester) async {
      await tester.pumpApp(
        AuthCallbackPage(uri: linkUri),
        authBloc: mockAuthBloc(signedIn),
      );
      await tester.pump(AuthCallbackPage.timeout);
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.homeAuth)), findsOneWidget);
    });
  });
}
