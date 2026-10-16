import 'package:moodtune_app/features/mood_feedback/domain/entities/app_config.dart';

/// Response of `GET /config`.
class AppConfigModel {
  const AppConfigModel({required this.onDeviceMood});

  /// Throws [FormatException] when `on_device_mood` is missing or not a bool.
  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    final onDeviceMood = json['on_device_mood'];
    if (onDeviceMood is! bool) {
      throw FormatException('Invalid on_device_mood: $onDeviceMood');
    }
    return AppConfigModel(onDeviceMood: onDeviceMood);
  }

  final bool onDeviceMood;

  AppConfig toDomain() => AppConfig(onDeviceMood: onDeviceMood);
}
