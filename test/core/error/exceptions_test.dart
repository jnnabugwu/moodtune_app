import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/error/exceptions.dart';

void main() {
  group('exceptions', () {
    test('ServerException keeps message and prefixes toString', () {
      const e = ServerException('boom');

      expect(e, isA<Exception>());
      expect(e.message, 'boom');
      expect(e.toString(), 'ServerException: boom');
    });

    test('CacheException keeps message and prefixes toString', () {
      const e = CacheException('disk full');

      expect(e, isA<Exception>());
      expect(e.message, 'disk full');
      expect(e.toString(), 'CacheException: disk full');
    });

    test('SpotifyAuthException keeps message and prefixes toString', () {
      const e = SpotifyAuthException('denied');

      expect(e, isA<Exception>());
      expect(e.message, 'denied');
      expect(e.toString(), 'SpotifyAuthException: denied');
    });

    test('wrap runtime messages (non-const construction)', () {
      final builders = <Exception Function(String)>[
        ServerException.new,
        CacheException.new,
        SpotifyAuthException.new,
      ];
      final rendered = builders.map((build) => build('dyn').toString());

      expect(rendered, [
        'ServerException: dyn',
        'CacheException: dyn',
        'SpotifyAuthException: dyn',
      ]);
    });

    test('can be thrown and caught as Exception', () {
      expect(
        () => throw const ServerException('x'),
        throwsA(
          isA<ServerException>().having((e) => e.message, 'message', 'x'),
        ),
      );
    });
  });
}
