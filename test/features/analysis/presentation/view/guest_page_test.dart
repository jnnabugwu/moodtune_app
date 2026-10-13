import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/view/guest_page.dart';
import 'package:moodtune_app/shared/widgets/animated_waveform.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('GuestPage', () {
    // The hero waveform repeats forever, so pumpAndSettle would time out.
    Future<void> pumpGuestPage(WidgetTester tester) async {
      await tester.pumpApp(const GuestPage());
      await tester.pump();
    }

    Future<void> tapAndNavigate(WidgetTester tester, String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pump();
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('renders wordmark, hero, headline and CTAs', (tester) async {
      await pumpGuestPage(tester);

      expect(find.text('MoodTune'), findsOneWidget);
      expect(find.byType(AnimatedWaveform), findsOneWidget);
      expect(find.text('Drop a song.'), findsOneWidget);
      expect(find.text('Find its mood.'), findsOneWidget);
      expect(
        find.text(
          'Upload any audio file and we read its energy, '
          'rhythm, and feel — instantly.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try it — upload now'), findsOneWidget);
      expect(find.text('Browse the catalog'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('upload CTA pushes the upload music route', (tester) async {
      await pumpGuestPage(tester);

      await tapAndNavigate(tester, 'Try it — upload now');

      expect(find.text(navigatedTo(RouteNames.uploadMusic)), findsOneWidget);
    });

    testWidgets('catalog CTA pushes the catalog route', (tester) async {
      await pumpGuestPage(tester);

      await tapAndNavigate(tester, 'Browse the catalog');

      expect(find.text(navigatedTo(RouteNames.catalog)), findsOneWidget);
    });

    testWidgets('sign in link pushes the sign-in route', (tester) async {
      await pumpGuestPage(tester);

      await tapAndNavigate(tester, 'Sign in');

      expect(find.text(navigatedTo(RouteNames.signIn)), findsOneWidget);
    });
  });
}
