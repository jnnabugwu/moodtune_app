import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/device_details.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef PackageInfoLoader = Future<PackageInfo> Function();

/// Platform, OS version, device model and app version for mood
/// observations. Loaded once and cached; [load] never throws (fields it
/// can't read are null).
class DeviceContext {
  DeviceContext({
    DeviceInfoPlugin? deviceInfo,
    PackageInfoLoader? packageInfo,
    TargetPlatform? platform,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _packageInfo = packageInfo ?? PackageInfo.fromPlatform,
       _platform = platform;

  final DeviceInfoPlugin _deviceInfo;
  final PackageInfoLoader _packageInfo;
  final TargetPlatform? _platform;

  Future<DeviceDetails>? _details;

  Future<DeviceDetails> load() => _details ??= _read();

  Future<DeviceDetails> _read() async {
    final platform = _platform ?? defaultTargetPlatform;
    String? osVersion;
    String? deviceModel;
    String? appVersion;

    try {
      switch (platform) {
        case TargetPlatform.iOS:
          final ios = await _deviceInfo.iosInfo;
          osVersion = ios.systemVersion;
          // Hardware id such as "iPhone15,2" (more precise than ios.model).
          // The simulator reports the Mac's architecture ("arm64") instead.
          deviceModel = ios.isPhysicalDevice ? ios.utsname.machine : null;
        case TargetPlatform.android:
          final android = await _deviceInfo.androidInfo;
          osVersion = android.version.release;
          deviceModel = '${android.manufacturer} ${android.model}';
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          break;
      }
    } on Object catch (e, s) {
      talker.warning('Device info unavailable: $e', e, s);
    }

    try {
      final info = await _packageInfo();
      appVersion = info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
    } on Object catch (e, s) {
      talker.warning('Package info unavailable: $e', e, s);
    }

    return DeviceDetails(
      platform: platform.name.toLowerCase(),
      osVersion: osVersion,
      deviceModel: deviceModel,
      appVersion: appVersion,
    );
  }
}
