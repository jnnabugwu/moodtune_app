import 'package:flutter/cupertino.dart';

Future<bool?> showAnalysisDisclaimerSheet(
  BuildContext context, {
  int minTracks = 5,
  int maxTracks = 50,
}) {
  return showCupertinoModalPopup<bool>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: const Text('Analyze Playlist'),
      message: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'We will analyze your playlist to uncover its overall mood.',
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 12),
          Text(
            'Requirements',
            style: CupertinoTheme.of(ctx).textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text('• Playlist must have at least $minTracks tracks.'),
          Text('• We analyze up to $maxTracks tracks for speed.'),
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Analyze now'),
        ),
      ],
    ),
  );
}
