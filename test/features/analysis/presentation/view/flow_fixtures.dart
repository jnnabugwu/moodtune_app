import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/domain/entities/spotify_track.dart';

// Shared domain fixtures for analysis-flow page tests.

const uploadAudioFeatures = UploadAudioFeatures(
  tempo: 120,
  beatStrength: 0.6,
  spectralCentroid: 2000,
  spectralRolloff: 4000,
  spectralBandwidth: 1800,
  harmonicRatio: 0.5,
  zeroCrossingRate: 0.1,
  rmsEnergy: 0.3,
  dynamicRange: 12,
  mfccMean: [1, 2, 3],
  durationSeconds: 180,
  energyLabel: 'High (0.84)',
  brightnessLabel: 'Bright',
  textureLabel: 'Smooth',
);

const uploadMoodResult = UploadMoodResult(
  primaryMood: 'happy',
  moodScores: {'happy': 0.8, 'sad': 0.2},
  confidence: 0.84,
  reasoning: 'Upbeat tempo and bright timbre.',
  audioFeatures: uploadAudioFeatures,
  descriptors: ['upbeat', 'bright'],
);

final audioUploadAnalysis = AudioUploadAnalysis(
  id: 'upload-1',
  filename: 'song.mp3',
  fileSizeBytes: 3600000,
  durationSeconds: 180,
  mood: uploadMoodResult,
  analysisMethod: 'librosa',
  processedAt: DateTime.utc(2026),
  processingTimeSeconds: 4.2,
  title: 'Song',
  artist: 'Artist',
);

const songAnalysisResult = SongAnalysisResult(
  trackName: 'Track One',
  artistName: 'Artist A',
  trackId: 'track-1',
  mood: SongMoodResult(
    primaryMood: 'happy',
    confidence: 0.9,
    valence: 0.8,
    energy: 0.7,
  ),
  features: SongAudioFeatures(
    tempo: 120,
    energy: 0.7,
    valence: 0.8,
    danceability: 0.6,
    loudness: -5,
  ),
  success: true,
);

final playlistAnalysis = PlaylistAnalysis(
  id: 'analysis-1',
  playlistId: 'playlist-1',
  playlistName: 'Road Trip',
  moodResult: const MoodResult(
    primaryMood: 'happy',
    moodCategory: 'positive',
    moodDescriptors: ['upbeat'],
    confidence: 0.8,
    averages: AudioFeaturesSummary(
      valence: 0.7,
      energy: 0.6,
      danceability: 0.5,
      tempo: 118,
      acousticness: 0.2,
      instrumentalness: 0.1,
    ),
    moodDistribution: MoodDistribution(
      happy: 0.5,
      sad: 0.1,
      energetic: 0.2,
      calm: 0.1,
      danceable: 0.1,
    ),
    topTracks: [],
    trackCount: 12,
  ),
  createdAt: DateTime.utc(2026),
);

const spotifyTrack = SpotifyTrack(
  id: 'track-1',
  name: 'Track One',
  artists: ['Artist A', 'Artist B'],
);
