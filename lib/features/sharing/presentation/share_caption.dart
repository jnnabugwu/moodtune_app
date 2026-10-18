import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_caption.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_content.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_target.dart';
import 'package:moodtune_app/features/sharing/domain/share_links.dart';
import 'package:moodtune_app/l10n/l10n.dart';

/// Builds the localized caption for a share (R7, AC8).
///
/// Uses the title only when [ShareContent.title] is set; the mapper already
/// dropped filenames. The link carries the target's UTM source (D1).
ShareCaption buildShareCaption(
  AppLocalizations l10n,
  ShareContent content,
  ShareTarget target,
) {
  final mood = localizedMoodWord(l10n, content.mood);
  final title = content.title;
  final body = title == null
      ? l10n.shareCaptionWithoutTitle(mood)
      : l10n.shareCaptionWithTitle(title, mood);
  return ShareCaption(body: body, link: ShareLinks.forTarget(target));
}

/// The mood word as it reads in a sentence ("Charged", "intensa").
String localizedMoodWord(AppLocalizations l10n, MoodIdentity mood) =>
    switch (mood) {
      MoodIdentity.upbeat => l10n.shareMoodUpbeat,
      MoodIdentity.serene => l10n.shareMoodSerene,
      MoodIdentity.charged => l10n.shareMoodCharged,
      MoodIdentity.reflective => l10n.shareMoodReflective,
    };
