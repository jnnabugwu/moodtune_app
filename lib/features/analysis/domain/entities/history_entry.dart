import 'package:equatable/equatable.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';

enum HistoryEntryType { playlist, song }

/// Flat, display-ready history item that represents either a playlist analysis
/// or a song analysis. Used by the History screen so it can show a unified
/// feed without caring about the underlying type.
class HistoryEntry extends Equatable {
  const HistoryEntry({
    required this.id,
    required this.title,
    required this.primaryMood,
    required this.confidence,
    required this.createdAt,
    required this.type,
    this.subtitle,
    this.comparison,
    this.titleFromFilename = false,
  });

  final String id;

  /// Playlist name for playlist entries; track name for song entries.
  final String title;

  /// Artist name for song entries; null for playlist entries.
  final String? subtitle;

  /// The mood the results screen showed.
  final String primaryMood;

  /// Null for on-device results: their probabilities are overconfident and
  /// never shown until recalibrated (ROADMAP OD-5).
  final double? confidence;
  final DateTime createdAt;
  final HistoryEntryType type;

  /// Both engines' moods, for upload and catalog results saved with them.
  /// Null for playlists and older rows.
  final EngineComparison? comparison;

  /// True when [title] is an upload's filename because the user typed no
  /// title. Shares leave such titles out.
  final bool titleFromFilename;

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    primaryMood,
    confidence,
    createdAt,
    type,
    comparison,
    titleFromFilename,
  ];
}

/// The backend's and the on-device mood for one result, plus the user's
/// "Does this feel right?" answer about the mood that was shown.
class EngineComparison extends Equatable {
  const EngineComparison({
    required this.backendMood,
    required this.displayedSource,
    this.onDeviceMood,
    this.agrees,
    this.userMood,
  });

  /// Backend label (`happy`, `energetic`, `calm`, `angry` or `sad`).
  final String backendMood;

  /// On-device label (same vocabulary), or null when it didn't run.
  final String? onDeviceMood;

  /// Which engine's mood was shown, and so which one [agrees] is about.
  final MoodSource displayedSource;

  /// Null until the user answers.
  final bool? agrees;

  /// The display bucket the user picked on a thumbs-down, if any.
  final String? userMood;

  @override
  List<Object?> get props => [
    backendMood,
    onDeviceMood,
    displayedSource,
    agrees,
    userMood,
  ];
}
