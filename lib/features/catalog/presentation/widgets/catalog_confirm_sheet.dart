import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';

/// Bottom sheet that confirms before analysing a Jamendo catalog track.
///
/// Shown via [showCupertinoModalPopup]. Calls [onConfirm] when the user
/// taps "Analyse this track"; dismisses silently on "Cancel".
class CatalogConfirmSheet extends StatelessWidget {
  const CatalogConfirmSheet({
    required this.track,
    required this.onConfirm,
    super.key,
  });

  final JamendoTrack track;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final durationStr = _formatDuration(track.duration);

    return CupertinoActionSheet(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: track.albumImageUrl.isNotEmpty
                    ? Image.network(
                        track.albumImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _AlbumArtPlaceholder(),
                      )
                    : const _AlbumArtPlaceholder(),
              ),
            ),
            const SizedBox(height: 12),

            // Track name
            Text(
              track.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.label,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Artist · duration
            Text(
              '${track.artistName} · $durationStr',
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      message: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "We'll analyse the mood of this track from Jamendo's free "
            'music library.',
            textAlign: TextAlign.center,
          ),
          if (track.duration.inSeconds > 300) ...[
            const SizedBox(height: 8),
            const Text(
              'Tracks over 5 minutes — only the first 5 will be analysed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            context.pop();
            onConfirm();
          },
          child: const Text('Analyse this track'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => context.pop(),
        child: const Text('Cancel'),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _AlbumArtPlaceholder extends StatelessWidget {
  const _AlbumArtPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.tertiarySystemFill,
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.music_note,
        size: 24,
        color: CupertinoColors.tertiaryLabel,
      ),
    );
  }
}
