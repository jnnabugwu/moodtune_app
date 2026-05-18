import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

enum _AuthMode { signIn, signUp }

/// Unified sign-in / sign-up screen.
///
/// A segmented tab toggle switches between modes without navigation.
/// The "Confirm password" field expands with [AnimatedSize] in sign-up mode.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  _AuthMode _mode = _AuthMode.signIn;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _localError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _localError = null;
    });
  }

  void _submit(AuthState state) {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _localError = 'Please fill in all fields.');
      return;
    }

    if (_mode == _AuthMode.signUp) {
      if (_confirmCtrl.text.trim() != password) {
        setState(() => _localError = 'Passwords do not match.');
        return;
      }
      setState(() => _localError = null);
      context.read<AuthBloc>().add(AuthSignUpRequested(email, password));
    } else {
      setState(() => _localError = null);
      context.read<AuthBloc>().add(AuthSignInRequested(email, password));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status || prev.error != curr.error,
      listener: (context, state) {
        if (state.error != null) {
          setState(() => _localError = state.error);
        } else if (state.status == AuthStatus.authenticated) {
          if (state.justSignedUp) {
            context.push(RouteNames.emailVerify);
          } else {
            context.go(RouteNames.homeAuth);
          }
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        final displayError = _localError;

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.landing);
                }
              },
              child: const Icon(CupertinoIcons.back),
            ),
            middle: Text(_mode == _AuthMode.signIn ? 'Sign in' : 'Sign up'),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),

                  // ── Mode toggle ────────────────────────────────────────
                  _ModeToggle(
                    mode: _mode,
                    onChanged: isLoading ? null : _switchMode,
                  ),
                  const SizedBox(height: 28),

                  // ── Email ──────────────────────────────────────────────
                  CupertinoTextField(
                    controller: _emailCtrl,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enabled: !isLoading,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Password ───────────────────────────────────────────
                  CupertinoTextField(
                    controller: _passwordCtrl,
                    placeholder: 'Password',
                    obscureText: true,
                    textInputAction: _mode == _AuthMode.signUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    enabled: !isLoading,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),

                  // ── Confirm password (sign-up only) ────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _mode == _AuthMode.signUp
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: CupertinoTextField(
                              controller: _confirmCtrl,
                              placeholder: 'Confirm password',
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Forgot password (sign-in only) ─────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _mode == _AuthMode.signIn
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: CupertinoButton(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 4,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () => context.push(
                                      RouteNames.forgotPassword,
                                      extra: _emailCtrl.text.trim(),
                                    ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),

                  // ── Error banner ───────────────────────────────────────
                  if (displayError != null) ...[
                    ErrorBanner(message: displayError),
                    const SizedBox(height: 16),
                  ],

                  // ── Primary CTA ────────────────────────────────────────
                  CupertinoButton.filled(
                    onPressed: isLoading ? null : () => _submit(state),
                    borderRadius: BorderRadius.circular(12),
                    child: isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : Text(
                            _mode == _AuthMode.signIn ? 'Sign in' : 'Sign up',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // ── "or" divider ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 0.5,
                          color: CupertinoColors.separator,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: theme.textTheme.textStyle.copyWith(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 0.5,
                          color: CupertinoColors.separator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Social buttons (OAuth placeholders) ────────────────
                  // TODO(oauth): wire Google + Apple sign-in via url_launcher.
                  const _SocialButton(
                    label: 'Continue with Google',
                    icon: CupertinoIcons.globe,
                    onTap: null,
                  ),
                  const SizedBox(height: 10),
                  const _SocialButton(
                    label: 'Continue with Apple',
                    icon: CupertinoIcons.device_phone_portrait,
                    onTap: null,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final _AuthMode mode;
  final void Function(_AuthMode)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tab(
          label: 'Sign in',
          isActive: mode == _AuthMode.signIn,
          onTap: onChanged == null ? null : () => onChanged!(_AuthMode.signIn),
        ),
        const SizedBox(width: 24),
        _Tab(
          label: 'Sign up',
          isActive: mode == _AuthMode.signUp,
          onTap: onChanged == null ? null : () => onChanged!(_AuthMode.signUp),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final activeColor = theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? activeColor : CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 2,
            width: isActive ? 60 : 0,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.separator),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: CupertinoColors.label),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
