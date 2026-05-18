import 'package:flutter/cupertino.dart';

/// A base bottom sheet widget with a drag handle and standard padding.
///
/// Always use [showMoodTuneBottomSheet] to present this — it wraps
/// [showCupertinoModalPopup] with the correct barrier and dismissal behaviour.
class MoodTuneBottomSheet extends StatelessWidget {
  const MoodTuneBottomSheet({
    required this.child,
    super.key,
    this.contentPadding =
        const EdgeInsets.fromLTRB(16, 0, 16, 32),
  });

  final Widget child;

  /// Padding applied around [child] below the drag handle.
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.secondarySystemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: contentPadding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents a [MoodTuneBottomSheet] via [showCupertinoModalPopup].
///
/// Returns the value passed to [Navigator.pop] when dismissed, or `null`.
Future<T?> showMoodTuneBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isDismissible = true,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (_) => MoodTuneBottomSheet(child: child),
  );
}
