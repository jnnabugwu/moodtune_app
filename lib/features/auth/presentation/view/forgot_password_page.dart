import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

/// Forgot password screen with two local states: default and sent.
///
/// The email field is pre-populated when a non-empty string is passed as
/// [GoRouterState.extra] from the sign-in screen.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    required this.prefillEmail,
    super.key,
  });

  /// Pre-filled email address — empty string if not provided.
  final String prefillEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const _cooldownSeconds = 60;

  late final TextEditingController _emailCtrl;
  bool _sent = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefillEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldown = _cooldown - 1;
        if (_cooldown <= 0) t.cancel();
      });
    });
  }

  void _send() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    context.read<AuthBloc>().add(ForgotPasswordRequested(email));
  }

  void _resend() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    context.read<AuthBloc>().add(ForgotPasswordRequested(email));
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.passwordResetSent != curr.passwordResetSent ||
          prev.status != curr.status,
      listener: (context, state) {
        if (state.passwordResetSent && !_sent) {
          setState(() => _sent = true);
          _startCooldown();
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.signIn),
              child: const Icon(CupertinoIcons.back),
            ),
            middle: Text(_sent ? 'Link sent' : 'Reset your password'),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _sent
                  ? _SentView(
                      key: const ValueKey('sent'),
                      cooldown: _cooldown,
                      isLoading: isLoading,
                      onResend: _cooldown > 0 ? null : _resend,
                      onBackToSignIn: () => context.go(RouteNames.signIn),
                    )
                  : _DefaultView(
                      key: const ValueKey('default'),
                      emailCtrl: _emailCtrl,
                      isLoading: isLoading,
                      error: state.error,
                      onSend: _send,
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ── Default state ────────────────────────────────────────────────────────────

class _DefaultView extends StatelessWidget {
  const _DefaultView({
    required this.emailCtrl,
    required this.isLoading,
    required this.error,
    required this.onSend,
    super.key,
  });

  final TextEditingController emailCtrl;
  final bool isLoading;
  final String? error;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            "Enter your email and we'll send you a link to reset it.",
            style: theme.textTheme.textStyle.copyWith(
              color: CupertinoColors.secondaryLabel,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          CupertinoTextField(
            controller: emailCtrl,
            placeholder: 'Email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enabled: !isLoading,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            onSubmitted: (_) => onSend(),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(message: error!),
          ],
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: isLoading ? null : onSend,
            borderRadius: BorderRadius.circular(12),
            child: isLoading
                ? const CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                  )
                : const Text(
                    'Send reset link',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Sent state ───────────────────────────────────────────────────────────────

class _SentView extends StatelessWidget {
  const _SentView({
    required this.cooldown,
    required this.isLoading,
    required this.onResend,
    required this.onBackToSignIn,
    super.key,
  });

  final int cooldown;
  final bool isLoading;
  final VoidCallback? onResend;
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 48),

          // ── Icon ────────────────────────────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.mail,
              size: 40,
              color: CupertinoColors.activeBlue,
            ),
          ),
          const SizedBox(height: 28),

          // ── Heading ──────────────────────────────────────────────────────
          Text(
            'Link sent',
            style: theme.textTheme.navTitleTextStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // ── Body ─────────────────────────────────────────────────────────
          Text(
            'Check your email for a reset link. It expires in 1 hour.',
            style: theme.textTheme.textStyle.copyWith(
              color: CupertinoColors.secondaryLabel,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // ── Resend ───────────────────────────────────────────────────────
          if (cooldown > 0)
            Text(
              'Resend in ${cooldown}s',
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            )
          else
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: isLoading ? null : onResend,
              child: isLoading
                  ? const CupertinoActivityIndicator()
                  : const Text('Resend', style: TextStyle(fontSize: 14)),
            ),

          const Spacer(),

          // ── Back link ────────────────────────────────────────────────────
          CupertinoButton(
            onPressed: onBackToSignIn,
            child: const Text(
              'Back to sign in',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
