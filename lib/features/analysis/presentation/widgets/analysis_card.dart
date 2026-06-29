import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/features/analysis/domain/entities/history_entry.dart';

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({
    required this.entry,
    this.onTap,
    super.key,
  });

  final HistoryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isSong = entry.type == HistoryEntryType.song;
    final confidencePct =
        '${(entry.confidence * 100).toStringAsFixed(0)}% confidence';
    final typeLabel = isSong ? 'Song' : 'Playlist';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title (playlist name or track name)
            Text(
              entry.title,
              style: theme.textTheme.textStyle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Artist name for songs
            if (isSong && entry.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                entry.subtitle!,
                style: theme.textTheme.textStyle.copyWith(
                  fontSize: 13,
                  color: theme.textTheme.textStyle.color?.withValues(
                    alpha: 0.6,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            // Mood label
            Text(
              entry.primaryMood,
              style: theme.textTheme.textStyle.copyWith(
                color: theme.textTheme.textStyle.color?.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Tag(confidencePct),
                _Tag(typeLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          fontSize: 12,
        ),
      ),
    );
  }
}
