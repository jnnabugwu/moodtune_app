import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';

class GuestPage extends StatelessWidget {
  const GuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Choose Music Source'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Analyze a song mood',
                style: theme.textTheme.navTitleTextStyle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Upload a local file or connect Spotify to pick from playlists.',
                style: theme.textTheme.textStyle.copyWith(
                  color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: () => context.go(RouteNames.uploadMusic),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Text('Upload a song'),
              ),
              const SizedBox(height: 12),
              CupertinoButton.filled(
                onPressed: () => context.go(RouteNames.spotify),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Text('Connect Spotify'),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () => context.go(RouteNames.login),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
