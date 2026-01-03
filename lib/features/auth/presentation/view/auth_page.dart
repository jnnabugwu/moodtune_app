import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/core/routing/routing.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
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
    context.read<AuthBloc>().add(AuthSignInRequested(email, password));
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status || prev.error != curr.error,
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
        if (state.status == AuthStatus.authenticated) {
          context.go(RouteNames.spotify);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Sign in'),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      state.user != null && state.user!.email.isNotEmpty
                          ? state.user!.email
                          : 'Welcome back',
                      style: theme.textTheme.navTitleTextStyle.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 20),
                    CupertinoButton.filled(
                      onPressed: isLoading
                          ? null
                          : () => GoRouter.of(context).go(RouteNames.signup),
                      child: isLoading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text('Sign up'),
                    ),
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
