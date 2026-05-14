import 'package:flutter/widgets.dart';
import 'package:moodtune_app/app/app.dart';
import 'package:moodtune_app/bootstrap.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  await SentryFlutter.init(
    (options) {
      if (sentryDsn.isNotEmpty) {
        options.dsn = sentryDsn;
      }
      options
        ..environment = environment
        // Capture 100% of transactions for tracing.
        // Adjust this value in production.
        ..tracesSampleRate = 1.0
        // Do not send PII by default.
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
