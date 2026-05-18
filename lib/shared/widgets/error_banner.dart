import 'package:flutter/cupertino.dart';

/// An inline red-tinted banner for surfacing error messages.
///
/// Designed to sit directly above or below a form field or CTA — not as a
/// full-screen overlay.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // ~12 % opacity red tint
        color: const Color(0x1FC0392B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          // ~25 % opacity red border
          color: const Color(0x40C0392B),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            size: 16,
            color: Color(0xFFC0392B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFC0392B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
