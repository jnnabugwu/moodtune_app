import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/di/injector.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_content.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_target.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_card_renderer.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_repository.dart';
import 'package:moodtune_app/features/sharing/presentation/bloc/share_bloc.dart';
import 'package:moodtune_app/features/sharing/presentation/share_caption.dart';
import 'package:moodtune_app/l10n/l10n.dart';
import 'package:moodtune_app/shared/widgets/bottom_sheet_base.dart';

/// Opens the share bottom sheet for [content] (R1, AC1, AC10).
///
/// The sheet lists Instagram Stories and X when available plus "More…",
/// closes itself once a share call returns (completed or cancelled), and
/// stays open with an inline message when one fails (R10).
Future<void> showShareSheet(BuildContext context, ShareContent content) {
  final l10n = context.l10n;
  return showMoodTuneBottomSheet<void>(
    context: context,
    child: BlocProvider(
      create: (_) => ShareBloc(
        repository: getIt<ShareRepository>(),
        renderer: getIt<ShareCardRenderer>(),
        captionBuilder: (content, target) =>
            buildShareCaption(l10n, content, target),
      )..add(ShareOpened(content)),
      child: const ShareSheet(),
    ),
  );
}

/// Body of the share sheet. Expects a [ShareBloc] above it.
class ShareSheet extends StatelessWidget {
  const ShareSheet({super.key});

  static const Color _textPrimary = CupertinoColors.label;
  static const Color _textSecondary = CupertinoColors.secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ShareBloc, ShareState>(
      listenWhen: (prev, curr) =>
          curr.status == ShareStatus.done && prev.status != ShareStatus.done,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final loading =
            state.status == ShareStatus.initial ||
            state.status == ShareStatus.loadingTargets;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.shareSheetTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CupertinoActivityIndicator(),
              )
            else
              for (final target in state.targets)
                _ShareTargetRow(
                  target: target,
                  label: _labelFor(l10n, target),
                  busy: state.isSharing && state.activeTarget == target,
                  enabled: !state.isSharing,
                ),
            if (state.isSharing)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.sharePreparing,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ),
            if (state.status == ShareStatus.failure)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.shareFailed,
                  key: const Key('share_failed_message'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _labelFor(AppLocalizations l10n, ShareTarget target) =>
      switch (target) {
        ShareTarget.instagramStory => l10n.shareTargetInstagramStory,
        ShareTarget.x => l10n.shareTargetX,
        ShareTarget.system => l10n.shareTargetMore,
      };
}

class _ShareTargetRow extends StatelessWidget {
  const _ShareTargetRow({
    required this.target,
    required this.label,
    required this.busy,
    required this.enabled,
  });

  final ShareTarget target;
  final String label;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      key: ValueKey('share_target_${target.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      onPressed: enabled ? () => _select(context) : null,
      child: Row(
        children: [
          _TargetGlyph(target: target),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ShareSheet._textPrimary,
              ),
            ),
          ),
          if (busy)
            const CupertinoActivityIndicator()
          else
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: ShareSheet._textSecondary,
            ),
        ],
      ),
    );
  }

  void _select(BuildContext context) {
    // The row's global rect anchors the iPad share popover (R6).
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    context.read<ShareBloc>().add(ShareTargetSelected(target, origin: origin));
  }
}

/// A rounded square with a glyph per target.
class _TargetGlyph extends StatelessWidget {
  const _TargetGlyph({required this.target});

  final ShareTarget target;

  @override
  Widget build(BuildContext context) {
    final (child, background) = switch (target) {
      ShareTarget.instagramStory => (
        const Icon(
          CupertinoIcons.camera_circle_fill,
          size: 22,
          color: CupertinoColors.white,
        ),
        const Color(0xFFE1306C),
      ),
      ShareTarget.x => (
        const Text(
          'X',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: CupertinoColors.white,
          ),
        ),
        const Color(0xFF000000),
      ),
      ShareTarget.system => (
        const Icon(
          CupertinoIcons.share,
          size: 20,
          color: CupertinoColors.white,
        ),
        const Color(0xFF6B6256),
      ),
    };
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
