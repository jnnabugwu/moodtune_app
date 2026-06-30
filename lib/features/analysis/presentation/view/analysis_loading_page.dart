import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/shared/widgets/animated_waveform.dart';

/// Distinguishes the source of the current analysis so the loading screen
/// knows which BLoC state fields to watch.
enum AnalysisSource { upload, catalog }

/// Navigation arguments for [AnalysisLoadingPage].
///
/// Pass this as `extra` when pushing [RouteNames.analysisLoading].
class AnalysisLoadingArgs {
  const AnalysisLoadingArgs({
    required this.source,
    this.trackDurationSeconds,
  });

  final AnalysisSource source;

  /// Known or estimated track duration in seconds.
  ///
  /// When > 240 (4 min) the 35-second timeout UI is suppressed — the page
  /// waits for a BLoC success/error instead and stays pinned to the last
  /// phase message.
  final int? trackDurationSeconds;
}

/// Full-screen loading experience shown while a track is being analyzed.
///
/// Cycles through phase messages every 5 seconds, reveals a blurred ghost
/// result card at ~28 s, and surfaces a timeout UI at 35 s. Listens to
/// [AnalysisBloc] for errors and success, then navigates automatically.
class AnalysisLoadingPage extends StatefulWidget {
  const AnalysisLoadingPage({
    required this.source,
    this.trackDurationSeconds,
    super.key,
  });

  /// Whether the analysis originated from a file upload or Jamendo catalog.
  final AnalysisSource source;

  /// Known or estimated track duration in seconds.
  ///
  /// When > 240 (4 min) the timeout UI is suppressed so long tracks don't
  /// falsely surface "taking longer than expected."
  final int? trackDurationSeconds;

  @override
  State<AnalysisLoadingPage> createState() => _AnalysisLoadingPageState();
}

class _AnalysisLoadingPageState extends State<AnalysisLoadingPage> {
  static const _timeoutSecs = 35;
  static const _blurRevealSecs = 28;
  static const _phaseIntervalSecs = 5;

  int _currentPhase = 0;
  int _elapsedSecs = 0;
  bool _blurVisible = false;
  bool _timedOut = false;

  Timer? _phaseTimer;
  Timer? _timeoutTimer;

  // ── Phase messages ──────────────────────────────────────────────────

  static const List<String> _uploadPhases = [
    'Uploading your track…',
    'Listening to the rhythm…',
    'Reading the energy…',
    'Feeling the texture…',
    'Finding the mood…',
    'Almost there…',
  ];

  static const List<String> _catalogPhases = [
    'Fetching the track…',
    'Listening to the rhythm…',
    'Reading the energy…',
    'Feeling the texture…',
    'Finding the mood…',
    'Almost there…',
  ];

  List<String> get _phases =>
      widget.source == AnalysisSource.upload ? _uploadPhases : _catalogPhases;

  // ── Computed ─────────────────────────────────────────────────────────

  /// True when the track is longer than 4 minutes.
  ///
  /// Long tracks skip the timeout UI — the last phase stays pinned until
  /// the BLoC emits success or error.
  bool get _isLongTrack => (widget.trackDurationSeconds ?? 0) > 240;

  // ── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() {
    _phaseTimer?.cancel();
    _timeoutTimer?.cancel();

    _phaseTimer = Timer.periodic(
      const Duration(seconds: _phaseIntervalSecs),
      (_) {
        if (!mounted) return;
        setState(() {
          _elapsedSecs += _phaseIntervalSecs;
          if (_currentPhase < _phases.length - 1) _currentPhase++;
          if (_elapsedSecs >= _blurRevealSecs) _blurVisible = true;
        });
      },
    );

    // For tracks longer than 4 min, skip the timeout UI entirely.
    // The BLoC error state handles genuine backend failures, and Dio's own
    // receive timeout (90 s) acts as the hard ceiling.
    if (!_isLongTrack) {
      _timeoutTimer = Timer(
        const Duration(seconds: _timeoutSecs),
        () {
          if (!mounted) return;
          _phaseTimer?.cancel();
          setState(() => _timedOut = true);
        },
      );
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────

  void _cancel() {
    final dest = widget.source == AnalysisSource.upload
        ? RouteNames.uploadMusic
        : RouteNames.catalog;
    context.go(dest);
  }

  void _retry() {
    setState(() {
      _timedOut = false;
      _currentPhase = 0;
      _elapsedSecs = 0;
      _blurVisible = false;
    });
    _startTimers();
  }

  // ── Error helpers ───────────────────────────────────────────────────

  bool _isRateLimit(String msg) =>
      msg.toLowerCase().contains('rate') ||
      msg.toLowerCase().contains('limit') ||
      msg.toLowerCase().contains('429');

  bool _isOffline(String msg) =>
      msg.toLowerCase().contains('offline') ||
      msg.toLowerCase().contains('network') ||
      msg.toLowerCase().contains('socket') ||
      msg.toLowerCase().contains('connection');

  String _errorTitle(String msg) {
    if (_isOffline(msg)) return 'Looks like you went offline.';
    if (_isRateLimit(msg)) return "You've done a lot of listening today.";
    return "Something went wrong. It's not your file — try again.";
  }

  IconData _errorIcon(String msg) {
    if (_isOffline(msg)) return CupertinoIcons.bolt_slash_fill;
    if (_isRateLimit(msg)) return CupertinoIcons.timer;
    return CupertinoIcons.xmark_circle_fill;
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnalysisBloc, AnalysisState>(
      listener: (context, state) {
        // Upload success → navigate to result
        if (widget.source == AnalysisSource.upload &&
            state.uploadStatus == UploadStatus.success &&
            state.currentUploadAnalysis != null) {
          _phaseTimer?.cancel();
          _timeoutTimer?.cancel();
          context.go(RouteNames.result, extra: AnalysisSource.upload);
          return;
        }
        // Catalog success → navigate to result
        if (widget.source == AnalysisSource.catalog &&
            state.catalogStatus == CatalogAnalysisStatus.success &&
            state.currentCatalogAnalysis != null) {
          _phaseTimer?.cancel();
          _timeoutTimer?.cancel();
          context.go(RouteNames.result, extra: AnalysisSource.catalog);
        }
      },
      child: BlocBuilder<AnalysisBloc, AnalysisState>(
        builder: (context, state) {
          final hasUploadError =
              widget.source == AnalysisSource.upload &&
              state.uploadStatus == UploadStatus.error &&
              state.uploadError != null;
          final hasCatalogError =
              widget.source == AnalysisSource.catalog &&
              state.catalogStatus == CatalogAnalysisStatus.error &&
              state.catalogError != null;
          final hasError = hasUploadError || hasCatalogError;
          final errorMsg = widget.source == AnalysisSource.upload
              ? (state.uploadError ?? '')
              : (state.catalogError ?? '');

          return CupertinoPageScaffold(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Cancel button top-right
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _cancel,
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),

                    const Spacer(),

                    if (hasError)
                      _ErrorState(
                        icon: _errorIcon(errorMsg),
                        title: _errorTitle(errorMsg),
                        isRateLimit: _isRateLimit(errorMsg),
                        onRetry: _retry,
                        onCancel: _cancel,
                      )
                    else if (_timedOut)
                      _TimeoutState(onRetry: _retry, onCancel: _cancel)
                    else
                      _ActiveState(
                        phases: _phases,
                        currentPhase: _currentPhase,
                        blurVisible: _blurVisible,
                      ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Active loading state ──────────────────────────────────────────────

class _ActiveState extends StatelessWidget {
  const _ActiveState({
    required this.phases,
    required this.currentPhase,
    required this.blurVisible,
  });

  final List<String> phases;
  final int currentPhase;
  final bool blurVisible;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Blurred ghost card — appears at ~28 s as a mood colour bleed-through
        AnimatedOpacity(
          opacity: blurVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 72,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4ECDC4), Color(0xFFA8E6CF)],
                      ),
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: const ColoredBox(color: Color(0x10FFFFFF)),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (blurVisible) const SizedBox(height: 32),

        // Waveform — 200 px height as per spec
        AnimatedWaveform(
          color: CupertinoColors.activeBlue,
          isAnimating: !reduce,
          barCount: 7,
          width: 140,
          height: 80,
        ),
        const SizedBox(height: 40),

        // Phase message — cross-fades on change
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            phases[currentPhase],
            key: ValueKey<int>(currentPhase),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Step dots
        _StepDots(total: phases.length, current: currentPhase),
      ],
    );
  }
}

// ── Step dots ─────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isDone = i < current;
        final isActive = i == current;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isActive ? 10 : 8,
            height: isActive ? 10 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDone || isActive)
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.separator,
            ),
          ),
        );
      }),
    );
  }
}

// ── Timeout state ─────────────────────────────────────────────────────

class _TimeoutState extends StatelessWidget {
  const _TimeoutState({required this.onRetry, required this.onCancel});

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          CupertinoIcons.exclamationmark_triangle_fill,
          size: 56,
          color: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 20),
        const Text(
          "This one's taking longer than usual.\nGive it another try.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton.filled(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
            const SizedBox(width: 16),
            CupertinoButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.icon,
    required this.title,
    required this.isRateLimit,
    required this.onRetry,
    required this.onCancel,
  });

  final IconData icon;
  final String title;
  final bool isRateLimit;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: CupertinoColors.destructiveRed),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 32),
        if (isRateLimit)
          CupertinoButton.filled(
            onPressed: onCancel,
            child: const Text('OK'),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton.filled(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
              const SizedBox(width: 16),
              CupertinoButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
      ],
    );
  }
}
