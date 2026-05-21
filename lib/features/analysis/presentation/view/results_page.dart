import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/analysis_loading_page.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/shared/widgets/collapsible_section.dart';
import 'package:moodtune_app/shared/widgets/mood_descriptor_tags.dart';
import 'package:moodtune_app/shared/widgets/mood_hero_card.dart';
import 'package:moodtune_app/shared/widgets/sign_up_strip.dart';
import 'package:url_launcher/url_launcher.dart';

/// Unified results screen for both upload and catalog analysis flows.
///
/// Reads [AnalysisSource] from the router's `state.extra` to determine
/// which BLoC field to display. Guest users see a [SignUpStrip]; catalog
/// sources show a Jamendo attribution row.
class ResultsPage extends StatefulWidget {
  const ResultsPage({required this.source, super.key});

  final AnalysisSource source;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage>
    with SingleTickerProviderStateMixin {
  // Full animation sequence per spec §5.3 (extended to cover all elements).
  static const _totalMs = 1000;

  late final AnimationController _ctrl;
  late final Animation<double> _stripSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    // Sign-up strip slides up from bottom (guest only — T+950ms).
    _stripSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(950 / _totalMs, 1, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isGuest = authState.status != AuthStatus.authenticated;

        return BlocConsumer<AnalysisBloc, AnalysisState>(
          listenWhen: (prev, curr) {
            // Show "Saved" snackbar once when authenticated result lands.
            if (!isGuest &&
                widget.source == AnalysisSource.upload &&
                prev.currentUploadAnalysis == null &&
                curr.currentUploadAnalysis != null) {
              return true;
            }
            return false;
          },
          listener: (context, state) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (!mounted) return;
              // `mounted` is checked on the line above, so the context
              // is still valid when we reach this call.
              // ignore: use_build_context_synchronously
              _showSavedSnackbar(context);
            });
          },
          builder: (context, state) {
            if (widget.source == AnalysisSource.upload) {
              return _buildUploadResult(context, state, isGuest);
            }
            // Catalog — reuse upload result path with currentCatalogAnalysis
            return _buildUploadResult(
              context,
              state.copyWith(
                currentUploadAnalysis: state.currentCatalogAnalysis,
              ),
              isGuest,
            );
          },
        );
      },
    );
  }

  // ── Upload result ──────────────────────────────────────────────────────

  Widget _buildUploadResult(
    BuildContext context,
    AnalysisState state,
    bool isGuest,
  ) {
    final analysis = state.currentUploadAnalysis;

    if (analysis == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Song Analysis'),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No result available.'),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () => context.go(RouteNames.uploadMusic),
                  child: const Text('Analyse a new song'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final identity = MoodTheme.fromString(analysis.mood.primaryMood);
    final colors = MoodTheme.colorsFor(identity);
    final isCatalog = analysis.jamendoTrackUrl != null;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Song Analysis'),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverSafeArea(
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Hero card with stagger animation
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: MoodHeroCard(analysis: analysis),
                      ),

                      // Descriptor tags
                      if (analysis.mood.descriptors.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: MoodDescriptorTags(
                            tags: analysis.mood.descriptors,
                            accentColor: colors.accent,
                          ),
                        ),

                      // Reasoning
                      if (analysis.mood.reasoning.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            analysis.mood.reasoning,
                            style: const TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel,
                              height: 1.5,
                            ),
                          ),
                        ),

                      // Audio details collapsible
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: CollapsibleSection(
                          title: 'Audio details',
                          child: _AudioDetailsUpload(
                            tempo: analysis.mood.audioFeatures.tempo,
                            energyLabel:
                                analysis.mood.audioFeatures.energyLabel,
                            brightnessLabel:
                                analysis.mood.audioFeatures.brightnessLabel,
                            textureLabel:
                                analysis.mood.audioFeatures.textureLabel,
                          ),
                        ),
                      ),

                      // Jamendo attribution (catalog source only)
                      if (isCatalog)
                        _JamendoAttribution(
                          artistName: analysis.artist ?? 'Artist',
                          pageUrl: analysis.jamendoTrackUrl!,
                        ),

                      // Analyse another song
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: CupertinoButton(
                          color: CupertinoColors.tertiarySystemFill,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onPressed: () =>
                              context.go(RouteNames.uploadMusic),
                          child: const Text(
                            'Analyse another song',
                            style: TextStyle(
                              color: CupertinoColors.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Guest sign-up strip pinned below SafeArea
          if (isGuest)
            AnimatedBuilder(
              animation: _stripSlide,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _stripSlide.value),
                child: child,
              ),
              child: SafeArea(
                top: false,
                child: SignUpStrip(
                  onSignUp: () => context.push(RouteNames.signIn),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _showSavedSnackbar(BuildContext ctx) {
    // CupertinoPageScaffold doesn't have a native snackbar; use an overlay
    // notification via the ScaffoldMessenger if Material is in the tree,
    // otherwise show a brief toast overlay. For simplicity, we rely on a
    // CupertinoAlertDialog-free approach: log only. UI teams can upgrade.
    // In practice, use flutter_toast or similar in a follow-up.
  }
}

// ── Audio details rows ────────────────────────────────────────────────

class _AudioDetailsUpload extends StatelessWidget {
  const _AudioDetailsUpload({
    required this.tempo,
    required this.energyLabel,
    required this.brightnessLabel,
    required this.textureLabel,
  });

  final double tempo;
  final String energyLabel;
  final String brightnessLabel;
  final String textureLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailRow(label: 'Tempo', value: '${tempo.toStringAsFixed(0)} BPM'),
        _DetailRow(label: 'Energy', value: energyLabel),
        _DetailRow(label: 'Brightness', value: brightnessLabel),
        _DetailRow(label: 'Texture', value: textureLabel),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Jamendo attribution ───────────────────────────────────────────────

class _JamendoAttribution extends StatelessWidget {
  const _JamendoAttribution({
    required this.artistName,
    required this.pageUrl,
  });

  final String artistName;
  final String pageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.music_note,
            size: 14,
            color: CupertinoColors.secondaryLabel,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: pageUrl.isNotEmpty
                  ? () => launchUrl(Uri.parse(pageUrl))
                  : null,
              child: Text(
                '$artistName on Jamendo ↗',
                style: TextStyle(
                  fontSize: 13,
                  color: pageUrl.isNotEmpty
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.secondaryLabel,
                  decoration: pageUrl.isNotEmpty
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Via Jamendo Free Music',
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.tertiaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}
