import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/app/view/splash_page.dart';
import 'package:moodtune_app/core/routing/routing.dart';
import 'package:moodtune_app/di/injector.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/view.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_callback_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_gate_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/email_verify_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/forgot_password_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/reset_password_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/sign_in_page.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:moodtune_app/features/catalog/presentation/view/catalog_search_page.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';
import 'package:moodtune_app/features/spotify/presentation/view/playlist_tracks_page.dart';
import 'package:moodtune_app/features/spotify/presentation/view/playlists_page.dart';
import 'package:moodtune_app/l10n/l10n.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../helpers/helpers.dart';

const _playlist = SpotifyPlaylist(
  id: 'pl-1',
  name: 'Road Trip',
  tracksCount: 12,
);

const _track = SpotifyTrack(id: 'tr-1', name: 'Song', artists: ['Artist']);

const _songResult = SongAnalysisResult(
  trackName: 'Song',
  artistName: 'Artist',
  trackId: 'tr-1',
  mood: SongMoodResult(
    primaryMood: 'happy',
    confidence: 0.9,
    valence: 0.8,
    energy: 0.7,
  ),
  features: SongAudioFeatures(
    tempo: 120,
    energy: 0.7,
    valence: 0.8,
    danceability: 0.6,
    loudness: -5,
  ),
  success: true,
);

void main() {
  late MockAuthBloc authBloc;
  late MockAnalysisBloc analysisBloc;
  late MockSpotifyBloc spotifyBloc;

  setUpAll(() => registerFallbackValue(const AnalysisHistoryRequested()));

  setUp(() {
    authBloc = mockAuthBloc(
      const AuthState(status: AuthStatus.unauthenticated),
    );
    analysisBloc = mockAnalysisBloc();
    spotifyBloc = mockSpotifyBloc();
    getIt.registerFactory<CatalogBloc>(mockCatalogBloc);
  });

  tearDown(getIt.reset);

  /// Mounts the real [AppRouter.router] at [location] inside the app shell.
  ///
  /// The router is a static singleton, so the location is reset explicitly
  /// before every mount to avoid leaking state between tests.
  Future<void> pumpRouterAt(
    WidgetTester tester,
    String location, {
    Object? extra,
  }) async {
    AppRouter.router.go(location, extra: extra);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<AnalysisBloc>.value(value: analysisBloc),
          BlocProvider<SpotifyBloc>.value(value: spotifyBloc),
        ],
        child: ShadApp.custom(
          appBuilder: (context) => CupertinoApp.router(
            theme: CupertinoTheme.of(context),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: AppRouter.router,
          ),
          themeMode: ThemeMode.light,
          theme: ShadThemeData(
            brightness: Brightness.light,
            colorScheme: const ShadSlateColorScheme.light(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Unmounts the app so page timers are cancelled, then drains any
  /// remaining delayed futures (e.g. the splash minimum-display timer).
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  String currentPath() =>
      AppRouter.router.routerDelegate.currentConfiguration.uri.path;

  final cases = <({String location, Object? extra, Type page})>[
    (location: RouteNames.splash, extra: null, page: SplashPage),
    (location: RouteNames.landing, extra: null, page: GuestPage),
    (location: RouteNames.signIn, extra: null, page: SignInPage),
    (location: RouteNames.emailVerify, extra: null, page: EmailVerifyPage),
    (location: RouteNames.loginCallback, extra: null, page: AuthCallbackPage),
    (location: RouteNames.resetPassword, extra: null, page: ResetPasswordPage),
    (location: RouteNames.homeAuth, extra: null, page: HomeAuthPage),
    (location: RouteNames.history, extra: null, page: HistoryPage),
    (location: RouteNames.catalog, extra: null, page: CatalogSearchPage),
    (location: RouteNames.uploadMusic, extra: null, page: UploadMusicPage),
    (
      location: RouteNames.result,
      extra: AnalysisSource.catalog,
      page: ResultsPage,
    ),
    (location: RouteNames.result, extra: null, page: ResultsPage),
    (location: RouteNames.spotify, extra: null, page: AuthGatePage),
    (location: RouteNames.callback, extra: null, page: AuthGatePage),
    (location: RouteNames.playlists, extra: null, page: SpotifyPlaylistsPage),
    (
      location: RouteNames.playlistTracksFor('pl-1'),
      extra: _playlist,
      page: PlaylistTracksPage,
    ),
    (
      location: RouteNames.playlistTracksFor('pl-1'),
      extra: null,
      page: NotFoundPage,
    ),
    (
      location: RouteNames.analyzingFor('pl-1'),
      extra: _playlist,
      page: AnalyzingPage,
    ),
    (
      location: RouteNames.songAnalyzingFor('tr-1'),
      extra: _track,
      page: SongAnalyzingPage,
    ),
    (location: RouteNames.songResult, extra: _songResult, page: SongResultPage),
    (location: RouteNames.songResult, extra: null, page: NotFoundPage),
    (location: RouteNames.notFound, extra: null, page: NotFoundPage),
  ];

  group('AppRouter', () {
    for (final c in cases) {
      testWidgets(
        '${c.location} (extra: ${c.extra?.runtimeType}) renders ${c.page}',
        (tester) async {
          await pumpRouterAt(tester, c.location, extra: c.extra);

          expect(find.byType(c.page), findsOneWidget);
          expect(currentPath(), c.location);

          await unmount(tester);
        },
      );
    }

    for (final (from, to, page) in [
      (RouteNames.login, RouteNames.signIn, SignInPage),
      (RouteNames.signup, RouteNames.signIn, SignInPage),
      (RouteNames.guest, RouteNames.landing, GuestPage),
    ]) {
      testWidgets('legacy $from redirects to $to', (tester) async {
        await pumpRouterAt(tester, from);

        expect(find.byType(page), findsOneWidget);
        expect(currentPath(), to);

        await unmount(tester);
      });
    }

    testWidgets('forgot password pre-fills email from extra', (tester) async {
      await pumpRouterAt(
        tester,
        RouteNames.forgotPassword,
        extra: 'user@example.com',
      );

      final page = tester.widget<ForgotPasswordPage>(
        find.byType(ForgotPasswordPage),
      );
      expect(page.prefillEmail, 'user@example.com');

      await unmount(tester);
    });

    testWidgets('forgot password defaults to empty email', (tester) async {
      await pumpRouterAt(tester, RouteNames.forgotPassword);

      final page = tester.widget<ForgotPasswordPage>(
        find.byType(ForgotPasswordPage),
      );
      expect(page.prefillEmail, isEmpty);

      await unmount(tester);
    });

    testWidgets('result route opens a HistoryEntry read-only', (tester) async {
      final entry = HistoryEntry(
        id: 'h1',
        title: 'Saved Song',
        primaryMood: 'happy',
        confidence: 0.8,
        createdAt: DateTime(2026, 10, 17),
        type: HistoryEntryType.song,
      );
      await pumpRouterAt(tester, RouteNames.result, extra: entry);

      final page = tester.widget<ResultsPage>(find.byType(ResultsPage));
      expect(page.savedEntry, entry);
      expect(find.text('Saved Song'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('analysis loading accepts AnalysisLoadingArgs', (tester) async {
      await pumpRouterAt(
        tester,
        RouteNames.analysisLoading,
        extra: const AnalysisLoadingArgs(
          source: AnalysisSource.catalog,
          trackDurationSeconds: 300,
        ),
      );

      final page = tester.widget<AnalysisLoadingPage>(
        find.byType(AnalysisLoadingPage),
      );
      expect(page.source, AnalysisSource.catalog);
      expect(page.trackDurationSeconds, 300);

      await unmount(tester);
    });

    testWidgets('analysis loading accepts a bare AnalysisSource', (
      tester,
    ) async {
      await pumpRouterAt(
        tester,
        RouteNames.analysisLoading,
        extra: AnalysisSource.catalog,
      );

      final page = tester.widget<AnalysisLoadingPage>(
        find.byType(AnalysisLoadingPage),
      );
      expect(page.source, AnalysisSource.catalog);
      expect(page.trackDurationSeconds, isNull);

      await unmount(tester);
    });

    testWidgets('analysis loading defaults to upload source', (tester) async {
      await pumpRouterAt(tester, RouteNames.analysisLoading);

      final page = tester.widget<AnalysisLoadingPage>(
        find.byType(AnalysisLoadingPage),
      );
      expect(page.source, AnalysisSource.upload);

      await unmount(tester);
    });

    testWidgets('analyzing passes playlist meta and path param', (
      tester,
    ) async {
      await pumpRouterAt(
        tester,
        RouteNames.analyzingFor('pl-1'),
        extra: _playlist,
      );

      final page = tester.widget<AnalyzingPage>(find.byType(AnalyzingPage));
      expect(page.playlistId, 'pl-1');
      expect(page.playlistName, 'Road Trip');
      expect(page.trackCount, 12);

      await unmount(tester);
    });

    testWidgets('analysis result deep link requests the analysis by id', (
      tester,
    ) async {
      await pumpRouterAt(tester, RouteNames.analysisResultFor('an-1'));

      final page = tester.widget<AnalysisResultPage>(
        find.byType(AnalysisResultPage),
      );
      expect(page.analysisId, 'an-1');
      expect(page.initialAnalysis, isNull);
      verify(
        () => analysisBloc.add(const AnalysisByIdRequested('an-1')),
      ).called(1);

      await unmount(tester);
    });

    testWidgets('unknown location renders ErrorPage', (tester) async {
      await pumpRouterAt(tester, '/does-not-exist');

      expect(find.byType(ErrorPage), findsOneWidget);
      expect(find.textContaining('Something went wrong: '), findsOneWidget);

      await unmount(tester);
    });
  });

  group('ErrorPage', () {
    testWidgets('renders a generic message without an error', (tester) async {
      await tester.pumpWidgetInShell(const ErrorPage());

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });

  group('NotFoundPage', () {
    testWidgets('renders not found text', (tester) async {
      await tester.pumpWidgetInShell(const NotFoundPage());

      expect(find.text('Page not found'), findsOneWidget);
    });
  });

  group('RouteNames helpers', () {
    test('build parameterised paths', () {
      expect(RouteNames.analyzingFor('p'), '/analysis/analyzing/p');
      expect(RouteNames.analysisResultFor('a'), '/analysis/a');
      expect(RouteNames.playlistTracksFor('p'), '/playlist/p/tracks');
      expect(RouteNames.songAnalyzingFor('t'), '/song/analyzing/t');
    });
  });
}
