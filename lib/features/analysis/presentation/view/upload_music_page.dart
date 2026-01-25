import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';

class UploadMusicPage extends StatefulWidget {
  const UploadMusicPage({super.key});

  @override
  State<UploadMusicPage> createState() => _UploadMusicPageState();
}

class _UploadMusicPageState extends State<UploadMusicPage> {
  Uint8List? _fileBytes;
  String? _fileName;
  int? _fileSizeBytes;

  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'flac', 'wav', 'ogg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;

    setState(() {
      _fileBytes = file.bytes;
      _fileName = file.name;
      _fileSizeBytes = file.size;
    });
  }

  void _analyze() {
    if (_fileBytes == null || _fileName == null) return;
    context.read<AnalysisBloc>().add(
          AudioUploadRequested(
            bytes: _fileBytes!,
            filename: _fileName!,
            title: _titleController.text.trim(),
            artist: _artistController.text.trim(),
            album: _albumController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final surfaceColor = CupertinoColors.systemGrey6.withValues(alpha: 0.2);
    final fieldDecoration = BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: CupertinoColors.systemGrey4.withValues(alpha: 0.4),
      ),
    );

    return BlocConsumer<AnalysisBloc, AnalysisState>(
      listenWhen: (previous, current) =>
          previous.uploadError != current.uploadError,
      listener: (context, state) {
        final error = state.uploadError;
        if (error != null) {
          showCupertinoDialog<void>(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Upload error'),
              content: Text(error),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        final isUploading = state.uploadStatus == UploadStatus.uploading;
        final analysis = state.currentUploadAnalysis;
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Upload Music'),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Upload a song for analysis',
                  style: theme.textTheme.navTitleTextStyle.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accepted formats: MP3, M4A, FLAC, WAV, OGG (max 15 MB)',
                  style: theme.textTheme.textStyle.copyWith(
                    color: theme.textTheme.textStyle.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: isUploading ? null : _pickFile,
                  child: const Text('Choose a file'),
                ),
                if (_fileName != null) ...[
                  const SizedBox(height: 12),
                  _FileInfoCard(
                    filename: _fileName!,
                    sizeBytes: _fileSizeBytes ?? 0,
                  ),
                ],
                const SizedBox(height: 20),
                CupertinoTextField(
                  controller: _titleController,
                  placeholder: 'Title (optional)',
                  enabled: !isUploading,
                  decoration: fieldDecoration,
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: _artistController,
                  placeholder: 'Artist (optional)',
                  enabled: !isUploading,
                  decoration: fieldDecoration,
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: _albumController,
                  placeholder: 'Album (optional)',
                  enabled: !isUploading,
                  decoration: fieldDecoration,
                ),
                const SizedBox(height: 20),
                CupertinoButton.filled(
                  onPressed:
                      isUploading || _fileBytes == null ? null : _analyze,
                  child: isUploading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Text('Analyze song'),
                ),
                const SizedBox(height: 24),
                if (analysis != null) _UploadAnalysisResult(analysis: analysis),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FileInfoCard extends StatelessWidget {
  const _FileInfoCard({
    required this.filename,
    required this.sizeBytes,
  });

  final String filename;
  final int sizeBytes;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final sizeMb = sizeBytes / (1024 * 1024);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.music_note_2),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: theme.textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sizeMb.toStringAsFixed(2)} MB',
                  style: theme.textTheme.textStyle.copyWith(
                    color: theme.textTheme.textStyle.color?.withValues(
                      alpha: 0.7,
                    ),
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

class _UploadAnalysisResult extends StatelessWidget {
  const _UploadAnalysisResult({required this.analysis});

  final AudioUploadAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final mood = analysis.mood;
    final scores = mood.moodScores;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Result',
            style: theme.textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mood.primaryMood.toUpperCase(),
            style: theme.textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(mood.confidence * 100).toStringAsFixed(0)}% confidence',
            style: theme.textTheme.textStyle.copyWith(
              color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Duration',
            value: '${analysis.durationSeconds.toStringAsFixed(1)}s',
          ),
          _MetricRow(
            label: 'Tempo',
            value:
                '${mood.audioFeatures.tempo.toStringAsFixed(0)} BPM',
          ),
          _MetricRow(
            label: 'Energy',
            value: scores['energy']?.toStringAsFixed(2) ?? '-',
          ),
          _MetricRow(
            label: 'Valence',
            value: scores['valence']?.toStringAsFixed(2) ?? '-',
          ),
          const SizedBox(height: 8),
          Text(
            mood.reasoning,
            style: theme.textTheme.textStyle.copyWith(
              color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.textStyle.copyWith(
              color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
