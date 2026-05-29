import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/app/view/splash_page.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/di/injector.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/view.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_gate_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/email_verify_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/forgot_password_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/sign_in_page.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:moodtune_app/features/catalog/presentation/view/catalog_search_page.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/presentation/view/playlist_tracks_page.dart';
import 'package:moodtune_app/features/spotify/presentation/view/playlists_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      // ── Legacy redirects ──────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        redirect: (_, _) => RouteNames.signIn,
      ),
      GoRoute(
        path: RouteNames.signup,
        redirect: (_, _) => RouteNames.signIn,
      ),
      GoRoute(
        path: RouteNames.guest,
        redirect: (_, _) => RouteNames.landing,
      ),

      // ── Guest / auth ──────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.landing,
        builder: (context, state) => const GuestPage(),
      ),
      GoRoute(
        path: RouteNames.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: RouteNames.emailVerify,
        builder: (context, state) => const EmailVerifyPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => ForgotPasswordPage(
          prefillEmail: state.extra as String? ?? '',
        ),
      ),

      // ── Authenticated home ────────────────────────────────────────────
      GoRoute(
        path: RouteNames.homeAuth,
        builder: (context, state) => const HomeAuthPage(),
      ),
      GoRoute(
        path: RouteNames.history,
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: RouteNames.catalog,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CatalogBloc>(),
          child: const CatalogSearchPage(),
        ),
      ),

      // ── Upload + analysis ─────────────────────────────────────────────
      GoRoute(
        path: RouteNames.uploadMusic,
        builder: (context, state) => const UploadMusicPage(),
      ),
      GoRoute(
        path: RouteNames.analysisLoading,
        builder: (context, state) {
          final source =
              state.extra as AnalysisSource? ?? AnalysisSource.upload;
          return AnalysisLoadingPage(source: source);
        },
      ),
      GoRoute(
        path: RouteNames.result,
        builder: (context, state) {
          final source =
              state.extra as AnalysisSource? ?? AnalysisSource.upload;
          return ResultsPage(source: source);
        },
      ),

      // ── Spotify / legacy analysis ─────────────────────────────────────
      GoRoute(
        path: RouteNames.spotify,
        builder: (context, state) => const AuthGatePage(),
      ),
      GoRoute(
        path: RouteNames.callback,
        builder: (context, state) => const AuthGatePage(),
      ),
      GoRoute(
        path: RouteNames.playlists,
        builder: (context, state) => const SpotifyPlaylistsPage(),
      ),
      GoRoute(
        path: RouteNames.playlistTracks,
        builder: (context, state) {
          final playlist = state.extra as SpotifyPlaylist?;
          if (playlist == null) {
            return const NotFoundPage();
          }
          return PlaylistTracksPage(playlist: playlist);
        },
      ),
      GoRoute(
        path: RouteNames.analyzing,
        builder: (context, state) {
          final playlistId = state.pathParameters['playlistId']!;
          final playlist = state.extra as SpotifyPlaylist?;
          return AnalyzingPage(
            playlistId: playlistId,
            playlistName: playlist?.name,
            trackCount: playlist?.tracksCount,
          );
        },
      ),
      GoRoute(
        path: RouteNames.analysisResult,
        builder: (context, state) {
          final analysisId = state.pathParameters['id']!;
          final initialAnalysis = state.extra as PlaylistAnalysis?;
          // Deep-link path: no pre-fetched data passed via extra, so
          // schedule a fetch after the frame when the widget is mounted.
          if (initialAnalysis == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              final bloc = context.read<AnalysisBloc>();
              final current = bloc.state.currentAnalysis;
              if (current == null || current.id != analysisId) {
                bloc.add(AnalysisByIdRequested(analysisId));
              }
            });
          }
          return AnalysisResultPage(
            analysisId: analysisId,
            initialAnalysis: initialAnalysis,
          );
        },
      ),
      GoRoute(
        path: RouteNames.songAnalyzing,
        builder: (context, state) {
          final trackId = state.pathParameters['trackId']!;
          final track = state.extra as SpotifyTrack?;
          return SongAnalyzingPage(
            trackId: trackId,
            track: track,
          );
        },
      ),
      GoRoute(
        path: RouteNames.songResult,
        builder: (context, state) {
          final analysis = state.extra as SongAnalysisResult?;
          if (analysis == null) {
            return const NotFoundPage();
          }
          return SongResultPage(analysis: analysis);
        },
      ),
      GoRoute(
        path: RouteNames.notFound,
        builder: (context, state) => const NotFoundPage(),
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Something went wrong${error != null ? ': $error' : ''}',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Page not found'),
    );
  }
}
