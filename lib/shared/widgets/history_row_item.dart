import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

/// A tappable row that represents a single history entry (playlist or song).
///
/// Displays the mood chip, title (truncated to 24 chars), artist name for
/// song entries, analysis date, and confidence percentage when there is one.
/// With [showComparison], results saved with both engines' moods also show
/// a line comparing them.
class HistoryRowItem extends StatelessWidget {
  const HistoryRowItem({
    required this.item,
    required this.onTap,
    this.showComparison = false,
    super.key,
  });

  final HistoryEntry item;
  final VoidCallback onTap;
  final bool showComparison;

  @override
  Widget build(BuildContext context) {
    final identity = MoodTheme.fromString(item.primaryMood);
    final colors = MoodTheme.colorsFor(identity);
    final short = MoodTheme.shortLabel(identity);

    final rawTitle = item.title;
    final title = rawTitle.length > 24
        ? '${rawTitle.substring(0, 24)}…'
        : rawTitle;

    final date = DateFormat.yMMMd().format(item.createdAt);
    final confidence = item.confidence;
    final comparison = showComparison ? item.comparison : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            // Mood chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  if (comparison != null) _ComparisonLine(comparison),
                ],
              ),
            ),

            // Confidence (on-device results have none to show)
            if (confidence != null)
              Text(
                '${(confidence * 100).round()}%',
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

/// "On-device SERENE · Backend UPBEAT", a match mark, and the user's answer
/// with the engine it's about: "· 👎 on-device, picked REFLECTIVE".
class _ComparisonLine extends StatelessWidget {
  const _ComparisonLine(this.comparison);

  final EngineComparison comparison;

  @override
  Widget build(BuildContext context) {
    final onDevice = comparison.onDeviceMood;
    final backend = MoodTheme.fromString(comparison.backendMood);
    final match = onDevice != null && MoodTheme.fromString(onDevice) == backend;
    // Name the engine the answer is about (the one that was shown) and, on
    // a thumbs-down, the mood the user picked instead.
    final shown = comparison.displayedSource == MoodSource.onDevice
        ? 'on-device'
        : 'backend';
    final userMood = comparison.userMood;
    final picked = userMood == null
        ? ''
        : ', picked ${MoodTheme.shortLabel(MoodTheme.fromString(userMood))}';
    final answer = switch (comparison.agrees) {
      true => ' · 👍 $shown',
      false => ' · 👎 $shown$picked',
      null => '',
    };
    final text = onDevice == null
        ? 'Backend ${MoodTheme.shortLabel(backend)} · on-device didn’t run'
        : 'On-device ${MoodTheme.shortLabel(MoodTheme.fromString(onDevice))}'
              ' · Backend ${MoodTheme.shortLabel(backend)}';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          if (onDevice != null) ...[
            Icon(
              match
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.xmark_circle_fill,
              size: 12,
              color: match
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemOrange,
              semanticLabel: match ? 'Engines agree' : 'Engines disagree',
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              '$text$answer',
              style: const TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
