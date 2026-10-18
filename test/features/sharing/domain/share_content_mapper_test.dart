import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/sharing/sharing.dart';

import '../../analysis/presentation/view/results_fixtures.dart';

void main() {
  group('ShareContentMapper.fromAnalysis', () {
    test('keeps the displayed mood, title, artist and 3 descriptors', () {
      final analysis = testUploadAnalysis(
        descriptors: const ['upbeat', 'danceable', 'bright', 'loud'],
      );

      final content = ShareContentMapper.fromAnalysis(analysis);

      expect(content.mood, MoodIdentity.upbeat);
      expect(content.title, 'Test Song');
      expect(content.artist, 'Test Artist');
      expect(content.descriptors, ['upbeat', 'danceable', 'bright']);
    });

    test('uses the displayed mood, not the backend one (R8)', () {
      final backend = testUploadAnalysis();
      final shown = backend.copyWith(
        mood: backend.mood.copyWith(
          primaryMood: 'serene',
          source: MoodSource.onDevice,
          backendPrimaryMood: 'upbeat',
          soundTags: const ['vocals', 'piano'],
        ),
      );

      final content = ShareContentMapper.fromAnalysis(shown);

      expect(content.mood, MoodIdentity.serene);
      // Sound tags describe what was heard, not the mood; not shared.
      expect(content.descriptors, isEmpty);
    });

    test('drops a filename-looking title and a missing artist', () {
      final analysis = AudioUploadAnalysis(
        id: 'upload-9',
        filename: 'track_01.mp3',
        fileSizeBytes: 1,
        durationSeconds: 1,
        title: 'track_01.mp3',
        mood: testUploadMood(),
        analysisMethod: 'librosa',
        processedAt: DateTime(2024),
        processingTimeSeconds: 1,
      );

      final content = ShareContentMapper.fromAnalysis(analysis);

      expect(content.title, isNull);
      expect(content.artist, isNull);
    });

    // AC6: nothing private can reach the card or caption.
    test('never carries filename, IDs, confidence or engine fields', () {
      final backend = testUploadAnalysis(id: 'observation-42');
      final analysis = backend.copyWith(
        mood: backend.mood.copyWith(
          source: MoodSource.onDevice,
          backendPrimaryMood: 'charged',
        ),
      );

      final content = ShareContentMapper.fromAnalysis(analysis);
      final dump = [
        content.mood.name,
        content.title,
        content.artist,
        ...content.descriptors,
      ].join(' ');

      expect(dump, isNot(contains(analysis.filename)));
      expect(dump, isNot(contains(analysis.id)));
      expect(dump, isNot(contains('${analysis.fileSizeBytes}')));
      expect(dump, isNot(contains('${analysis.mood.confidence}')));
      expect(dump, isNot(contains('charged')));
      expect(dump, isNot(contains('backend')));
      expect(dump, isNot(contains('onDevice')));
      expect(content.props, hasLength(4));
    });
  });

  group('ShareContentMapper.fromHistoryRecord', () {
    test('uses displayedMood, title and artist with no descriptors', () {
      const record = ResultHistoryRecord(
        source: ResultHistorySource.upload,
        title: 'Night Drive',
        artist: 'Someone',
        displayedMood: 'reflective',
        displayedSource: MoodSource.onDevice,
        backendMood: 'upbeat',
        onDeviceMood: 'reflective',
        confidence: 0.91,
        observationId: 'obs-1',
      );

      final content = ShareContentMapper.fromHistoryRecord(record);

      expect(
        content,
        const ShareContent(
          mood: MoodIdentity.reflective,
          title: 'Night Drive',
          artist: 'Someone',
        ),
      );
      expect(content.descriptors, isEmpty);
    });

    test('leaves out a title made from the filename', () {
      const record = ResultHistoryRecord(
        source: ResultHistorySource.upload,
        title: 'Summer Vibes',
        titleFromFilename: true,
        displayedMood: 'happy',
        displayedSource: MoodSource.backend,
        backendMood: 'happy',
      );

      expect(ShareContentMapper.fromHistoryRecord(record).title, isNull);
    });
  });

  group('ShareContentMapper.fromHistoryEntry', () {
    test('maps a song row; the subtitle is the artist', () {
      final content = ShareContentMapper.fromHistoryEntry(
        testHistoryEntry(3, mood: 'calm', subtitle: 'Artist Z'),
      );

      expect(content.mood, MoodIdentity.serene);
      expect(content.title, 'Entry 3');
      expect(content.artist, 'Artist Z');
      expect(content.descriptors, isEmpty);
    });

    test('leaves out a title made from the filename', () {
      final entry = HistoryEntry(
        id: 'h1',
        title: 'Summer Vibes',
        primaryMood: 'happy',
        confidence: null,
        createdAt: DateTime(2026, 10, 18),
        type: HistoryEntryType.song,
        titleFromFilename: true,
      );

      expect(ShareContentMapper.fromHistoryEntry(entry).title, isNull);
    });

    test('leaves the artist null when there is no subtitle', () {
      final content = ShareContentMapper.fromHistoryEntry(testHistoryEntry(1));

      expect(content.artist, isNull);
    });
  });

  group('ShareContentMapper.looksLikeFilename', () {
    test('matches audio extensions, paths and underscore names', () {
      for (final value in [
        'track_01.mp3',
        'song.M4A',
        'recording.wav',
        '/Users/me/Music/song',
        '~/Downloads/song',
        r'C:\music\song',
        'my_song_final',
      ]) {
        expect(
          ShareContentMapper.looksLikeFilename(value),
          isTrue,
          reason: value,
        );
      }
    });

    test('accepts ordinary titles', () {
      for (final value in [
        'Blinding Lights',
        'Mr. Brightside',
        'Snake_Eyes (Live)',
        '22',
        'Ænima',
        'Love/Hate',
        'AC/DC Live',
      ]) {
        expect(
          ShareContentMapper.looksLikeFilename(value),
          isFalse,
          reason: value,
        );
      }
    });
  });

  group('cleanDescriptors', () {
    test('trims, drops blanks and caps at three', () {
      expect(
        ShareContentMapper.cleanDescriptors(const [
          ' a ',
          '',
          'b',
          '  ',
          'c',
          'd',
        ]),
        ['a', 'b', 'c'],
      );
    });
  });

  group('ShareLinks', () {
    test('points at getmoodtune.com with per-target UTM parameters', () {
      expect(
        ShareLinks.forTarget(ShareTarget.instagramStory).toString(),
        'https://getmoodtune.com/?utm_source=instagram_story&utm_medium=share',
      );
      expect(
        ShareLinks.forTarget(ShareTarget.x).toString(),
        'https://getmoodtune.com/?utm_source=x&utm_medium=share',
      );
      expect(
        ShareLinks.forTarget(ShareTarget.system).toString(),
        'https://getmoodtune.com/?utm_source=share_sheet&utm_medium=share',
      );
    });
  });
}
