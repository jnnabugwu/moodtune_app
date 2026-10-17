import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

/// Shown after a password-reset link opens the app. The user already has a
/// recovery session, so saving the new password signs them straight in.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _localError;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordCtrl.text.trim();
    if (password.isEmpty) {
      setState(() => _localError = 'Please enter a new password.');
      return;
    }
    if (_confirmCtrl.text.trim() != password) {
      setState(() => _localError = 'Passwords do not match.');
      return;
    }
    setState(() => _localError = null);
    context.read<AuthBloc>().add(PasswordUpdateRequested(password));
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
        } else if (state.status == AuthStatus.authenticated &&
            !state.passwordRecovery) {
          context.go(RouteNames.homeAuth);
        } else if (state.status == AuthStatus.unauthenticated) {
          // Cancelled: the recovery session was signed out.
          context.go(RouteNames.signIn);
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        final displayError = _localError;

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            automaticallyImplyLeading: false,
            // A reset link signs the user in; cancelling signs them out
            // again rather than leaving a half-finished recovery session.
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: isLoading
                  ? null
                  : () => context.read<AuthBloc>().add(
                      const AuthSignOutRequested(),
                    ),
              child: const Text('Cancel'),
            ),
            middle: const Text('New password'),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Choose a new password for your account.',
                    style: theme.textTheme.textStyle.copyWith(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  CupertinoTextField(
                    controller: _passwordCtrl,
                    placeholder: 'New password',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _confirmCtrl,
                    placeholder: 'Confirm new password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    enabled: !isLoading,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  if (displayError != null) ...[
                    ErrorBanner(message: displayError),
                    const SizedBox(height: 16),
                  ],
                  CupertinoButton.filled(
                    onPressed: isLoading ? null : _submit,
                    borderRadius: BorderRadius.circular(12),
                    child: isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Save password',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
