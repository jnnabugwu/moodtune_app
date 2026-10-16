import 'package:equatable/equatable.dart';

/// Remote flags served by `GET /config`.
class AppConfig extends Equatable {
  const AppConfig({required this.onDeviceMood});

  /// Used whenever the config can't be fetched: features stay on.
  static const fallback = AppConfig(onDeviceMood: true);

  /// Kill switch for on-device (YAMNet) mood. When false, show the backend
  /// mood and skip the on-device classifier.
  final bool onDeviceMood;

  @override
  List<Object?> get props => [onDeviceMood];
}
