import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/mood_feedback/data/device_context.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/device_details.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

IosDeviceInfo _iosInfo() => IosDeviceInfo.setMockInitialValues(
  name: 'Jordan’s iPhone',
  systemName: 'iOS',
  systemVersion: '18.1',
  model: 'iPhone',
  modelName: 'iPhone 14 Pro',
  localizedModel: 'iPhone',
  freeDiskSize: 0,
  totalDiskSize: 0,
  isPhysicalDevice: true,
  isiOSAppOnMac: false,
  isiOSAppOnVision: false,
  physicalRamSize: 0,
  availableRamSize: 0,
  utsname: IosUtsname.setMockInitialValues(
    sysname: 'Darwin',
    nodename: 'node',
    release: '24.1.0',
    version: 'Darwin Kernel',
    machine: 'iPhone15,2',
  ),
);

AndroidDeviceInfo _androidInfo() => AndroidDeviceInfo.setMockInitialValues(
  version: AndroidBuildVersion.setMockInitialValues(
    codename: 'REL',
    incremental: '1',
    previewSdkInt: 0,
    release: '15',
    sdkInt: 35,
  ),
  board: 'b',
  bootloader: 'b',
  brand: 'google',
  device: 'shiba',
  display: 'd',
  fingerprint: 'f',
  hardware: 'h',
  host: 'h',
  id: 'id',
  manufacturer: 'Google',
  model: 'Pixel 8',
  product: 'p',
  name: 'n',
  supported32BitAbis: const [],
  supported64BitAbis: const [],
  supportedAbis: const [],
  tags: 't',
  type: 'user',
  isPhysicalDevice: true,
  freeDiskSize: 0,
  totalDiskSize: 0,
  systemFeatures: const [],
  isLowRamDevice: false,
  physicalRamSize: 0,
  availableRamSize: 0,
);

PackageInfo _package({String buildNumber = '7'}) => PackageInfo(
  appName: 'MoodTune',
  packageName: 'com.moodtune',
  version: '1.0.0',
  buildNumber: buildNumber,
);

void main() {
  late _MockDeviceInfoPlugin plugin;
  var packageCalls = 0;

  setUpAll(talker.disable);
  tearDownAll(talker.enable);

  setUp(() {
    plugin = _MockDeviceInfoPlugin();
    packageCalls = 0;
  });

  Future<PackageInfo> package() async {
    packageCalls++;
    return _package();
  }

  test('reads iOS version, hardware model and app version', () async {
    when(() => plugin.iosInfo).thenAnswer((_) async => _iosInfo());

    final details = await DeviceContext(
      deviceInfo: plugin,
      packageInfo: package,
      platform: TargetPlatform.iOS,
    ).load();

    expect(
      details,
      const DeviceDetails(
        platform: 'ios',
        osVersion: '18.1',
        deviceModel: 'iPhone15,2',
        appVersion: '1.0.0+7',
      ),
    );
  });

  test('reads Android release and manufacturer + model', () async {
    when(() => plugin.androidInfo).thenAnswer((_) async => _androidInfo());

    final details = await DeviceContext(
      deviceInfo: plugin,
      packageInfo: package,
      platform: TargetPlatform.android,
    ).load();

    expect(
      details,
      const DeviceDetails(
        platform: 'android',
        osVersion: '15',
        deviceModel: 'Google Pixel 8',
        appVersion: '1.0.0+7',
      ),
    );
  });

  test('other platforms report only platform and app version', () async {
    final details = await DeviceContext(
      deviceInfo: plugin,
      packageInfo: () async => _package(buildNumber: ''),
      platform: TargetPlatform.macOS,
    ).load();

    expect(
      details,
      const DeviceDetails(platform: 'macos', appVersion: '1.0.0'),
    );
    verifyZeroInteractions(plugin);
  });

  test('never throws: unreadable fields are null', () async {
    when(() => plugin.iosInfo).thenThrow(Exception('no plugin'));

    final details = await DeviceContext(
      deviceInfo: plugin,
      packageInfo: () async => throw Exception('no package info'),
      platform: TargetPlatform.iOS,
    ).load();

    expect(details, const DeviceDetails(platform: 'ios'));
  });

  test('loads once and caches', () async {
    when(() => plugin.iosInfo).thenAnswer((_) async => _iosInfo());
    final context = DeviceContext(
      deviceInfo: plugin,
      packageInfo: package,
      platform: TargetPlatform.iOS,
    );

    await context.load();
    await context.load();

    verify(() => plugin.iosInfo).called(1);
    expect(packageCalls, 1);
  });

  test('defaults to the current target platform', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final details = await DeviceContext(
      deviceInfo: plugin,
      packageInfo: package,
    ).load();

    expect(details.platform, 'linux');
  });
}
