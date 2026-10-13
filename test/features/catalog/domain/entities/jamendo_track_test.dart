import 'package:flutter_test/flutter_test.dart';

import '../../catalog_fixtures.dart';

void main() {
  group('JamendoTrack', () {
    test('supports value equality', () {
      expect(buildJamendoTrack(), buildJamendoTrack());
      expect(buildJamendoTrack(), isNot(buildJamendoTrack(id: '2')));
      expect(
        buildJamendoTrack(),
        isNot(buildJamendoTrack(tags: const ['jazz'])),
      );
    });

    test('props include every field', () {
      final track = buildJamendoTrack();
      expect(track.props, [
        '1',
        'Sunny Day',
        'The Testers',
        '',
        const Duration(seconds: 125),
        const ['pop', 'happy'],
        'https://audio.example/1.mp3',
        'https://jamendo.example/track/1',
        true,
      ]);
    });
  });
}
