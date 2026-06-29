import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';

/// Shows a [CupertinoActionSheet] letting the user choose between browsing
/// the catalog or uploading a file. Call this wherever "Analyze a song" CTAs
/// appear instead of hard-navigating to a single flow.
Future<void> showAnalysisSourceSheet(BuildContext context) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => CupertinoActionSheet(
      title: const Text('Analyze a Song'),
      message: const Text('Choose how you want to find your track.'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => context
            ..pop()
            ..push(RouteNames.catalog),
          child: const Text('Browse Catalog'),
        ),
        CupertinoActionSheetAction(
          onPressed: () => context
            ..pop()
            ..push(RouteNames.uploadMusic),
          child: const Text('Upload a Song'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => context.pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
}
