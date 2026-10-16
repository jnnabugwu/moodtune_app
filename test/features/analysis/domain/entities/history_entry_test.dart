import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/history_entry.dart';

final _date = DateTime.utc(2025, 6);

HistoryEntry _entry({
  String id = 'id',
  String title = 'title',
  String? subtitle = 'sub',
  String primaryMood = 'Happy',
  double confidence = 0.5,
  DateTime? createdAt,
  HistoryEntryType type = HistoryEntryType.song,
}) => HistoryEntry(
  id: id,
  title: title,
  subtitle: subtitle,
  primaryMood: primaryMood,
  confidence: confidence,
  createdAt: createdAt ?? _date,
  type: type,
);

void main() {
  group('HistoryEntryType', () {
    test('has playlist and song values', () {
      expect(HistoryEntryType.values, [
        HistoryEntryType.playlist,
        HistoryEntryType.song,
      ]);
    });
  });

  group('HistoryEntry', () {
    test('instances with equal values are equal', () {
      expect(_entry(), _entry());
      expect(_entry().hashCode, _entry().hashCode);
    });

    test('subtitle is optional and defaults to null', () {
      final entry = HistoryEntry(
        id: 'id',
        title: 'title',
        primaryMood: 'Happy',
        confidence: 0.5,
        createdAt: _date,
        type: HistoryEntryType.playlist,
      );

      expect(entry.subtitle, isNull);
    });

    test('props lists fields in declaration order', () {
      expect(_entry().props, [
        'id',
        'title',
        'sub',
        'Happy',
        0.5,
        _date,
        HistoryEntryType.song,
        null,
      ]);
    });

    test('every field participates in equality', () {
      final variants = [
        _entry(id: 'x'),
        _entry(title: 'x'),
        _entry(subtitle: null),
        _entry(primaryMood: 'x'),
        _entry(confidence: 0.9),
        _entry(createdAt: DateTime.utc(2000)),
        _entry(type: HistoryEntryType.playlist),
      ];
      for (final v in variants) {
        expect(v, isNot(_entry()));
      }
    });
  });
}
