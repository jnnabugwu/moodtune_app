import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';
import 'package:moodtune_app/features/spotify/presentation/widgets/widgets.dart';

class SpotifyPlaylistsPage extends StatefulWidget {
  const SpotifyPlaylistsPage({super.key});

  @override
  State<SpotifyPlaylistsPage> createState() => _SpotifyPlaylistsPageState();
}

class _SpotifyPlaylistsPageState extends State<SpotifyPlaylistsPage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<SpotifyBloc>();
    if (bloc.state.playlists == null || bloc.state.playlists!.length < 4) {
      bloc.add(const SpotifyPlaylistsRequested(limit: 50, offset: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Playlists'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.spotify);
            }
          },
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: BlocBuilder<SpotifyBloc, SpotifyState>(
          builder: (context, state) {
            final playlists = state.playlists ?? [];
            if (playlists.isEmpty && state.error != null) {
              return Center(
                child: Text(
                  state.error!,
                  style: theme.textTheme.textStyle,
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (playlists.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return PlaylistCard(playlist: playlist);
              },
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: playlists.length,
            );
          },
        ),
      ),
    );
  }
}
