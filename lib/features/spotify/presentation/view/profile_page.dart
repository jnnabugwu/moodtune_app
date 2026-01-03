import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';
import 'package:moodtune_app/features/spotify/presentation/widgets/widgets.dart';

class SpotifyProfilePage extends StatelessWidget {
  const SpotifyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpotifyBloc, SpotifyState>(
      builder: (context, state) {
        final profile = state.profile;
        if (profile == null) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Spotify Profile'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: () => context.read<SpotifyBloc>().add(
                const SpotifyDisconnectRequested(),
              ),
              child: const Icon(CupertinoIcons.square_arrow_left),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpotifyProfileHeader(profile: profile),
                  const SizedBox(height: 24),
                  _CountsRow(profile: profile),
                  const SizedBox(height: 32),
                  Text(
                    'No recent activity.',
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check out some new music now.',
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountsRow extends StatelessWidget {
  const _CountsRow({required this.profile});

  final SpotifyProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCard(label: 'Followers', value: profile.followersCount),
        _StatCard(label: 'Following', value: profile.followingCount),
        _StatCard(label: 'Playlists', value: profile.playlistsCount),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.navTitleTextStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.textStyle.copyWith(
            color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
