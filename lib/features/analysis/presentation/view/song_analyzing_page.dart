import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/spotify/domain/entities/spotify_track.dart';

class SongAnalyzingPage extends StatefulWidget {
  const SongAnalyzingPage({
    required this.trackId,
    this.track,
    super.key,
  });

  final String trackId;
  final SpotifyTrack? track;

  @override
  State<SongAnalyzingPage> createState() => _SongAnalyzingPageState();
}

class _SongAnalyzingPageState extends State<SongAnalyzingPage> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      context.read<AnalysisBloc>().add(
        AnalyzeSongRequested(widget.trackId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final track = widget.track;

    return BlocListener<AnalysisBloc, AnalysisState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AnalysisStatus.success &&
            state.currentSongAnalysis != null) {
          final analysis = state.currentSongAnalysis!;
          context.go(
            RouteNames.songResult,
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
                  message: state.error ?? 'Failed to analyze song.',
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyzing song...',
                      style: theme.textTheme.navTitleTextStyle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This may take a few seconds.',
                      style: theme.textTheme.textStyle.copyWith(
                        color: theme.textTheme.textStyle.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (track != null) _TrackMeta(track: track),
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

class _TrackMeta extends StatelessWidget {
  const _TrackMeta({required this.track});

  final SpotifyTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final artistsText = track.artists.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.name,
          style: theme.textTheme.textStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        if (artistsText.isNotEmpty)
          Text(
            artistsText,
            style: theme.textTheme.textStyle.copyWith(
              color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
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
