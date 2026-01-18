import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/presentation/view/view.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_gate_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/signup_page.dart';
import 'package:moodtune_app/features/spotify/domain/entities/spotify_playlist.dart';
import 'package:moodtune_app/features/spotify/presentation/view/playlists_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.login,
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignupPage(),
      ),
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
          return AnalysisResultPage(
            analysisId: analysisId,
            initialAnalysis: initialAnalysis,
          );
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
        'Something went wrong${error != null ? ': '
                  ' $error' : ''}',
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
