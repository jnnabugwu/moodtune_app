import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

/// Landing route for Supabase email links (sign-up confirmation and
/// password reset).
///
/// supabase_flutter exchanges the link's `code` for a session on its own;
/// this page waits for the resulting [AuthBloc] change and routes on. An
/// expired or invalid link arrives with an `error_description` instead.
class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({required this.uri, super.key});

  /// The incoming link as GoRouter received it.
  final Uri uri;

  /// How long to wait for the session before calling the link broken.
  static const timeout = Duration(seconds: 10);

  /// How long to wait when a session already exists, in case the link turns
  /// out to be a password reset, before going home.
  static const signedInGrace = Duration(seconds: 2);

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  Timer? _timer;

  /// The link itself carried an error; nothing can recover from that.
  String? _linkError;

  /// No session arrived in time. A late one still wins.
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _linkError = _errorIn(widget.uri);
    if (_linkError != null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The link's auth change can beat this page to the bloc.
      final state = context.read<AuthBloc>().state;
      if (state.passwordRecovery) {
        context.go(RouteNames.resetPassword);
        return;
      }
      _timer = Timer(
        _isSignedIn(state)
            ? AuthCallbackPage.signedInGrace
            : AuthCallbackPage.timeout,
        _onTimeout,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static bool _isSignedIn(AuthState state) =>
      state.status == AuthStatus.authenticated && !state.justSignedUp;

  /// Supabase puts link errors in the query (PKCE) or fragment (implicit).
  /// Both decoders already turn `+` into spaces.
  static String? _errorIn(Uri uri) {
    final fragment = uri.fragment.contains('=')
        ? Uri.splitQueryString(uri.fragment)
        : const <String, String>{};
    return uri.queryParameters['error_description'] ??
        fragment['error_description'];
  }

  void _onTimeout() {
    if (!mounted) return;
    // Already signed in (e.g. the change landed before this page did).
    if (_isSignedIn(context.read<AuthBloc>().state)) {
      context.go(RouteNames.homeAuth);
      return;
    }
    setState(() => _timedOut = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final error =
        _linkError ??
        (_timedOut
            ? 'This link is invalid or has expired. Request a new one.'
            : null);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_linkError != null) return;
        if (state.passwordRecovery) {
          context.go(RouteNames.resetPassword);
        } else if (_isSignedIn(state)) {
          context.go(RouteNames.homeAuth);
        }
      },
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          middle: Text('Signing in'),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: error == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CupertinoActivityIndicator(radius: 14),
                        const SizedBox(height: 16),
                        Text(
                          'Signing you in…',
                          style: theme.textTheme.textStyle.copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ErrorBanner(message: error),
                        const SizedBox(height: 24),
                        CupertinoButton.filled(
                          onPressed: () => context.go(RouteNames.signIn),
                          borderRadius: BorderRadius.circular(12),
                          child: const Text(
                            'Back to sign in',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
