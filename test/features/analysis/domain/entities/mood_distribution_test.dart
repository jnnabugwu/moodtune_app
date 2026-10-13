import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/mood_distribution.dart';

MoodDistribution _dist({
  double happy = 0.1,
  double sad = 0.2,
  double energetic = 0.3,
  double calm = 0.4,
  double danceable = 0.5,
}) => MoodDistribution(
  happy: happy,
  sad: sad,
  energetic: energetic,
  calm: calm,
  danceable: danceable,
);

void main() {
  group('MoodDistribution', () {
    test('instances with equal values are equal', () {
      expect(_dist(), _dist());
      expect(_dist().hashCode, _dist().hashCode);
    });

    test('props lists buckets in declaration order', () {
      expect(_dist().props, [0.1, 0.2, 0.3, 0.4, 0.5]);
    });

    test('every bucket participates in equality', () {
      final variants = [
        _dist(happy: 9),
        _dist(sad: 9),
        _dist(energetic: 9),
        _dist(calm: 9),
        _dist(danceable: 9),
      ];
      for (final v in variants) {
        expect(v, isNot(_dist()));
      }
    });
  });
}
