import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/shared/widgets/moodtune_note_mark.dart';

// Splash page

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  bool _timerDone = false;
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    // Kick off auth check after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthBloc>().add(const AuthCheckRequested());
    });

    // Minimum display time so the splash doesn't just flash.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _timerDone = true;
      _maybeNavigate();
    });
  }

  void _onAuthResolved(String route) {
    _pendingRoute = route;
    _maybeNavigate();
  }

  /// Navigate only when both the min timer AND auth check have resolved.
  void _maybeNavigate() {
    if (_timerDone && _pendingRoute != null) {
      context.go(_pendingRoute!);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, curr) =>
          curr.status == AuthStatus.authenticated ||
          curr.status == AuthStatus.unauthenticated ||
          curr.status == AuthStatus.error,
      listener: (context, state) {
        _onAuthResolved(
          state.status == AuthStatus.authenticated
              ? RouteNames.homeAuth
              : RouteNames.landing,
        );
      },
      child: CupertinoPageScaffold(
        backgroundColor: MoodTuneLogo.ink,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: const MoodTuneLogo(size: 72),
          ),
        ),
      ),
    );
  }
}

// Lockup widget

enum MoodTuneLogoVariant {
  /// Peach mark + cream wordmark on ink background (dark screens).
  dark,

  /// Ink mark + ink wordmark on light/cream backgrounds.
  light,
}

/// MoodTune brand lockup — smiling-note mark + "moodtune" wordmark.
///
/// [size] is the height of the mark square; wordmark and spacing
/// scale from it. [variant] selects the dark or light colour set.
class MoodTuneLogo extends StatelessWidget {
  const MoodTuneLogo({
    super.key,
    this.size = 40.0,
    this.variant = MoodTuneLogoVariant.dark,
  });

  final double size;
  final MoodTuneLogoVariant variant;

  // Brand colour tokens
  /// Charcoal — primary, wordmark default, dark-variant background.
  static const Color ink = Color(0xFF2D2A26);

  /// Off-white — light backgrounds, face cut-outs on light mark.
  static const Color cream = Color(0xFFEFECE6);

  /// Warm peach — accent, mark colour on dark backgrounds.
  static const Color peach = Color(0xFFD99D77);

  @override
  Widget build(BuildContext context) {
    final (noteColor, faceColor, wordmarkColor) = switch (variant) {
      MoodTuneLogoVariant.dark => (peach, ink, cream),
      MoodTuneLogoVariant.light => (ink, cream, ink),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MoodTuneNoteMark(
          size: size,
          noteColor: noteColor,
          faceColor: faceColor,
        ),
        SizedBox(width: size * 0.28),
        Text(
          'moodtune',
          style: TextStyle(
            color: wordmarkColor,
            // Inter Tight 700 per brand spec; system sans-serif fallback.
            fontFamily: 'Inter Tight',
            fontSize: size * 0.52,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
