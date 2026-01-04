import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_page.dart';
import 'package:moodtune_app/features/spotify/presentation/view/spotify_flow_page.dart';

class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.loading:
          case AuthStatus.initial:
            return const CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()),
            );
          case AuthStatus.authenticated:
            return const SpotifyFlowPage();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            // Default to login; router handles explicit /signup.
            return const AuthPage();
        }
      },
    );
  }
}
