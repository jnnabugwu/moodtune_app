import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/history_page.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/shared/widgets/analysis_source_sheet.dart';
import 'package:moodtune_app/shared/widgets/history_row_item.dart';

/// Authenticated home shell — two-tab layout (Home + History).
///
/// Dispatches [AnalysisHistoryRequested] on first build so the Home tab's
/// "Recent analyses" section is populated immediately.
class HomeAuthPage extends StatelessWidget {
  const HomeAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock),
            label: 'History',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return switch (index) {
          0 => const _HomeTab(),
          _ => const HistoryPage(isEmbedded: true),
        };
      },
    );
  }
}

// ── Home tab ─────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    // Load recent history on mount so the 3-item preview is populated.
    context.read<AnalysisBloc>().add(const AnalysisHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final email = authState.user?.email ?? '';
        final initials = _initials(email);

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text(
              'MoodTune',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            trailing: GestureDetector(
              onTap: () => _showSignOutSheet(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              children: [
                // Upload card
                _ActionCard(
                  icon: CupertinoIcons.music_note,
                  title: 'Analyze a new song',
                  subtitle: 'Tap to upload a file',
                  isPrimary: true,
                  onTap: () => context.push(RouteNames.uploadMusic),
                ),
                const SizedBox(height: 12),

                // Catalog card
                _ActionCard(
                  icon: CupertinoIcons.square_grid_2x2,
                  title: 'Browse the catalog',
                  subtitle: 'Explore free music',
                  isPrimary: false,
                  onTap: () => context.push(RouteNames.catalog),
                ),
                const SizedBox(height: 24),

                // Recent analyses
                const Text(
                  'Recent analyses',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 8),

                BlocBuilder<AnalysisBloc, AnalysisState>(
                  builder: (context, state) {
                    if (state.historyLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CupertinoActivityIndicator(),
                      );
                    }

                    final recent = state.history.take(3).toList();

                    if (recent.isEmpty) {
                      return _EmptyHistoryState(
                        onAnalyze: () => showAnalysisSourceSheet(context),
                      );
                    }

                    return Column(
                      children: [
                        for (final item in recent)
                          HistoryRowItem(
                            item: item,
                            onTap: () {},
                          ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            // Switch to History tab (index 1).
                            // CupertinoTabScaffold doesn't expose a
                            // controller from BuildContext, so navigate
                            // via route instead.
                            context.push(RouteNames.history);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'See all history',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.activeBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 12,
                                  color: CupertinoColors.activeBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns up to two capitalised initials from an email address.
  String _initials(String email) {
    if (email.isEmpty) return '?';
    final local = email.split('@').first;
    final parts = local.split(RegExp(r'[._\-]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return local.substring(0, local.length.clamp(1, 2)).toUpperCase();
  }

  void _showSignOutSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              context.pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: const Text('Sign out'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ── Action cards ──────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isPrimary
              ? CupertinoColors.activeBlue.withAlpha(20)
              : CupertinoColors.tertiarySystemFill,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? Border.all(
                  color: CupertinoColors.activeBlue.withAlpha(60),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPrimary
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.secondarySystemFill,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 22,
                color: isPrimary
                    ? CupertinoColors.white
                    : CupertinoColors.label,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isPrimary
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: isPrimary
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty history state ────────────────────────────────────────────────

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.onAnalyze});

  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.waveform,
            size: 48,
            color: CupertinoColors.tertiaryLabel,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your past analyses will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            color: CupertinoColors.tertiarySystemFill,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            onPressed: onAnalyze,
            child: const Text(
              'Analyze your first song →',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
