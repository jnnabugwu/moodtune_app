import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/features/spotify/domain/entities/spotify_playlist.dart';

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    required this.playlist,
    super.key,
  });

  final SpotifyPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Artwork(imageUrl: playlist.imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playlist.name,
                style: theme.textTheme.textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (playlist.ownerDisplayName != null)
                Text(
                  playlist.ownerDisplayName!,
                  style: theme.textTheme.textStyle.copyWith(
                    color: theme.textTheme.textStyle.color?.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: 56,
        height: 56,
        color: CupertinoColors.systemGrey6,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
              )
            : const Icon(
                CupertinoIcons.music_note_list,
                size: 28,
                color: CupertinoColors.systemGrey,
              ),
      ),
    );
  }
}
