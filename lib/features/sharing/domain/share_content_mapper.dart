import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/analysis/domain/entities/history_entry.dart';
import 'package:moodtune_app/features/analysis/domain/entities/result_history_record.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_content.dart';

/// Builds [ShareContent] from the analysis entities (R8, R12).
///
/// This is the only place sharing reads an analysis, so the privacy rule
/// lives here: the displayed mood, descriptors, title and artist go through;
/// filenames, IDs, confidence and engine comparisons never do.
abstract final class ShareContentMapper {
  /// From the result shown on the results screen. Uses
  /// `analysis.mood.primaryMood` as displayed; for on-device results the
  /// pills under the hero card are sound tags, which are not descriptors,
  /// so they are not shared.
  static ShareContent fromAnalysis(AudioUploadAnalysis analysis) =>
      ShareContent(
        mood: MoodTheme.fromString(analysis.mood.primaryMood),
        title: cleanTitle(analysis.title),
        artist: cleanArtist(analysis.artist),
        descriptors: cleanDescriptors(
          analysis.mood.source == MoodSource.onDevice
              ? const []
              : analysis.mood.descriptors,
        ),
      );

  /// From a saved result. Records keep no descriptors, so the card gets
  /// no tag row (R12). A title made from the filename is left out.
  static ShareContent fromHistoryRecord(ResultHistoryRecord record) =>
      ShareContent(
        mood: MoodTheme.fromString(record.displayedMood),
        title: record.titleFromFilename ? null : cleanTitle(record.title),
        artist: cleanArtist(record.artist),
      );

  /// From a History screen row. [HistoryEntry.subtitle] is the artist for
  /// song rows. A title made from the filename is left out.
  static ShareContent fromHistoryEntry(HistoryEntry entry) => ShareContent(
    mood: MoodTheme.fromString(entry.primaryMood),
    title: entry.titleFromFilename ? null : cleanTitle(entry.title),
    artist: cleanArtist(entry.subtitle),
  );

  /// Trims [title]; returns null when empty or when it looks like a raw
  /// filename such as `track_01.mp3` (R7).
  static String? cleanTitle(String? title) {
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty || looksLikeFilename(trimmed)) return null;
    return trimmed;
  }

  static String? cleanArtist(String? artist) {
    final trimmed = artist?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Trims, drops blanks and keeps the first [ShareContent.maxDescriptors].
  static List<String> cleanDescriptors(List<String> descriptors) => descriptors
      .map((d) => d.trim())
      .where((d) => d.isNotEmpty)
      .take(ShareContent.maxDescriptors)
      .toList(growable: false);

  static final _audioExtension = RegExp(
    r'\.(mp3|m4a|aac|wav|flac|ogg|oga|opus|aiff?|wma|alac|mp4|caf)$',
    caseSensitive: false,
  );

  /// A leading `/`, `~/` or `./`, as in `/Users/me/song`. A slash inside a
  /// title (`Love/Hate`) is not a path.
  static final _pathPrefix = RegExp(r'^(/|~/|\./)');

  /// True for values that are clearly a file name rather than a song title:
  /// an audio extension, a path, or no spaces plus underscores.
  static bool looksLikeFilename(String value) {
    if (_audioExtension.hasMatch(value)) return true;
    if (_pathPrefix.hasMatch(value) || value.contains(r'\')) return true;
    return !value.contains(' ') && value.contains('_');
  }
}
