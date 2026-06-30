import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/analysis_loading_page.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:moodtune_app/features/catalog/presentation/widgets/catalog_confirm_sheet.dart';
import 'package:moodtune_app/features/catalog/presentation/widgets/catalog_track_card.dart';
import 'package:moodtune_app/shared/widgets/mood_chip.dart';

/// Catalog search screen — full-text search + mood chip filter over
/// the Jamendo free-music library.
///
/// Requires [CatalogBloc] in the widget tree (provided via [BlocProvider]
/// in the router).
class CatalogSearchPage extends StatefulWidget {
  const CatalogSearchPage({super.key});

  @override
  State<CatalogSearchPage> createState() => _CatalogSearchPageState();
}

class _CatalogSearchPageState extends State<CatalogSearchPage> {
  final _searchController = TextEditingController();
  String? _selectedMood;

  static const List<({String label, MoodIdentity identity, String? tag})>
  _moodFilters = [
    (label: 'All', identity: MoodIdentity.upbeat, tag: null),
    (label: 'Upbeat', identity: MoodIdentity.upbeat, tag: 'upbeat'),
    (label: 'Serene', identity: MoodIdentity.serene, tag: 'serene'),
    (label: 'Charged', identity: MoodIdentity.charged, tag: 'charged'),
    (
      label: 'Reflective',
      identity: MoodIdentity.reflective,
      tag: 'reflective',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search({String? query, String? moodTag}) {
    context.read<CatalogBloc>().add(
      CatalogSearchRequested(
        query: query ?? _searchController.text,
        moodTag: moodTag ?? _selectedMood,
      ),
    );
  }

  void _selectMood(String? tag) {
    setState(() => _selectedMood = tag);
    _search(moodTag: tag);
  }

  void _showConfirmSheet(BuildContext context, JamendoTrack track) {
    // Resolve the BLoC and router eagerly, before the modal opens.
    // The onConfirm closure runs after the sheet is dismissed (context
    // deactivated), so capturing `context` directly would throw
    // "Looking up a deactivated widget's ancestor is unsafe".
    final analysisBloc = context.read<AnalysisBloc>();
    final router = GoRouter.of(context);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CatalogConfirmSheet(
        track: track,
        onConfirm: () {
          analysisBloc.add(
            CatalogTrackAnalyzeRequested(
              audioUrl: track.audioUrl,
              trackId: track.id,
              trackName: track.name,
              artistName: track.artistName,
              jamendoPageUrl: track.jamendoPageUrl,
            ),
          );
          router.push(
            RouteNames.analysisLoading,
            extra: AnalysisLoadingArgs(
              source: AnalysisSource.catalog,
              trackDurationSeconds: track.duration.inSeconds,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Browse Catalog'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search tracks or artists…',
                autofocus: true,
                onChanged: (query) => _search(query: query),
                onSubmitted: (query) => _search(query: query),
              ),
            ),

            // Mood chip row
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: _moodFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final filter = _moodFilters[i];
                  final isAll = filter.tag == null;
                  final isSelected = isAll
                      ? _selectedMood == null
                      : _selectedMood == filter.tag;

                  if (isAll) {
                    return GestureDetector(
                      onTap: () => _selectMood(null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.tertiarySystemFill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.separator,
                          ),
                        ),
                        child: Text(
                          filter.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? CupertinoColors.white
                                : CupertinoColors.label,
                          ),
                        ),
                      ),
                    );
                  }

                  return MoodChip(
                    label: filter.label,
                    mood: filter.identity,
                    isSelected: isSelected,
                    onTap: () => _selectMood(isSelected ? null : filter.tag),
                  );
                },
              ),
            ),

            // Results / states
            Expanded(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) => switch (state) {
                  CatalogInitial() => const _EmptyPrompt(),
                  CatalogLoading() => const _ShimmerList(),
                  CatalogLoaded(:final tracks) when tracks.isEmpty =>
                    _NoResults(query: _searchController.text),
                  CatalogLoaded(:final tracks) => ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, i) => CatalogTrackCard(
                      track: tracks[i],
                      onAnalyzeTap: () => _showConfirmSheet(context, tracks[i]),
                    ),
                  ),
                  CatalogError() => _ApiError(onRetry: _search),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── State sub-widgets ──────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Search for a track or pick a mood to explore.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ),
    );
  }
}

/// Three placeholder shimmer cards shown while results are loading.
class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (_, _) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemFill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemFill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          query.isNotEmpty
              ? "No tracks found for '$query'.\n"
                    'Try different keywords or clear the mood filter.'
              : 'No tracks match this mood.\nTry clearing the filter.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ApiError extends StatelessWidget {
  const _ApiError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Couldn't reach the catalog right now.",
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
