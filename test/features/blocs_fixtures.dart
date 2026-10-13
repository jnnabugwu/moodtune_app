import 'package:moodtune_app/features/analysis/domain/domain.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';

/// Shared domain fixtures for BLoC tests.

const tAppUser = AppUser(id: 'user-1', email: 'sam@example.com');

final tPlaylistAnalysis = PlaylistAnalysis(
  id: 'analysis-1',
  playlistId: 'playlist-1',
  playlistName: 'Road Trip',
  createdAt: DateTime.utc(2025),
  moodResult: const MoodResult(
    primaryMood: 'happy',
    moodCategory: 'positive',
    moodDescriptors: ['bright'],
    confidence: 0.9,
    averages: AudioFeaturesSummary(
      valence: 0.8,
      energy: 0.7,
      danceability: 0.6,
      tempo: 120,
      acousticness: 0.1,
      instrumentalness: 0,
    ),
    moodDistribution: MoodDistribution(
      happy: 0.6,
      sad: 0.1,
      energetic: 0.2,
      calm: 0.05,
      danceable: 0.05,
    ),
    topTracks: [],
    trackCount: 10,
  ),
);

const tSongAnalysis = SongAnalysisResult(
  trackName: 'Song',
  artistName: 'Artist',
  trackId: 'track-1',
  mood: SongMoodResult(
    primaryMood: 'calm',
    confidence: 0.7,
    valence: 0.4,
    energy: 0.3,
  ),
  features: SongAudioFeatures(
    tempo: 90,
    energy: 0.3,
    valence: 0.4,
    danceability: 0.5,
    loudness: -8,
  ),
  success: true,
);

AudioUploadAnalysis buildUploadAnalysis({
  String id = 'upload-1',
  String? jamendoTrackUrl,
}) {
  return AudioUploadAnalysis(
    id: id,
    filename: 'song.mp3',
    fileSizeBytes: 1024,
    durationSeconds: 180,
    mood: const UploadMoodResult(
      primaryMood: 'energetic',
      moodScores: {'energetic': 0.8},
      confidence: 0.8,
      reasoning: 'fast tempo',
      audioFeatures: UploadAudioFeatures(
        tempo: 140,
        beatStrength: 0.9,
        spectralCentroid: 2000,
        spectralRolloff: 4000,
        spectralBandwidth: 1500,
        harmonicRatio: 0.5,
        zeroCrossingRate: 0.1,
        rmsEnergy: 0.3,
        dynamicRange: 12,
        mfccMean: [1, 2],
        durationSeconds: 180,
        energyLabel: 'high',
        brightnessLabel: 'bright',
        textureLabel: 'dense',
      ),
      descriptors: ['driving'],
    ),
    analysisMethod: 'librosa',
    processedAt: DateTime.utc(2025),
    processingTimeSeconds: 3.2,
    jamendoTrackUrl: jamendoTrackUrl,
  );
}

HistoryEntry buildHistoryEntry({
  required String id,
  required String mood,
  HistoryEntryType type = HistoryEntryType.playlist,
}) {
  return HistoryEntry(
    id: id,
    title: 'Title $id',
    primaryMood: mood,
    confidence: 0.5,
    createdAt: DateTime.utc(2025),
    type: type,
  );
}
