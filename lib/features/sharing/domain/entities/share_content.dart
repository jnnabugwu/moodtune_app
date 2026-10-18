import 'package:equatable/equatable.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';

/// What goes on the share card and into the caption (R2, R7).
///
/// Holds only what the user saw: the displayed mood, up to three
/// descriptors, and the track's title and artist. Nothing else from an
/// analysis (filename, IDs, confidence, engine details) may reach it (R8).
/// Build one through `ShareContentMapper` rather than by hand.
class ShareContent extends Equatable {
  const ShareContent({
    required this.mood,
    this.title,
    this.artist,
    this.descriptors = const [],
  });

  /// At most this many descriptor tags are shown on the card.
  static const maxDescriptors = 3;

  /// The mood the results screen showed, never recomputed.
  final MoodIdentity mood;

  /// Track title, or null when unknown or when it looked like a filename.
  final String? title;

  /// Artist name, or null when unknown.
  final String? artist;

  /// Descriptor tags in display order; empty for history shares (R12).
  final List<String> descriptors;

  @override
  List<Object?> get props => [mood, title, artist, descriptors];
}
