import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/reset_password_page.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

import '../../../../helpers/helpers.dart';
import '../../auth_page_fixtures.dart';

void main() {
  const recovering = AuthState(
    status: AuthStatus.authenticated,
    user: testUser,
    passwordRecovery: true,
  );

  setUpAll(() => registerFallbackValue(const AuthCheckRequested()));

  Finder field(int index) => find.byType(CupertinoTextField).at(index);
  Finder saveButton() => find.widgetWithText(CupertinoButton, 'Save password');

  group('ResetPasswordPage', () {
    testWidgets('requires a password', (tester) async {
      final bloc = mockAuthBloc(recovering);
      await tester.pumpApp(const ResetPasswordPage(), authBloc: bloc);

      await tester.tap(saveButton());
      await tester.pump();

      expect(find.text('Please enter a new password.'), findsOneWidget);
      verifyNever(() => bloc.add(any(that: isA<PasswordUpdateRequested>())));
    });

    testWidgets('requires matching passwords', (tester) async {
      final bloc = mockAuthBloc(recovering);
      await tester.pumpApp(const ResetPasswordPage(), authBloc: bloc);

      await tester.enterText(field(0), 'new-secret');
      await tester.enterText(field(1), 'different');
      await tester.tap(saveButton());
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      verifyNever(() => bloc.add(any(that: isA<PasswordUpdateRequested>())));
    });

    testWidgets('dispatches PasswordUpdateRequested', (tester) async {
      final bloc = mockAuthBloc(recovering);
      await tester.pumpApp(const ResetPasswordPage(), authBloc: bloc);

      await tester.enterText(field(0), ' new-secret ');
      await tester.enterText(field(1), 'new-secret');
      await tester.tap(saveButton());
      await tester.pump();

      verify(
        () => bloc.add(const PasswordUpdateRequested('new-secret')),
      ).called(1);
    });

    testWidgets('shows a spinner while saving', (tester) async {
      await tester.pumpApp(
        const ResetPasswordPage(),
        authBloc: mockAuthBloc(
          const AuthState(status: AuthStatus.loading, passwordRecovery: true),
        ),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Save password'), findsNothing);
    });

    testWidgets('goes home once the password is saved', (tester) async {
      final bloc = mockAuthBloc();
      whenListen(
        bloc,
        Stream.fromIterable(const [
          AuthState(
            status: AuthStatus.loading,
            user: testUser,
            passwordRecovery: true,
          ),
          AuthState(status: AuthStatus.authenticated, user: testUser),
        ]),
        initialState: recovering,
      );
      await tester.pumpApp(const ResetPasswordPage(), authBloc: bloc);
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.homeAuth)), findsOneWidget);
    });

    testWidgets('Cancel signs out of the recovery session', (tester) async {
      final bloc = mockAuthBloc(recovering);
      await tester.pumpApp(const ResetPasswordPage(), authBloc: bloc);

      await tester.tap(find.text('Cancel'));

      verify(() => bloc.add(const AuthSignOutRequested())).called(1);
    });

    testWidgets('goes to sign in once signed out', (tester) async {
      final bloc = mockAuthBloc();
      whenListen(
        bloc,
        Stream.fromIterable(const [
          AuthState(status: AuthStatus.unauthenticated),
        ]),
        initialState: recovering,
      );
      await tester.pumpApp(const ResetPasswordPage(), authBloc: bloc);
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.signIn)), findsOneWidget);
    });

    testWidgets('shows the server error', (tester) async {
      final bloc = mockAuthBloc();
      whenListen(
        bloc,
        Stream.fromIterable(const [
          AuthState(
            status: AuthStatus.authenticated,
            user: testUser,
            passwordRecovery: true,
            error: 'Password should be at least 6 characters.',
          ),
        ]),
        initialState: const AuthState(
          status: AuthStatus.loading,
          user: testUser,
          passwordRecovery: true,
        ),
      );
      await tester.pumpApp(const ResetPasswordPage(), authBloc: bloc);
      await tester.pump();

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(
        find.text('Password should be at least 6 characters.'),
        findsOneWidget,
      );
    });
  });
}
