import 'dart:async';

import 'package:flutter/cupertino.dart';

/// Shows [message] in a small pill near the bottom of the screen that fades
/// in, stays for [duration], then fades out and removes itself.
///
/// Non-blocking: it sits in the root [Overlay] and lets taps through. Built
/// for the Cupertino app, which has no Material `ScaffoldMessenger`.
void showToastNotice(
  BuildContext context, {
  required String message,
  IconData icon = CupertinoIcons.checkmark_circle_fill,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => ToastNotice(
      message: message,
      icon: icon,
      duration: duration,
      onDismissed: () => entry
        ..remove()
        ..dispose(),
    ),
  );
  overlay.insert(entry);
}

/// The pill [showToastNotice] puts in the overlay. Calls [onDismissed] once
/// it has faded out.
class ToastNotice extends StatefulWidget {
  const ToastNotice({
    required this.message,
    required this.onDismissed,
    this.icon = CupertinoIcons.checkmark_circle_fill,
    this.duration = const Duration(seconds: 2),
    super.key,
  });

  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  /// How long the fade in and the fade out each take.
  static const fade = Duration(milliseconds: 200);

  @override
  State<ToastNotice> createState() => _ToastNoticeState();
}

class _ToastNoticeState extends State<ToastNotice>
    with SingleTickerProviderStateMixin {
  // Warm palette shared with the results page.
  static const _background = Color(0xFF2D2A26); // dark brown
  static const _foreground = Color(0xFFF5F1E7); // warm cream

  late final AnimationController _ctrl;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: ToastNotice.fade)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _hold = Timer(widget.duration, _ctrl.reverse);
        } else if (status == AnimationStatus.dismissed) {
          widget.onDismissed();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _hold?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 24),
        child: IgnorePointer(
          child: FadeTransition(
            opacity: _ctrl,
            child: Center(
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332D2A26),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, size: 16, color: _foreground),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
