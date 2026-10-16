import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/error/failures.dart';

void main() {
  group('Failure', () {
    test('each subtype exposes its message and props', () {
      const failures = <Failure>[
        ServerFailure('server'),
        NetworkFailure('network'),
        CacheFailure('cache'),
        SpotifyAuthFailure('spotify'),
      ];

      expect(failures.map((f) => f.message), [
        'server',
        'network',
        'cache',
        'spotify',
      ]);
      for (final f in failures) {
        expect(f.props, [f.message]);
      }
    });

    test('subtypes wrap runtime messages (non-const construction)', () {
      final builders = <Failure Function(String)>[
        ServerFailure.new,
        NetworkFailure.new,
        CacheFailure.new,
        SpotifyAuthFailure.new,
      ];
      for (final build in builders) {
        final message = 'msg-${build.hashCode}';
        expect(build(message).message, message);
      }
    });

    test('same type and message are equal', () {
      expect(const ServerFailure('x'), const ServerFailure('x'));
      expect(
        const NetworkFailure('x').hashCode,
        const NetworkFailure('x').hashCode,
      );
    });

    test('different messages are not equal', () {
      expect(const CacheFailure('a'), isNot(const CacheFailure('b')));
    });

    test('different subtypes with the same message are not equal', () {
      expect(const ServerFailure('x'), isNot(const NetworkFailure('x')));
      expect(const SpotifyAuthFailure('x'), isNot(const CacheFailure('x')));
    });
  });
}
