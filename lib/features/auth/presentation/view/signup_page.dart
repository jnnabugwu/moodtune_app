import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/core/routing/routing.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    context.read<AuthBloc>().add(AuthSignUpRequested(email, password));
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.error != curr.error,
      listener: (context, state) {
        if (state.error != null) {
          showCupertinoDialog<void>(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Auth error'),
              content: Text(state.error ?? ''),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        final showVerifyBanner =
            state.status == AuthStatus.authenticated && state.justSignedUp;
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Sign up'),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Create your account',
                    style: theme.textTheme.navTitleTextStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (showVerifyBanner) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemYellow.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CupertinoColors.systemYellow.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.info,
                            color: CupertinoColors.systemYellow,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Check your email to verify your'
                              ' address before signing in.',
                              style: theme.textTheme.textStyle.copyWith(
                                color: CupertinoColors.systemYellow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  CupertinoTextField(
                    controller: _emailController,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _passwordController,
                    placeholder: 'Password',
                    obscureText: true,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text('Sign up'),
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    onPressed: isLoading
                        ? null
                        : () => context.go(RouteNames.login),
                    child: isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text('Sign in'),
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
