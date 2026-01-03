import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_gate_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/auth_page.dart';
import 'package:moodtune_app/features/auth/presentation/view/signup_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.login,
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: RouteNames.spotify,
        builder: (context, state) => const AuthGatePage(),
      ),
      GoRoute(
        path: RouteNames.notFound,
        builder: (context, state) => const NotFoundPage(),
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Something went wrong${error != null ? ': '
                  ' $error' : ''}',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Page not found'),
    );
  }
}
