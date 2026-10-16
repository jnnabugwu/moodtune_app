import 'package:equatable/equatable.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';

/// Where a saved result came from.
enum ResultHistorySource { upload, catalog }

/// A finished upload or catalog result, saved to the signed-in user's
/// history with both engines' moods. Holds no audio.
class ResultHistoryRecord extends Equatable {
  const ResultHistoryRecord({
    required this.source,
    required this.title,
    required this.displayedMood,
    required this.displayedSource,
    required this.backendMood,
    this.artist,
    this.trackId,
    this.onDeviceMood,
    this.confidence,
    this.observationId,
  });

  /// Builds the record from the backend's own [backend] result and the
  /// [displayed] one (which may carry the on-device mood).
  factory ResultHistoryRecord.fromResult({
    required ResultHistorySource source,
    required String title,
    required AudioUploadAnalysis backend,
    required AudioUploadAnalysis displayed,
    String? onDeviceMood,
    String? artist,
    String? trackId,
    String? observationId,
  }) {
    final shownOnDevice = displayed.mood.source == MoodSource.onDevice;
    return ResultHistoryRecord(
      source: source,
      title: title,
      artist: artist,
      trackId: trackId,
      displayedMood: displayed.mood.primaryMood,
      displayedSource: displayed.mood.source,
      backendMood: backend.mood.primaryMood,
      onDeviceMood: onDeviceMood,
      // Only the backend's confidence is shown anywhere.
      confidence: shownOnDevice ? null : backend.mood.confidence,
      observationId: observationId,
    );
  }

  final ResultHistorySource source;
  final String title;
  final String? artist;
  final String? trackId;
  final String displayedMood;
  final MoodSource displayedSource;
  final String backendMood;
  final String? onDeviceMood;
  final double? confidence;
  final String? observationId;

  @override
  List<Object?> get props => [
    source,
    title,
    artist,
    trackId,
    displayedMood,
    displayedSource,
    backendMood,
    onDeviceMood,
    confidence,
    observationId,
  ];
}
