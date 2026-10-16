import 'package:moodtune_app/features/mood_feedback/domain/entities/app_config.dart';

/// Loads remote flags. Never throws: falls back to [AppConfig.fallback].
abstract class AppConfigRepository {
  Future<AppConfig> load();
}
