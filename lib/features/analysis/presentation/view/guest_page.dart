import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/shared/widgets/widgets.dart';

/// Redesigned landing screen shown to unauthenticated users.
///
/// No navigation bar. Centred single-column layout with:
/// primary upload CTA → catalog CTA → sign-in link.
class GuestPage extends StatelessWidget {
  const GuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    // TODO(connectivity): add connectivity_plus stream; when offline, insert
    // ErrorBanner(message: "You're offline…") above the primary CTA.

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),

            // ── Wordmark ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.music_note,
                  size: 26,
                  color: Color(0xFFF5A623),
                ),
                const SizedBox(width: 8),
                Text(
                  'MoodTune',
                  style: theme.textTheme.navTitleTextStyle.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // ── Hero graphic (animated waveform placeholder) ───────────
            Center(
              child: Container(
                width: 200,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x334A6FA5), Color(0x334ECDC4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: AnimatedWaveform(
                    color: Color(0xFFF5A623),
                    width: 120,
                    height: 60,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // ── Headline ───────────────────────────────────────────────
            Text(
              'Drop a song.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: theme.textTheme.textStyle.color,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Find its mood.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: Color(0xFFF5A623),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // ── Subhead ────────────────────────────────────────────────
            Text(
              'Upload any audio file and we read its energy, '
              'rhythm, and feel — instantly.',
              style: theme.textTheme.textStyle.copyWith(
                color: CupertinoColors.secondaryLabel,
                fontSize: 16,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // ── Primary CTA ────────────────────────────────────────────
            CupertinoButton.filled(
              onPressed: () => context.push(RouteNames.uploadMusic),
              borderRadius: BorderRadius.circular(14),
              child: const Text(
                'Try it — upload now',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),

            // ── Ghost CTA ──────────────────────────────────────────────
            CupertinoButton(
              onPressed: () => context.push(RouteNames.catalog),
              child: const Text(
                'Browse the catalog',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 4),

            // ── Sign-in link ───────────────────────────────────────────
            CupertinoButton(
              onPressed: () => context.push(RouteNames.signIn),
              child: const Text(
                'Sign in',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
