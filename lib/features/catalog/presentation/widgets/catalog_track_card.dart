import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';

/// A compact list tile representing a single Jamendo track.
///
/// Shows a 48×48 album art thumbnail, track name, artist + duration,
/// up to two tag pills, and an "Analyze →" pill button that triggers
/// [onAnalyzeTap].
class CatalogTrackCard extends StatelessWidget {
  const CatalogTrackCard({
    required this.track,
    required this.onAnalyzeTap,
    super.key,
  });

  final JamendoTrack track;
  final VoidCallback onAnalyzeTap;

  @override
  Widget build(BuildContext context) {
    final durationStr = _formatDuration(track.duration);
    final displayTags = track.tags.take(2).toList();
    final truncatedName = track.name.length > 28
        ? '${track.name.substring(0, 28)}…'
        : track.name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Album art thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: track.albumImageUrl.isNotEmpty
                  ? Image.network(
                      track.albumImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _AlbumArtPlaceholder(),
                    )
                  : const _AlbumArtPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),

          // Track info + tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  truncatedName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${track.artistName} · $durationStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (displayTags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (final tag in displayTags) ...[
                        _TagPill(tag: tag),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Analyze button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(20),
            minimumSize: const Size(0, 32),
            onPressed: onAnalyzeTap,
            child: const Text(
              'Analyze →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────

class _AlbumArtPlaceholder extends StatelessWidget {
  const _AlbumArtPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.tertiarySystemFill,
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.music_note,
        size: 20,
        color: CupertinoColors.tertiaryLabel,
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 10,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }
}
