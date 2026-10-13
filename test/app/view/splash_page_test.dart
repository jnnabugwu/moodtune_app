import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/app/view/splash_page.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';

import '../../helpers/helpers.dart';

void main() {
  const minDisplay = Duration(milliseconds: 1500);
  const user = AppUser(id: 'user-1', email: 'user@example.com');

  late MockAuthBloc authBloc;
  late StreamController<AuthState> controller;

  setUp(() {
    authBloc = mockAuthBloc();
    controller = StreamController<AuthState>();
    whenListen(authBloc, controller.stream, initialState: const AuthState());
  });

  // Not awaited: close() never completes if the stream was never listened to.
  tearDown(() => unawaited(controller.close()));

  group('SplashPage', () {
    testWidgets('renders the logo and requests an auth check', (
      tester,
    ) async {
      await tester.pumpApp(const SplashPage(), authBloc: authBloc);
      await tester.pump();

      expect(find.byType(MoodTuneLogo), findsOneWidget);
      expect(find.text('moodtune'), findsOneWidget);
      verify(() => authBloc.add(const AuthCheckRequested())).called(1);

      await tester.pump(minDisplay);
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('waits for the minimum display time before navigating', (
      tester,
    ) async {
      await tester.pumpApp(const SplashPage(), authBloc: authBloc);

      controller.add(
        const AuthState(status: AuthStatus.authenticated, user: user),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pump(minDisplay);
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.homeAuth)), findsOneWidget);
    });

    for (final status in [AuthStatus.unauthenticated, AuthStatus.error]) {
      testWidgets('navigates to landing when auth resolves as $status', (
        tester,
      ) async {
        await tester.pumpApp(const SplashPage(), authBloc: authBloc);

        controller.add(AuthState(status: status));
        await tester.pump(minDisplay);
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.landing)), findsOneWidget);
      });
    }

    testWidgets('navigates as soon as auth resolves after the timer', (
      tester,
    ) async {
      await tester.pumpApp(const SplashPage(), authBloc: authBloc);
      await tester.pump(minDisplay);

      // Loading does not trigger the listener.
      controller.add(const AuthState(status: AuthStatus.loading));
      await tester.pump();
      await tester.pump();
      expect(find.byType(SplashPage), findsOneWidget);

      controller.add(
        const AuthState(status: AuthStatus.authenticated, user: user),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(navigatedTo(RouteNames.homeAuth)), findsOneWidget);
    });

    testWidgets('does not navigate if disposed before the timer fires', (
      tester,
    ) async {
      await tester.pumpApp(const SplashPage(), authBloc: authBloc);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(minDisplay);

      expect(find.byType(SplashPage), findsNothing);
    });
  });

  group('MoodTuneLogo', () {
    testWidgets('renders both variants and repaints on change', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(const Center(child: MoodTuneLogo()));
      final darkText = tester.widget<Text>(find.text('moodtune'));
      expect(darkText.style!.color, MoodTuneLogo.cream);
      expect(darkText.style!.fontSize, closeTo(40 * 0.52, 0.001));

      await tester.pumpWidgetInShell(
        const Center(
          child: MoodTuneLogo(size: 60, variant: MoodTuneLogoVariant.light),
        ),
      );
      final lightText = tester.widget<Text>(find.text('moodtune'));
      expect(lightText.style!.color, MoodTuneLogo.ink);
      expect(lightText.style!.fontSize, closeTo(60 * 0.52, 0.001));

      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(MoodTuneLogo),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(paint.painter!.shouldRepaint(paint.painter!), isFalse);
    });
  });
}
