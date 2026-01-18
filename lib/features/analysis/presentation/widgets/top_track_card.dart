import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

class TopTrackCard extends StatelessWidget {
  const TopTrackCard({
    required this.track,
    super.key,
  });

  final TrackAnalysis track;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final artists = track.artists.join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            track.trackName,
            style: theme.textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artists,
            style: theme.textTheme.textStyle.copyWith(
              color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Tag('Mood: ${track.moodLabel}'),
              _Tag('Energy ${(track.energy * 100).round()}%'),
              _Tag('Valence ${(track.valence * 100).round()}%'),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(6),
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
