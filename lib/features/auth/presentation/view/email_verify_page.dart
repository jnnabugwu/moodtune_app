import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

/// Screen shown after sign-up asking the user to verify their email.
///
/// Resend link has a 60-second cooldown. Navigation to [RouteNames.homeAuth]
/// happens automatically when the [AuthBloc] transitions to authenticated
/// (triggered by a deep-link auth check after the user taps the email link).
class EmailVerifyPage extends StatefulWidget {
  const EmailVerifyPage({super.key});

  @override
  State<EmailVerifyPage> createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends State<EmailVerifyPage> {
  static const _cooldownSeconds = 60;

  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
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

  void _resend(String email) {
    context.read<AuthBloc>().add(ResendVerificationRequested(email));
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        // Navigate home once email is confirmed and a fresh session is active.
        if (state.status == AuthStatus.authenticated && !state.justSignedUp) {
          context.go(RouteNames.homeAuth);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final email = state.pendingVerificationEmail ?? '';
          final isResending = state.status == AuthStatus.loading;

          return CupertinoPageScaffold(
            // No leading back button — use "Wrong email?" link instead.
            navigationBar: const CupertinoNavigationBar(
              automaticallyImplyLeading: false,
              middle: Text('Verify email'),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // ── Icon ─────────────────────────────────────────────
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

                    // ── Heading ───────────────────────────────────────────
                    Text(
                      'Check your inbox',
                      style: theme.textTheme.navTitleTextStyle.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // ── Body ──────────────────────────────────────────────
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.textStyle.copyWith(
                          color: CupertinoColors.secondaryLabel,
                          height: 1.5,
                          fontSize: 15,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a link to '),
                          TextSpan(
                            text: email.isNotEmpty ? email : 'your email',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.textStyle.color,
                            ),
                          ),
                          const TextSpan(
                            text: '. Tap it to confirm your account.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Error banner ──────────────────────────────────────
                    if (state.error != null) ...[
                      ErrorBanner(message: state.error!),
                      const SizedBox(height: 16),
                    ],

                    // ── Resend link ───────────────────────────────────────
                    if (_cooldown > 0)
                      Text(
                        'Resend in ${_cooldown}s',
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      )
                    else
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: isResending || email.isEmpty
                            ? null
                            : () => _resend(email),
                        child: isResending
                            ? const CupertinoActivityIndicator()
                            : const Text(
                                'Resend email',
                                style: TextStyle(fontSize: 14),
                              ),
                      ),

                    const Spacer(),

                    // ── "Wrong email?" link ────────────────────────────────
                    CupertinoButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Wrong email? Go back',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
