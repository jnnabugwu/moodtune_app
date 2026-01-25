import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';

class PlaylistTracksPage extends StatefulWidget {
  const PlaylistTracksPage({
    required this.playlist,
    super.key,
  });

  final SpotifyPlaylist playlist;

  @override
  State<PlaylistTracksPage> createState() => _PlaylistTracksPageState();
}

class _PlaylistTracksPageState extends State<PlaylistTracksPage> {
  @override
  void initState() {
    super.initState();
    context.read<SpotifyBloc>().add(
      SpotifyPlaylistTracksRequested(
        playlistId: widget.playlist.id,
        limit: 50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.playlist.name),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.playlists);
            }
          },
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(CupertinoThemeData theme) {
    return BlocBuilder<SpotifyBloc, SpotifyState>(
      builder: (context, state) {
        if (state.playlistTracksLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (state.playlistTracksError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.playlistTracksError!,
                    style: theme.textTheme.textStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () {
                      context.read<SpotifyBloc>().add(
                        SpotifyPlaylistTracksRequested(
                          playlistId: widget.playlist.id,
                          limit: 50,
                        ),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final tracks = state.playlistTracks ?? [];
        if (tracks.isEmpty) {
          return Center(
            child: Text(
              'No tracks found',
              style: theme.textTheme.textStyle,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final track = tracks[index];
            final hasPreview =
                track.previewUrl != null && track.previewUrl!.isNotEmpty;
            return _TrackCard(
              track: track,
              onTap: hasPreview
                  ? () {
                      context.push(
                        RouteNames.songAnalyzingFor(track.id),
                        extra: track,
                      );
                    }
                  : null,
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemCount: tracks.length,
        );
      },
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    this.onTap,
  });

  final SpotifyTrack track;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final hasPreview = track.previewUrl != null && track.previewUrl!.isNotEmpty;
    final artistsText = track.artists.join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: hasPreview ? 1.0 : 0.5,
        child: Row(
          children: [
            if (track.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  track.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: CupertinoColors.systemGrey,
                    child: const Icon(CupertinoIcons.music_note_list),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.music_note_list),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: theme.textTheme.textStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (artistsText.isNotEmpty)
                    Text(
                      artistsText,
                      style: theme.textTheme.textStyle.copyWith(
                        color: theme.textTheme.textStyle.color?.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    'ID: ${track.id}',
                    style: theme.textTheme.textStyle.copyWith(
                      color: theme.textTheme.textStyle.color?.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
