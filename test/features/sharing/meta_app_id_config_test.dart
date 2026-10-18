import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// AC9 (R11): the Meta App ID comes from `--dart-define`, is documented in
/// `env.example`, and no Meta App Secret is anywhere in the repo.
void main() {
  test('META_APP_ID is read with String.fromEnvironment (AC9)', () {
    final injector = File('lib/di/injector.dart').readAsStringSync();
    expect(injector, contains("String.fromEnvironment('META_APP_ID')"));
  });

  test('env.example documents META_APP_ID (AC9)', () {
    expect(File('env.example').readAsStringSync(), contains('META_APP_ID'));
  });

  test('no Meta App Secret is in the app or native config (AC9)', () {
    // Any identifier naming an app secret (META_APP_SECRET, appSecret,
    // <key>FacebookAppSecret</key>, name="meta_app_secret"). Prose such as
    // "never put the Meta App Secret here" has a space and doesn't match.
    final secret = RegExp('app_?secret', caseSensitive: false);
    final config = RegExp(
      r'\.(dart|swift|kt|kts|gradle|plist|xml|xcconfig|entitlements|properties)$',
    );
    bool generated(String path) =>
        RegExp(r'/(build|Pods|\.gradle|\.symlinks)/').hasMatch(path);
    final files = [
      File('env.example'),
      for (final dir in ['lib', 'ios', 'android'])
        ...Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => config.hasMatch(f.path) && !generated(f.path)),
    ];
    for (final file in files) {
      expect(
        secret.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
  });
}
