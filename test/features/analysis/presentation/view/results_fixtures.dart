import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

/// Shared domain fixtures for analysis page widget tests.

const testUploadFeatures = UploadAudioFeatures(
  tempo: 128.4,
  beatStrength: 0.7,
  spectralCentroid: 2100,
  spectralRolloff: 4200,
  spectralBandwidth: 1800,
  harmonicRatio: 0.6,
  zeroCrossingRate: 0.08,
  rmsEnergy: 0.2,
  dynamicRange: 12,
  mfccMean: [1, 2, 3],
  durationSeconds: 210,
  energyLabel: 'High (0.84)',
  brightnessLabel: 'Bright (0.71)',
  textureLabel: 'Smooth (0.40)',
);

UploadMoodResult testUploadMood({
  List<String> descriptors = const ['upbeat', 'danceable'],
  String reasoning = 'Fast tempo and bright timbre suggest an upbeat mood.',
}) => UploadMoodResult(
  primaryMood: 'upbeat',
  moodScores: const {'upbeat': 0.8, 'serene': 0.2},
  confidence: 0.82,
  reasoning: reasoning,
  audioFeatures: testUploadFeatures,
  descriptors: descriptors,
);

AudioUploadAnalysis testUploadAnalysis({
  String id = 'upload-1',
  String? artist = 'Test Artist',
  String? jamendoTrackUrl,
  List<String> descriptors = const ['upbeat', 'danceable'],
  String reasoning = 'Fast tempo and bright timbre suggest an upbeat mood.',
}) => AudioUploadAnalysis(
  id: id,
  filename: 'song.mp3',
  fileSizeBytes: 1024,
  durationSeconds: 210,
  title: 'Test Song',
  artist: artist,
  album: 'Test Album',
  mood: testUploadMood(descriptors: descriptors, reasoning: reasoning),
  analysisMethod: 'librosa',
  processedAt: DateTime(2024, 3, 15),
  processingTimeSeconds: 2.5,
  jamendoTrackUrl: jamendoTrackUrl,
);

const testTopTracks = [
  TrackAnalysis(
    trackId: 't1',
    trackName: 'First Track',
    artists: ['Artist A'],
    valence: 0.8,
    energy: 0.7,
    danceability: 0.6,
    moodLabel: 'happy',
  ),
  TrackAnalysis(
    trackId: 't2',
    trackName: 'Second Track',
    artists: ['Artist B', 'Artist C'],
    valence: 0.3,
    energy: 0.4,
    danceability: 0.5,
    moodLabel: 'calm',
  ),
];

PlaylistAnalysis testPlaylistAnalysis({
  String id = 'analysis-1',
  String playlistName = 'Road Trip',
  List<String> descriptors = const ['bright', 'energetic'],
}) => PlaylistAnalysis(
  id: id,
  playlistId: 'playlist-1',
  playlistName: playlistName,
  moodResult: MoodResult(
    primaryMood: 'Euphoric',
    moodCategory: 'positive',
    moodDescriptors: descriptors,
    confidence: 87.25,
    averages: const AudioFeaturesSummary(
      valence: 0.654,
      energy: 0.712,
      danceability: 0.5,
      tempo: 121.37,
      acousticness: 0.1,
      instrumentalness: 0,
    ),
    moodDistribution: const MoodDistribution(
      happy: 0.5,
      sad: 0.1,
      energetic: 0.2,
      calm: 0.1,
      danceable: 0.1,
    ),
    topTracks: testTopTracks,
    trackCount: 42,
  ),
  createdAt: DateTime(2024, 3, 15, 10, 30),
  userId: 'user-1',
);

const testSongAnalysis = SongAnalysisResult(
  trackName: 'Blinding Lights',
  artistName: 'The Weeknd',
  trackId: 'track-1',
  mood: SongMoodResult(
    primaryMood: 'energetic',
    confidence: 0.876,
    valence: 0.33,
    energy: 0.73,
  ),
  features: SongAudioFeatures(
    tempo: 171.2,
    energy: 0.734,
    valence: 0.334,
    danceability: 0.514,
    loudness: -5.934,
  ),
  success: true,
);

HistoryEntry testHistoryEntry(
  int i, {
  String mood = 'upbeat',
  String? subtitle,
  HistoryEntryType type = HistoryEntryType.song,
}) => HistoryEntry(
  id: 'h$i',
  title: 'Entry $i',
  subtitle: subtitle,
  primaryMood: mood,
  confidence: 0.75,
  createdAt: DateTime(2024, 1, 1 + (i % 28)),
  type: type,
);

/// [count] history entries titled "Entry 0", "Entry 1", ...
List<HistoryEntry> testHistory(int count) => [
  for (var i = 0; i < count; i++) testHistoryEntry(i),
];
