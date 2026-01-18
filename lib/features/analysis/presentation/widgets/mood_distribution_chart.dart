import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

class MoodDistributionChart extends StatelessWidget {
  const MoodDistributionChart({
    required this.distribution,
    super.key,
  });

  final MoodDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final entries = <String, double>{
      'Happy': distribution.happy,
      'Sad': distribution.sad,
      'Energetic': distribution.energetic,
      'Calm': distribution.calm,
      'Danceable': distribution.danceable,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.entries.map((entry) {
        final percent = entry.value.clamp(0, 100).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MoodBar(label: entry.key, percent: percent),
        );
      }).toList(),
    );
  }
}

class _MoodBar extends StatelessWidget {
  const _MoodBar({
    required this.label,
    required this.percent,
  });

  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.textStyle),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: theme.textTheme.textStyle.copyWith(
                color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth * (percent / 100);
              return Stack(
                children: [
                  Container(
                    height: 10,
                    width: constraints.maxWidth,
                    color: CupertinoColors.systemGrey5,
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 10,
                    width: width,
                    color: CupertinoColors.activeBlue,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
