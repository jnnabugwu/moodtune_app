import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/analysis_card.dart';
import 'package:moodtune_app/features/analysis/presentation/widgets/analysis_disclaimer_sheet.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';
import 'package:moodtune_app/features/spotify/presentation/widgets/widgets.dart';

class SpotifyProfilePage extends StatefulWidget {
  const SpotifyProfilePage({super.key});

  @override
  State<SpotifyProfilePage> createState() => _SpotifyProfilePageState();
}

class _SpotifyProfilePageState extends State<SpotifyProfilePage> {
  bool _requestedHistory = false;

  @override
  Widget build(BuildContext context) {
    if (!_requestedHistory) {
      _requestedHistory = true;
      context.read<AnalysisBloc>().add(
        const AnalysisHistoryRequested(limit: 3, offset: 0),
      );
    }

    return BlocBuilder<SpotifyBloc, SpotifyState>(
      builder: (context, state) {
        final profile = state.profile;
        final playlists = state.playlists ?? [];
        if (profile == null) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Spotify Profile'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: () => context.read<SpotifyBloc>().add(
                const SpotifyDisconnectRequested(),
              ),
              child: const Icon(CupertinoIcons.power),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpotifyProfileHeader(profile: profile),
                  const SizedBox(height: 24),
                  _CountsRow(profile: profile),
                  const SizedBox(height: 32),
                  _RecentAnalyses(),
                  const SizedBox(height: 16),
                  if (playlists.isNotEmpty) ...[
                    Text(
                      'Playlists',
                      style: CupertinoTheme.of(context).textTheme.textStyle
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: playlists
                          .take(3)
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PlaylistCard(
                                playlist: p,
                                onTap: () async {
                                  final confirmed =
                                      await showAnalysisDisclaimerSheet(
                                        context,
                                      );
                                  if (confirmed == true) {
                                    context.push(
                                      RouteNames.analyzingFor(p.id),
                                      extra: p,
                                    );
                                  }
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => context.go(RouteNames.playlists),
                        child: const Text('See all playlists'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountsRow extends StatelessWidget {
  const _CountsRow({required this.profile});

  final SpotifyProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCard(label: 'Followers', value: profile.followersCount),
        _StatCard(label: 'Following', value: profile.followingCount),
        _StatCard(label: 'Playlists', value: profile.playlistsCount),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.navTitleTextStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.textStyle.copyWith(
            color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _RecentAnalyses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return BlocBuilder<AnalysisBloc, AnalysisState>(
      builder: (context, state) {
        if (state.historyLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state.history.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Analyses',
              style: theme.textTheme.textStyle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ...state.history.map(
              (analysis) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnalysisCard(
                  analysis: analysis,
                  onTap: () => context.go(
                    RouteNames.analysisResultFor(analysis.id),
                    extra: analysis,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
