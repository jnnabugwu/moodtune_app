import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({
    required this.analysis,
    this.onTap,
    super.key,
  });

  final PlaylistAnalysis analysis;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final mood = analysis.moodResult;

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
            Text(
              analysis.playlistName,
              style: theme.textTheme.textStyle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              mood.primaryMood,
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
                _Tag('${mood.confidence.toStringAsFixed(0)}% confidence'),
                _Tag('${mood.trackCount} tracks'),
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
