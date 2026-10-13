import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_gate_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_page.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';
import 'package:moodtune_app/features/spotify/presentation/view/spotify_flow_page.dart';

import '../../../../helpers/helpers.dart';
import '../../auth_page_fixtures.dart';

void main() {
  group('AuthGatePage', () {
    for (final status in [AuthStatus.initial, AuthStatus.loading]) {
      testWidgets('shows a spinner while $status', (tester) async {
        await tester.pumpApp(
          const AuthGatePage(),
          authBloc: mockAuthBloc(AuthState(status: status)),
        );

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.byType(AuthPage), findsNothing);
      });
    }

    for (final status in [AuthStatus.unauthenticated, AuthStatus.error]) {
      testWidgets('shows AuthPage when $status', (tester) async {
        await tester.pumpApp(
          const AuthGatePage(),
          authBloc: mockAuthBloc(AuthState(status: status)),
        );

        expect(find.byType(AuthPage), findsOneWidget);
      });
    }

    testWidgets('shows SpotifyFlowPage when authenticated', (tester) async {
      // A connected Spotify state renders the profile page, which avoids the
      // connect page's deep-link plugin setup.
      await tester.pumpApp(
        const AuthGatePage(),
        authBloc: mockAuthBloc(
          const AuthState(status: AuthStatus.authenticated, user: testUser),
        ),
        spotifyBloc: mockSpotifyBloc(
          const SpotifyState(
            status: SpotifyStatus.connected,
            isConnected: true,
            profile: SpotifyProfile(
              id: 'spotify-1',
              displayName: 'Test User',
              username: 'testuser',
              followersCount: 0,
              followingCount: 0,
              playlistsCount: 0,
            ),
          ),
        ),
      );

      expect(find.byType(SpotifyFlowPage), findsOneWidget);
      expect(find.byType(AuthPage), findsNothing);
    });
  });
}
