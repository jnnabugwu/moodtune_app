import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/domain/entities/playlist_analysis.dart';

/// A tappable row that represents a single history entry.
///
/// Displays the mood chip, playlist/track title (truncated to 24 chars),
/// analysis date, and confidence percentage.
class HistoryRowItem extends StatelessWidget {
  const HistoryRowItem({
    required this.item,
    required this.onTap,
    super.key,
  });

  final PlaylistAnalysis item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final identity = MoodTheme.fromString(item.moodResult.primaryMood);
    final colors = MoodTheme.colorsFor(identity);
    final short = MoodTheme.shortLabel(identity);

    final rawTitle = item.playlistName;
    final title =
        rawTitle.length > 24 ? '${rawTitle.substring(0, 24)}…' : rawTitle;

    final date = DateFormat.yMMMd().format(item.createdAt);
    final confidencePct = '${(item.moodResult.confidence * 100).round()}%';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            // Mood chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                short,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),

            // Confidence
            Text(
              confidencePct,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
