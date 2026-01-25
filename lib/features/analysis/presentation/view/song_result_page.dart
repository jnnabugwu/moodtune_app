import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/domain/entities/song_analysis_result.dart';

class SongResultPage extends StatelessWidget {
  const SongResultPage({
    required this.analysis,
    super.key,
  });

  final SongAnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    final mood = analysis.mood;
    final features = analysis.features;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Song Analysis'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.spotify);
            }
          },
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SongHeader(
              trackName: analysis.trackName,
              artistName: analysis.artistName,
            ),
            const SizedBox(height: 24),
            _MoodCard(mood: mood),
            const SizedBox(height: 16),
            _FeaturesCard(features: features),
          ],
        ),
      ),
    );
  }
}

class _SongHeader extends StatelessWidget {
  const _SongHeader({
    required this.trackName,
    required this.artistName,
  });

  final String trackName;
  final String artistName;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trackName,
          style: theme.textTheme.navTitleTextStyle.copyWith(
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          artistName,
          style: theme.textTheme.textStyle.copyWith(
            color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood});

  final SongMoodResult mood;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood',
            style: theme.textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood.primaryMood.toUpperCase(),
                      style: theme.textTheme.textStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                    '${(mood.confidence * 100).toStringAsFixed(0)}% confidence',
                      style: theme.textTheme.textStyle.copyWith(
                        color: theme.textTheme.textStyle.color?.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard({required this.features});

  final SongAudioFeatures features;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audio Features',
            style: theme.textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _FeatureRow(
            label: 'Tempo',
            value: '${features.tempo.toStringAsFixed(0)} BPM',
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            label: 'Energy',
            value: features.energy.toStringAsFixed(2),
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            label: 'Valence',
            value: features.valence.toStringAsFixed(2),
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            label: 'Danceability',
            value: features.danceability.toStringAsFixed(2),
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            label: 'Loudness',
            value: '${features.loudness.toStringAsFixed(1)} dB',
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.textStyle.copyWith(
            color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.textStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
