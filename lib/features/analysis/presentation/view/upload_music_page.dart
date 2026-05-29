import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/analysis_loading_page.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

/// Redesigned upload screen with drop-zone card, metadata collapsible,
/// client-side file validation, and a consent bottom sheet before analysis.
class UploadMusicPage extends StatefulWidget {
  const UploadMusicPage({super.key});

  @override
  State<UploadMusicPage> createState() => _UploadMusicPageState();
}

enum _FileError { tooLarge, wrongFormat }

class _UploadMusicPageState extends State<UploadMusicPage> {
  static const int _maxSizeBytes = 15 * 1024 * 1024; // 15 MB
  static const _allowedExtensions = {'mp3', 'm4a', 'flac', 'wav', 'ogg'};

  PlatformFile? _selectedFile;
  _FileError? _fileError;

  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _albumCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // File picking + validation
  // ---------------------------------------------------------------------------

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'flac', 'wav', 'ogg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null) return;

    _FileError? error;
    if (file.size > _maxSizeBytes) {
      error = _FileError.tooLarge;
    } else {
      final ext = file.extension?.toLowerCase() ?? '';
      if (!_allowedExtensions.contains(ext)) {
        error = _FileError.wrongFormat;
      }
    }

    setState(() {
      _selectedFile = file;
      _fileError = error;
    });
  }

  // ---------------------------------------------------------------------------
  // Analysis time estimate (size-based; replace with metadata reader later)
  // ---------------------------------------------------------------------------

  // TODO(metadata): use audio_metadata_reader for accurate duration,
  // then feed real seconds into this method.
  String _analysisEstimate(int sizeBytes) {
    // Approximate: ~20 KB/s for a typical 160 kbps MP3.
    final estimatedSeconds = sizeBytes / 20000;
    if (estimatedSeconds < 180) return '~15 secs';
    if (estimatedSeconds < 300) return '~30 secs';
    if (estimatedSeconds < 480) return '~45 secs';
    return 'about a minute';
  }

  // ---------------------------------------------------------------------------
  // Consent sheet → dispatch + navigate
  // ---------------------------------------------------------------------------

  Future<void> _showConsentSheet() async {
    final confirmed = await showMoodTuneBottomSheet<bool>(
      context: context,
      child: const _ConsentSheet(),
    );
    if ((confirmed ?? false) && mounted) _dispatch();
  }

  void _dispatch() {
    final file = _selectedFile;
    if (file == null || file.bytes == null) return;

    // Estimate duration from file size (approx 20 KB/s at 160 kbps).
    // TODO(metadata): replace with audio_metadata_reader for exact duration.
    final estimatedDurationSeconds = (file.size / 20000).round();

    context.read<AnalysisBloc>().add(
      AudioUploadRequested(
        bytes: Uint8List.fromList(file.bytes!),
        filename: file.name,
        title: _titleCtrl.text.trim(),
        artist: _artistCtrl.text.trim(),
        album: _albumCtrl.text.trim(),
      ),
    );
    context.push(
      RouteNames.analysisLoading,
      extra: AnalysisLoadingArgs(
        source: AnalysisSource.upload,
        trackDurationSeconds: estimatedDurationSeconds,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final dropZoneHeight = MediaQuery.sizeOf(context).height * 0.33;
    final hasValidFile = _selectedFile != null && _fileError == null;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.landing),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('Upload Music'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Section heading ─────────────────────────────────────────
            const Text(
              'Choose a file to analyze',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'MP3 · M4A · FLAC · WAV · OGG · max 15 MB',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 16),

            // ── Drop zone ───────────────────────────────────────────────
            _DropZone(
              file: _selectedFile,
              error: _fileError,
              height: dropZoneHeight,
              onTap: _pickFile,
              analysisEstimate: _selectedFile != null
                  ? _analysisEstimate(_selectedFile!.size)
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Metadata collapsible ────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CollapsibleSection(
                title: 'Add song details',
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: _titleCtrl,
                      placeholder: 'Title (optional)',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _artistCtrl,
                      placeholder: 'Artist (optional)',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _albumCtrl,
                      placeholder: 'Album (optional)',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Analyze button ──────────────────────────────────────────
            CupertinoButton.filled(
              onPressed: hasValidFile ? _showConsentSheet : null,
              borderRadius: BorderRadius.circular(14),
              child: const Text(
                'Analyze song',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Drop zone card ───────────────────────────────────────────────────────────

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.file,
    required this.error,
    required this.height,
    required this.onTap,
    required this.analysisEstimate,
  });

  final PlatformFile? file;
  final _FileError? error;
  final double height;
  final VoidCallback onTap;
  final String? analysisEstimate;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final hasFile = file != null;

    Color borderColor;
    Color bgColor;

    if (hasError) {
      borderColor = const Color(0xFFC0392B);
      bgColor = const Color(0x0FC0392B);
    } else if (hasFile) {
      borderColor = CupertinoColors.activeBlue;
      bgColor = const Color(0x0F0A84FF);
    } else {
      borderColor = CupertinoColors.separator;
      bgColor = CupertinoColors.secondarySystemBackground;
    }

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: borderColor,
          radius: 12,
          dashed: !hasFile && !hasError,
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: hasError
              ? _ErrorState(error: error!, onChangeTap: onTap)
              : hasFile
              ? _SelectedState(
                  file: file!,
                  analysisEstimate: analysisEstimate ?? '~30 secs',
                  onChangeTap: onTap,
                )
              : const _EmptyState(),
        ),
      ),
    );
  }
}

// ── Drop zone states ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.music_note,
          size: 40,
          color: CupertinoColors.secondaryLabel,
        ),
        SizedBox(height: 12),
        Text(
          'Tap to choose a file',
          style: TextStyle(
            fontSize: 15,
            color: CupertinoColors.secondaryLabel,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SelectedState extends StatelessWidget {
  const _SelectedState({
    required this.file,
    required this.analysisEstimate,
    required this.onChangeTap,
  });

  final PlatformFile file;
  final String analysisEstimate;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 20,
                color: CupertinoColors.activeGreen,
              ),
              SizedBox(width: 6),
              Icon(
                CupertinoIcons.music_note,
                size: 20,
                color: CupertinoColors.activeBlue,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            file.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$sizeMb MB  ·  Analysis takes $analysisEstimate',
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onChangeTap,
            child: const Text(
              'Change file',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onChangeTap,
  });

  final _FileError error;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final message = error == _FileError.tooLarge
        ? 'File is too large — maximum 15 MB.'
        : 'Unsupported format — use MP3, M4A, FLAC, WAV, or OGG.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 36,
            color: Color(0xFFC0392B),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFC0392B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onChangeTap,
            child: const Text(
              'Choose a different file',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashed border painter ────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashed,
  });

  final Color color;
  final double radius;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    if (!dashed) {
      canvas.drawRRect(rrect, paint);
      return;
    }

    // Dashed path
    final path = Path()..addRRect(rrect);
    const dashLength = 8.0;
    const gapLength = 5.0;
    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        dashedPath.addPath(
          metric.extractPath(distance, end),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius || old.dashed != dashed;
}

// ── Consent bottom sheet ─────────────────────────────────────────────────────

class _ConsentSheet extends StatelessWidget {
  const _ConsentSheet();

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'One quick thing',
          style: theme.textTheme.navTitleTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'By uploading this track you agree that it will be temporarily '
          'processed by our servers to analyse its audio characteristics. '
          'We never store audio files after analysis.',
          style: theme.textTheme.textStyle.copyWith(
            color: CupertinoColors.secondaryLabel,
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        CupertinoButton.filled(
          borderRadius: BorderRadius.circular(12),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          child: const Text(
            "Yes, let's hear it",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        CupertinoButton(
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
