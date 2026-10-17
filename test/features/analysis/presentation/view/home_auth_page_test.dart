import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/history_page.dart';
import 'package:moodtune_app/features/analysis/presentation/view/home_auth_page.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/shared/widgets/history_row_item.dart';

import '../../../../helpers/helpers.dart';
import 'results_fixtures.dart';

AuthState _signedIn(String email) => AuthState(
  status: AuthStatus.authenticated,
  user: AppUser(id: 'user-1', email: email),
);

void main() {
  setUpAll(() {
    registerFallbackValue(const AnalysisHistoryRequested());
    registerFallbackValue(const AuthSignOutRequested());
  });

  group('HomeAuthPage', () {
    testWidgets('requests history on mount and renders home tab', (
      tester,
    ) async {
      final analysisBloc = mockAnalysisBloc();

      await tester.pumpApp(
        const HomeAuthPage(),
        analysisBloc: analysisBloc,
        authBloc: mockAuthBloc(_signedIn('jane.doe@example.com')),
      );
      await tester.pumpAndSettle();

      verify(
        () => analysisBloc.add(const AnalysisHistoryRequested()),
      ).called(1);
      expect(find.text('MoodTune'), findsOneWidget);
      expect(find.text('Analyze a new song'), findsOneWidget);
      expect(find.text('Tap to upload a file'), findsOneWidget);
      expect(find.text('Browse the catalog'), findsOneWidget);
      expect(find.text('Explore free music'), findsOneWidget);
      expect(find.text('Recent analyses'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    group('avatar initials', () {
      final cases = {
        'jane.doe@example.com': 'JD',
        'john_smith@example.com': 'JS',
        'mary-jo@example.com': 'MJ',
        'bob@example.com': 'BO',
        'a@example.com': 'A',
        // Empty segments are ignored (#48).
        'john_@x.com': 'JO',
        '_john@x.com': 'JO',
        'john__smith@x.com': 'JS',
        '.a@x.com': 'A',
        '_@x.com': '?',
        '.-_@x.com': '?',
        '@x.com': '?',
      };

      for (final entry in cases.entries) {
        testWidgets('${entry.key} -> ${entry.value}', (tester) async {
          await tester.pumpApp(
            const HomeAuthPage(),
            authBloc: mockAuthBloc(_signedIn(entry.key)),
          );
          await tester.pumpAndSettle();

          expect(find.text(entry.value), findsOneWidget);
        });
      }

      testWidgets('shows "?" when there is no user', (tester) async {
        await tester.pumpApp(const HomeAuthPage());
        await tester.pumpAndSettle();

        expect(find.text('?'), findsOneWidget);
      });
    });

    group('recent analyses', () {
      testWidgets('shows a spinner while history is loading', (tester) async {
        await tester.pumpApp(
          const HomeAuthPage(),
          analysisBloc: mockAnalysisBloc(
            const AnalysisState(historyLoading: true),
          ),
        );
        await tester.pump();

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.byType(HistoryRowItem), findsNothing);
        expect(find.text('Your past analyses will appear here.'), findsNothing);
      });

      testWidgets('shows empty state that opens the source sheet', (
        tester,
      ) async {
        await tester.pumpApp(const HomeAuthPage());
        await tester.pumpAndSettle();

        expect(find.text('Your past analyses will appear here.'), findsOne);

        await tester.tap(find.text('Analyze your first song →'));
        await tester.pumpAndSettle();

        expect(find.text('Analyze a Song'), findsOneWidget);
        await tester.tap(find.text('Browse Catalog'));
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.catalog)), findsOneWidget);
      });

      testWidgets('shows at most three items and links to history', (
        tester,
      ) async {
        await tester.pumpApp(
          const HomeAuthPage(),
          analysisBloc: mockAnalysisBloc(
            AnalysisState(history: testHistory(5)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HistoryRowItem), findsNWidgets(3));
        expect(find.text('Entry 0'), findsOneWidget);
        expect(find.text('Entry 2'), findsOneWidget);
        expect(find.text('Entry 3'), findsNothing);

        // Rows are tappable without side effects.
        await tester.tap(find.text('Entry 0'));
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('See all history'));
        await tester.tap(find.text('See all history'));
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.history)), findsOneWidget);
      });
    });

    group('action cards', () {
      testWidgets('upload card pushes the upload route', (tester) async {
        await tester.pumpApp(const HomeAuthPage());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Analyze a new song'));
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.uploadMusic)), findsOneWidget);
      });

      testWidgets('catalog card pushes the catalog route', (tester) async {
        await tester.pumpApp(const HomeAuthPage());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Browse the catalog'));
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.catalog)), findsOneWidget);
      });
    });

    group('sign out sheet', () {
      testWidgets('signing out dispatches AuthSignOutRequested', (
        tester,
      ) async {
        final authBloc = mockAuthBloc(_signedIn('jane.doe@example.com'));

        await tester.pumpApp(const HomeAuthPage(), authBloc: authBloc);
        await tester.pumpAndSettle();

        await tester.tap(find.text('JD'));
        await tester.pumpAndSettle();
        expect(find.text('Sign out'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        await tester.tap(find.text('Sign out'));
        await tester.pumpAndSettle();

        verify(() => authBloc.add(const AuthSignOutRequested())).called(1);
        expect(find.text('Sign out'), findsNothing);
        expect(find.text('MoodTune'), findsOneWidget);
      });

      testWidgets('cancel closes the sheet without signing out', (
        tester,
      ) async {
        final authBloc = mockAuthBloc(_signedIn('jane.doe@example.com'));

        await tester.pumpApp(const HomeAuthPage(), authBloc: authBloc);
        await tester.pumpAndSettle();

        await tester.tap(find.text('JD'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        verifyNever(() => authBloc.add(any()));
        expect(find.text('Sign out'), findsNothing);
        expect(find.text('MoodTune'), findsOneWidget);
      });
    });

    testWidgets('History tab shows the embedded history page', (tester) async {
      await tester.pumpApp(const HomeAuthPage());
      await tester.pumpAndSettle();
      expect(find.byType(HistoryPage), findsNothing);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      final page = tester.widget<HistoryPage>(find.byType(HistoryPage));
      expect(page.isEmbedded, isTrue);
      expect(find.text('My History'), findsOneWidget);
    });
  });
}
