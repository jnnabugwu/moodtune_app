import 'package:flutter/widgets.dart';
import 'package:moodtune_app/app/app.dart';
import 'package:moodtune_app/bootstrap.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'staging');

  await SentryFlutter.init(
    (options) {
      if (sentryDsn.isNotEmpty) {
        options.dsn = sentryDsn;
      }
      options..environment = environment
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      ..tracesSampleRate = 1.0
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      ..sendDefaultPii = false;
    },
    appRunner: () async {
      const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
      const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      await bootstrap(() => const App());
    },
  );
}
