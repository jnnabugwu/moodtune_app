import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';

/// Bottom sheet that confirms before analyzing a Jamendo catalog track.
///
/// Shown via [showCupertinoModalPopup]. Calls [onConfirm] when the user
/// taps "Analyze this track"; dismisses silently on "Cancel".
/// Also lets the user preview up to 30 seconds of the track before deciding.
class CatalogConfirmSheet extends StatefulWidget {
  const CatalogConfirmSheet({
    required this.track,
    required this.onConfirm,
    super.key,
  });

  final JamendoTrack track;
  final VoidCallback onConfirm;

  @override
  State<CatalogConfirmSheet> createState() => _CatalogConfirmSheetState();
}

class _CatalogConfirmSheetState extends State<CatalogConfirmSheet> {
  static const _previewDuration = Duration(seconds: 30);

  final _player = AudioPlayer();

  bool _isPlaying = false;
  bool _isFinished = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();

    _positionSub = _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _stateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isLoading =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        if (state.processingState == ProcessingState.completed) {
          _isFinished = true;
          _isPlaying = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startPreview() async {
    setState(() {
      _isLoading = true;
      _isFinished = false;
      _position = Duration.zero;
    });
    await _player.setAudioSource(
      ClippingAudioSource(
        child: AudioSource.uri(Uri.parse(widget.track.audioUrl)),
        end: _previewDuration,
      ),
    );
    await _player.play();
  }

  Future<void> _togglePlayPause() async {
    if (_isFinished) {
      await _startPreview();
    } else if (_isPlaying) {
      await _player.pause();
    } else {
      await _startPreview();
    }
  }

  String _formatSeconds(int s) {
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Widget _previewButtonChild() {
    if (_isLoading && !_isPlaying) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(),
          SizedBox(width: 8),
          Text('Loading…'),
        ],
      );
    }

    if (_isFinished) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.arrow_counterclockwise, size: 16),
          SizedBox(width: 6),
          Text('Play again'),
        ],
      );
    }

    if (_isPlaying) {
      final elapsed = _formatSeconds(_position.inSeconds.clamp(0, 30));
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.pause_fill, size: 16),
          const SizedBox(width: 6),
          Text('$elapsed / 0:30'),
        ],
      );
    }

    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.play_fill, size: 16),
        SizedBox(width: 6),
        Text('Preview (0:30)'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final durationStr = _formatSeconds(widget.track.duration.inSeconds);

    return CupertinoActionSheet(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: widget.track.albumImageUrl.isNotEmpty
                    ? Image.network(
                        widget.track.albumImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _AlbumArtPlaceholder(),
                      )
                    : const _AlbumArtPlaceholder(),
              ),
            ),
            const SizedBox(height: 12),

            // Track name
            Text(
              widget.track.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.label,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Artist · duration
            Text(
              '${widget.track.artistName} · $durationStr',
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      message: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "We'll analyze the mood of this track from Jamendo's free "
            'music library.',
            textAlign: TextAlign.center,
          ),
          if (widget.track.duration.inSeconds > 300) ...[
            const SizedBox(height: 8),
            const Text(
              'Tracks over 5 minutes — only the first 5 will be analyzed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Preview action
        CupertinoActionSheetAction(
          onPressed: _togglePlayPause,
          child: _previewButtonChild(),
        ),

        // Analyze action
        CupertinoActionSheetAction(
          onPressed: () {
            context.pop();
            widget.onConfirm();
          },
          child: const Text('Analyze this track'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => context.pop(),
        child: const Text('Cancel'),
      ),
    );
  }
}

class _AlbumArtPlaceholder extends StatelessWidget {
  const _AlbumArtPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.tertiarySystemFill,
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.music_note,
        size: 24,
        color: CupertinoColors.tertiaryLabel,
      ),
    );
  }
}
