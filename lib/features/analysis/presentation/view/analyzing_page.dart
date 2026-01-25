import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';

class AnalyzingPage extends StatefulWidget {
  const AnalyzingPage({
    required this.playlistId,
    this.playlistName,
    this.trackCount,
    this.limit = 50,
    super.key,
  });

  final String playlistId;
  final String? playlistName;
  final int? trackCount;
  final int limit;

  @override
  State<AnalyzingPage> createState() => _AnalyzingPageState();
}

class _AnalyzingPageState extends State<AnalyzingPage> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      context.read<AnalysisBloc>().add(
        AnalyzePlaylistRequested(
          playlistId: widget.playlistId,
          limit: widget.limit,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final steps = [
      _AnalysisStep('Fetching tracks'),
      _AnalysisStep('Analyzing mood'),
      _AnalysisStep('Generating results'),
    ];

    return BlocListener<AnalysisBloc, AnalysisState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AnalysisStatus.success &&
            state.currentAnalysis != null) {
          final analysis = state.currentAnalysis!;
          context.go(
            RouteNames.analysisResultFor(analysis.id),
            extra: analysis,
          );
        }
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Analyzing'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<AnalysisBloc, AnalysisState>(
            builder: (context, state) {
              if (state.status == AnalysisStatus.error) {
                return _AnalysisError(
                  message: state.error ?? 'Failed to analyze playlist.',
                );
              }

              final activeStep = switch (state.status) {
                AnalysisStatus.analyzing => 2,
                AnalysisStatus.success => 3,
                _ => 1,
              };

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyzing your playlist...',
                      style: theme.textTheme.navTitleTextStyle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This may take a few seconds depending on playlist size.',
                      style: theme.textTheme.textStyle.copyWith(
                        color: theme.textTheme.textStyle.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PlaylistMeta(
                      name: widget.playlistName ?? 'Playlist',
                      trackCount: widget.trackCount,
                      limit: widget.limit,
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          const CupertinoActivityIndicator(radius: 14),
                          const SizedBox(height: 12),
                          Text(
                            'Working on it...',
                            style: theme.textTheme.textStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...List.generate(steps.length, (index) {
                      final step = steps[index];
                      final isActive = index < activeStep;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? CupertinoIcons.check_mark_circled_solid
                                  : CupertinoIcons.circle,
                              size: 20,
                              color: isActive
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.inactiveGray,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              step.label,
                              style: theme.textTheme.textStyle,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlaylistMeta extends StatelessWidget {
  const _PlaylistMeta({
    required this.name,
    required this.trackCount,
    required this.limit,
  });

  final String name;
  final int? trackCount;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: theme.textTheme.textStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        if (trackCount != null)
          Text(
            '$trackCount songs (up to $limit analyzed)',
            style: theme.textTheme.textStyle.copyWith(
              color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
            ),
          )
        else
          Text(
            'Analyzing up to $limit tracks',
            style: theme.textTheme.textStyle.copyWith(
              color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
}

class _AnalysisStep {
  _AnalysisStep(this.label);
  final String label;
}

class _AnalysisError extends StatelessWidget {
  const _AnalysisError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: theme.textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.textStyle,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () => context.pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
