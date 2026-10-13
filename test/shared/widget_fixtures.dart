import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';

/// Shared fixtures for widget tests of reusable widgets.

HistoryEntry buildHistoryEntry({
  String id = 'h1',
  String title = 'Morning Mix',
  String? subtitle,
  String primaryMood = 'happy',
  double confidence = 0.87,
  DateTime? createdAt,
  HistoryEntryType type = HistoryEntryType.playlist,
}) {
  return HistoryEntry(
    id: id,
    title: title,
    subtitle: subtitle,
    primaryMood: primaryMood,
    confidence: confidence,
    createdAt: createdAt ?? DateTime(2025, 3, 14),
    type: type,
  );
}

const testAudioFeatures = UploadAudioFeatures(
  tempo: 120,
  beatStrength: 0.7,
  spectralCentroid: 2000,
  spectralRolloff: 4000,
  spectralBandwidth: 1500,
  harmonicRatio: 0.6,
  zeroCrossingRate: 0.1,
  rmsEnergy: 0.3,
  dynamicRange: 12,
  mfccMean: [1, 2, 3],
  durationSeconds: 180,
  energyLabel: 'High (0.84)',
  brightnessLabel: 'Bright (0.70)',
  textureLabel: 'Smooth (0.40)',
);

AudioUploadAnalysis buildAudioUploadAnalysis({
  String primaryMood = 'happy',
  double confidence = 0.85,
  List<String> descriptors = const ['upbeat', 'danceable'],
}) {
  return AudioUploadAnalysis(
    id: 'a1',
    filename: 'song.mp3',
    fileSizeBytes: 1024,
    durationSeconds: 180,
    mood: UploadMoodResult(
      primaryMood: primaryMood,
      moodScores: const {'happy': 0.85},
      confidence: confidence,
      reasoning: 'Bright and fast.',
      audioFeatures: testAudioFeatures,
      descriptors: descriptors,
    ),
    analysisMethod: 'librosa',
    processedAt: DateTime(2025, 3, 14),
    processingTimeSeconds: 2.5,
  );
}

JamendoTrack buildJamendoTrack({
  String id = 't1',
  String name = 'Sunny Day',
  String artistName = 'The Testers',
  String albumImageUrl = '',
  Duration duration = const Duration(minutes: 3, seconds: 5),
  List<String> tags = const ['pop', 'upbeat'],
  String audioUrl = 'https://example.com/audio.mp3',
}) {
  return JamendoTrack(
    id: id,
    name: name,
    artistName: artistName,
    albumImageUrl: albumImageUrl,
    duration: duration,
    tags: tags,
    audioUrl: audioUrl,
    jamendoPageUrl: 'https://jamendo.com/track/$id',
    audiodownloadAllowed: true,
  );
}

const testTrackAnalysis = TrackAnalysis(
  trackId: 'tr1',
  trackName: 'Electric Feel',
  artists: ['MGMT', 'Guest'],
  valence: 0.734,
  energy: 0.415,
  danceability: 0.8,
  moodLabel: 'Happy',
);
