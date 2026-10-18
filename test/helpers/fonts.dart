import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled Inter Tight weights so goldens render real glyphs
/// instead of the test font. Call from `setUpAll`.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Inter Tight');
  for (final file in const [
    'assets/fonts/InterTight-Medium.ttf',
    'assets/fonts/InterTight-SemiBold.ttf',
    'assets/fonts/InterTight-Bold.ttf',
  ]) {
    final bytes = File(file).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
