import 'package:equatable/equatable.dart';

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
  });

  final String id;

  /// Playlist name for playlist entries; track name for song entries.
  final String title;

  /// Artist name for song entries; null for playlist entries.
  final String? subtitle;

  final String primaryMood;
  final double confidence;
  final DateTime createdAt;
  final HistoryEntryType type;

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    primaryMood,
    confidence,
    createdAt,
    type,
  ];
}
