import 'package:flutter/cupertino.dart';

/// A persistent 60 dp bottom strip prompting guests to sign up.
///
/// Shows "Save this & see your history" copy alongside a pill Sign Up button.
/// Typically pinned below [SafeArea] on guest-variant screens (Results, etc.).
class SignUpStrip extends StatelessWidget {
  const SignUpStrip({
    required this.onSignUp,
    super.key,
  });

  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Save this & see your history',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(20),
            minimumSize: const Size(36, 36),
            onPressed: onSignUp,
            child: const Text(
              'Sign up',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
