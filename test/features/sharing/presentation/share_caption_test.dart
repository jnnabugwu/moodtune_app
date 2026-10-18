import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/sharing/sharing.dart';
import 'package:moodtune_app/l10n/l10n.dart';

import '../../analysis/presentation/view/results_fixtures.dart';
import '../sharing_fixtures.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final es = lookupAppLocalizations(const Locale('es'));

  group('buildShareCaption', () {
    test('names the title and mood and appends the target link (R7)', () {
      final caption = buildShareCaption(en, testShareContent(), ShareTarget.x);

      expect(
        caption.body,
        'My song "Blinding Lights" feels Charged 🎧 '
        "Find your song's mood on MoodTune",
      );
      expect(
        caption.link.toString(),
        'https://getmoodtune.com/?utm_source=x&utm_medium=share',
      );
      expect(caption.full, '${caption.body} ${caption.link}');
    });

    test('leaves the title out when there is none', () {
      final caption = buildShareCaption(
        en,
        testShareContent(title: null, mood: MoodIdentity.serene),
        ShareTarget.system,
      );

      expect(
        caption.body,
        "This song feels Serene 🎧 Find your song's mood on MoodTune",
      );
      expect(caption.body, isNot(contains('"')));
    });

    test('is localized in Spanish (AC8)', () {
      final caption = buildShareCaption(
        es,
        testShareContent(mood: MoodIdentity.reflective),
        ShareTarget.instagramStory,
      );

      expect(
        caption.body,
        'Mi canción "Blinding Lights" suena reflexiva 🎧 '
        'Descubre el mood de tu canción en MoodTune',
      );
      expect(caption.link.queryParameters['utm_source'], 'instagram_story');
    });

    test('has a mood word for every identity in both locales', () {
      for (final mood in MoodIdentity.values) {
        expect(localizedMoodWord(en, mood), isNotEmpty);
        expect(localizedMoodWord(es, mood), isNotEmpty);
      }
    });

    // AC6: the caption built from a real analysis carries nothing private.
    test('never includes the filename, IDs or engine details', () {
      // The title is the raw filename, so the leak guard has work to do.
      final analysis = testUploadAnalysis(id: 'obs-99', title: 'song.mp3');
      final caption = buildShareCaption(
        en,
        ShareContentMapper.fromAnalysis(analysis),
        ShareTarget.x,
      );

      expect(caption.full, isNot(contains(analysis.filename)));
      expect(caption.full, isNot(contains('song.mp3')));
      expect(caption.full, isNot(contains('obs-99')));
      expect(caption.full, isNot(contains('${analysis.mood.confidence}')));
      expect(caption.full, isNot(contains('%')));
      expect(caption.full, isNot(contains('backend')));
      expect(caption.full, isNot(contains('device')));
      expect(caption.full, isNot(contains('@')));
    });
  });
}
