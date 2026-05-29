import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/domain/entities/history_entry.dart';

/// A tappable row that represents a single history entry (playlist or song).
///
/// Displays the mood chip, title (truncated to 24 chars), artist name for
/// song entries, analysis date, and confidence percentage.
class HistoryRowItem extends StatelessWidget {
  const HistoryRowItem({
    required this.item,
    required this.onTap,
    super.key,
  });

  final HistoryEntry item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final identity = MoodTheme.fromString(item.primaryMood);
    final colors = MoodTheme.colorsFor(identity);
    final short = MoodTheme.shortLabel(identity);

    final rawTitle = item.title;
    final title =
        rawTitle.length > 24 ? '${rawTitle.substring(0, 24)}…' : rawTitle;

    final date = DateFormat.yMMMd().format(item.createdAt);
    final confidencePct = '${(item.confidence * 100).round()}%';

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

            // Title + artist (song) or date
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
                    item.subtitle != null ? item.subtitle! : date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null)
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.tertiaryLabel,
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
