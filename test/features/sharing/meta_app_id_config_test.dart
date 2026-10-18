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
    // A value being set, not a mention ("never put the App Secret here").
    final secret = RegExp(
      'app_?secret\\w*["\']?\\s*[:=]',
      caseSensitive: false,
    );
    final files = [
      File('env.example'),
      for (final dir in ['lib', 'ios/Runner', 'android/app/src'])
        ...Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) => RegExp(r'\.(dart|swift|kt|plist|xml)$').hasMatch(f.path),
            ),
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
