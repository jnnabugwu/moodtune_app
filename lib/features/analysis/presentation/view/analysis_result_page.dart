import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/mood_distribution_chart.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/top_track_card.dart';

class AnalysisResultPage extends StatefulWidget {
  const AnalysisResultPage({
    required this.analysisId,
    this.initialAnalysis,
    super.key,
  });

  final String analysisId;
  final PlaylistAnalysis? initialAnalysis;

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    final bloc = context.read<AnalysisBloc>();
    final current = bloc.state.currentAnalysis;
    final hasAnalysisForId = current != null && current.id == widget.analysisId;
    if (!hasAnalysisForId && widget.initialAnalysis == null) {
      _requested = true;
      bloc.add(AnalysisByIdRequested(widget.analysisId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Analysis'),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: BlocBuilder<AnalysisBloc, AnalysisState>(
          builder: (context, state) {
            final analysis = state.currentAnalysis?.id == widget.analysisId
                ? state.currentAnalysis
                : widget.initialAnalysis;

            if (analysis == null) {
              return _ResultLoading(status: state.status);
            }
            return _ResultBody(analysis: analysis);
          },
        ),
      ),
    );
  }
}

class _ResultLoading extends StatelessWidget {
  const _ResultLoading({required this.status});

  final AnalysisStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 14),
          const SizedBox(height: 12),
          Text(
            status == AnalysisStatus.error
                ? 'Failed to load analysis'
                : 'Loading analysis...',
            style: theme.textTheme.textStyle,
          ),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.analysis});

  final PlaylistAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final moodResult = analysis.moodResult;
    final descriptors = moodResult.moodDescriptors.join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            analysis.playlistName,
            style: theme.textTheme.navTitleTextStyle,
          ),
          Text(
            '${moodResult.trackCount} tracks analyzed',
            style: theme.textTheme.textStyle.copyWith(
              color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Mood',
                  style: theme.textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  moodResult.primaryMood,
                  style: theme.textTheme.navTitleTextStyle,
                ),
                const SizedBox(height: 6),
                Text(
                  'Confidence: ${moodResult.confidence.toStringAsFixed(1)}%',
                  style: theme.textTheme.textStyle,
                ),
                const SizedBox(height: 6),
                if (descriptors.isNotEmpty)
                  Text(
                    descriptors,
                    style: theme.textTheme.textStyle.copyWith(
                      color: theme.textTheme.textStyle.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood Distribution',
                  style: theme.textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                MoodDistributionChart(
                  distribution: moodResult.moodDistribution,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Tracks',
                  style: theme.textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...moodResult.topTracks.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TopTrackCard(track: t),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Averages',
                  style: theme.textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _AverageRow(
                  label: 'Valence',
                  value: moodResult.averages.valence,
                ),
                _AverageRow(
                  label: 'Energy',
                  value: moodResult.averages.energy,
                ),
                _AverageRow(
                  label: 'Danceability',
                  value: moodResult.averages.danceability,
                ),
                _AverageRow(
                  label: 'Tempo',
                  value: moodResult.averages.tempo,
                  unit: ' BPM',
                  isPercent: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Created ${analysis.createdAt}',
            style: theme.textTheme.textStyle.copyWith(
              color: theme.textTheme.textStyle.color?.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _AverageRow extends StatelessWidget {
  const _AverageRow({
    required this.label,
    required this.value,
    this.unit = '%',
    this.isPercent = true,
  });

  final String label;
  final double value;
  final String unit;
  final bool isPercent;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final displayValue = isPercent
        ? (value * 100).toStringAsFixed(1)
        : value.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.textStyle),
          Text(
            '$displayValue$unit',
            style: theme.textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
