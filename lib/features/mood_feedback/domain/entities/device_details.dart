import 'package:equatable/equatable.dart';

/// Coarse device context attached to a mood observation. Any field can be
/// null when the platform doesn't report it.
class DeviceDetails extends Equatable {
  const DeviceDetails({
    this.platform,
    this.osVersion,
    this.deviceModel,
    this.appVersion,
  });

  /// `ios`, `android`, or another `TargetPlatform` name.
  final String? platform;
  final String? osVersion;

  /// Hardware identifier, e.g. `iPhone15,2` or `Google Pixel 8`.
  final String? deviceModel;

  /// `version+build`, e.g. `1.0.0+7`.
  final String? appVersion;

  @override
  List<Object?> get props => [platform, osVersion, deviceModel, appVersion];
}
