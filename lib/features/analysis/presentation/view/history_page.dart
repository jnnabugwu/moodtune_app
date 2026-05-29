import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/shared/widgets/analysis_source_sheet.dart';
import 'package:moodtune_app/shared/widgets/history_row_item.dart';
import 'package:moodtune_app/shared/widgets/mood_chip.dart';

/// Full history screen — shows the user's 50 most recent analyses with
/// in-memory mood chip filtering.
///
/// [isEmbedded] — when true (used inside the home tab scaffold) the
/// navigation bar back button is hidden and history is loaded via the
/// ambient [AnalysisBloc]; when false the page is a standalone push route.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  /// Null means "All" (no filter active).
  String? _selectedMood;

  static const List<
    ({String label, MoodIdentity identity, String? value})
  > _moodFilters = [
    (label: 'All', identity: MoodIdentity.upbeat, value: null),
    (label: 'Upbeat', identity: MoodIdentity.upbeat, value: 'upbeat'),
    (label: 'Serene', identity: MoodIdentity.serene, value: 'serene'),
    (label: 'Charged', identity: MoodIdentity.charged, value: 'charged'),
    (
      label: 'Reflective',
      identity: MoodIdentity.reflective,
      value: 'reflective',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Only fetch if not already loaded (embedded tab shares AnalysisBloc
    // with HomeTab which may have already triggered a load).
    final bloc = context.read<AnalysisBloc>();
    if (bloc.state.history.isEmpty && !bloc.state.historyLoading) {
      bloc.add(const AnalysisHistoryRequested());
    }
  }

  void _applyFilter(String? mood) {
    setState(() => _selectedMood = mood);
    context
        .read<AnalysisBloc>()
        .add(AnalysisHistoryFilterChanged(mood));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('My History'),
        // Hide the automatic back button when embedded in a tab scaffold.
        leading: widget.isEmbedded ? const SizedBox.shrink() : null,
      ),
      child: SafeArea(
        child: BlocBuilder<AnalysisBloc, AnalysisState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood chip filter row
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
                      final isAll = filter.value == null;
                      final isSelected = isAll
                          ? _selectedMood == null
                          : _selectedMood == filter.value;

                      // "All" chip uses a neutral style.
                      if (isAll) {
                        return GestureDetector(
                          onTap: () => _applyFilter(null),
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
                        onTap: () => _applyFilter(
                          isSelected ? null : filter.value,
                        ),
                      );
                    },
                  ),
                ),

                // List / empty / loading states
                Expanded(
                  child: _buildBody(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AnalysisState state) {
    if (state.historyLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (state.historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 48,
                color: CupertinoColors.destructiveRed,
              ),
              const SizedBox(height: 12),
              Text(
                state.historyError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: () => context
                    .read<AnalysisBloc>()
                    .add(const AnalysisHistoryRequested()),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final items = state.filteredHistory;

    if (items.isEmpty) {
      return _EmptyState(
        hasFilter: _selectedMood != null,
        onAnalyse: () => showAnalysisSourceSheet(context),
        onClearFilter: () => _applyFilter(null),
      );
    }

    return ListView.builder(
      itemCount: items.length + (items.length >= 50 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          // Cap footnote
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Showing your 50 most recent analyses.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.tertiaryLabel,
              ),
            ),
          );
        }

        return HistoryRowItem(
          item: items[index],
          onTap: () {},
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasFilter,
    required this.onAnalyse,
    required this.onClearFilter,
  });

  final bool hasFilter;
  final VoidCallback onAnalyse;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.waveform,
              size: 64,
              color: CupertinoColors.tertiaryLabel,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'No analyses match this filter.'
                  : 'Nothing here yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 8),
            if (hasFilter)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onClearFilter,
                child: const Text('Clear filter'),
              )
            else
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                onPressed: onAnalyse,
                child: const Text('Analyse a song'),
              ),
          ],
        ),
      ),
    );
  }
}
