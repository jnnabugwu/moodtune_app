# Catalog Track Analysis — Option A Implementation Plan

**Status:** Approved, pending implementation  
**Date:** 2026-05-20  
**Problem:** Catalog track analysis returns 403 Forbidden because `AnalyzeSongRequested(track.id)` calls `POST /api/v1/song/analyze/{trackId}` — an endpoint that requires Spotify OAuth and a Spotify track ID. Jamendo track IDs have neither.

---

## Solution Overview

Add a dedicated unauthenticated endpoint `POST /api/v1/catalog/analyze`. It accepts a Jamendo audio stream URL, downloads the audio server-side, and runs it through the same rich librosa pipeline used by `/audio-upload/analyze`. The Flutter side gets a new `CatalogTrackAnalyzeRequested` BLoC event that produces `AudioUploadAnalysis` — so the Results screen can use `MoodHeroCard`, descriptors, and reasoning for catalog results, replacing the current broken `SongAnalysisResult` dual-type handling.

---

## Backend Changes (`moodtune-backend`)

### Step 1 — Verify `httpx` dependency
**File:** `requirements.txt`  
Confirm `httpx>=0.27` is present. It's needed to download audio from the Jamendo stream URL asynchronously.

---

### Step 2 — New request schema
**File:** `app/schemas/catalog_analysis.py` *(new)*

```python
from pydantic import BaseModel

class CatalogAnalyzeRequest(BaseModel):
    audio_url: str          # Jamendo audiodownload stream URL
    track_id: str           # Jamendo track ID (used for temp filename)
    track_name: str
    artist_name: str
    jamendo_page_url: str = ""  # Attribution link — passed through to response
```

---

### Step 3 — Add `jamendo_track_url` to response schema
**File:** `app/schemas/audio_analysis.py`

Add one field to `AudioAnalysisResponse`:
```python
jamendo_track_url: Optional[str] = None
```
This is a non-breaking nullable addition. The existing `/audio-upload/analyze` endpoint's response will include the field as `null` with no other changes needed.

---

### Step 4 — New catalog router
**File:** `app/api/v1/catalog.py` *(new)*

```python
import time, uuid
from datetime import datetime, timezone
import httpx
from fastapi import APIRouter, HTTPException
from app.schemas.catalog_analysis import CatalogAnalyzeRequest
from app.schemas.audio_analysis import (
    AudioAnalysisResponse, MoodFromAudio, AudioFeatures
)
from app.services.audio_analysis_service import audio_analysis_service
from app.core.config import settings

router = APIRouter()

@router.post("/analyze", response_model=AudioAnalysisResponse)
async def analyze_catalog_track(body: CatalogAnalyzeRequest):
    # 1. Download audio from Jamendo
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.get(body.audio_url)
            resp.raise_for_status()
    except httpx.HTTPError as e:
        raise HTTPException(status_code=502, detail=f"Could not fetch audio: {e}")

    file_data = resp.content
    filename = f"{body.track_id}.mp3"

    # 2. Validate size (<= MAX_UPLOAD_SIZE_MB)
    if len(file_data) > settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Track exceeds size limit")

    # 3. Run rich analysis pipeline (same as /audio-upload/analyze)
    start = time.time()
    features = audio_analysis_service.analyze_uploaded_audio(file_data, filename)
    mood_summary = audio_analysis_service.determine_upload_mood(features)
    processing_time = time.time() - start

    # 4. Build and return response
    audio_features = AudioFeatures(**features)
    mood = MoodFromAudio(
        primary_mood=mood_summary["primary_mood"],
        mood_scores=mood_summary["mood_scores"],
        confidence=mood_summary["confidence"],
        reasoning=mood_summary["reasoning"],
        audio_features=audio_features,
        descriptors=mood_summary.get("descriptors", []),
    )
    return AudioAnalysisResponse(
        id=uuid.uuid4(),
        user_id=None,
        filename=body.track_name,
        file_size_bytes=len(file_data),
        duration_seconds=audio_features.duration_seconds,
        title=body.track_name,
        artist=body.artist_name,
        mood=mood,
        analysis_method="catalog_stream",
        processed_at=datetime.now(timezone.utc),
        processing_time_seconds=round(processing_time, 2),
        jamendo_track_url=body.jamendo_page_url or None,
    )
```

---

### Step 5 — Register router
**File:** `app/api/v1/api.py`

```python
from app.api.v1 import catalog
api_router.include_router(catalog.router, prefix="/catalog", tags=["catalog"])
```

Final endpoint path: `POST /api/v1/catalog/analyze`

---

## Flutter Changes (`moodtune_app`)

### Step 6 — Add new state fields
**File:** `lib/features/analysis/presentation/bloc/analysis_state.dart`

Add enum (alongside existing `AnalysisStatus` and `UploadStatus`):
```dart
enum CatalogAnalysisStatus { initial, analyzing, success, error }
```

Add fields to `AnalysisState`:
```dart
final CatalogAnalysisStatus catalogStatus;   // default: initial
final AudioUploadAnalysis? currentCatalogAnalysis;
final String? catalogError;
```

Update constructor defaults, `copyWith`, and `props` accordingly.

---

### Step 7 — Add new event
**File:** `lib/features/analysis/presentation/bloc/analysis_event.dart`

```dart
class CatalogTrackAnalyzeRequested extends AnalysisEvent {
  const CatalogTrackAnalyzeRequested({
    required this.audioUrl,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.jamendoPageUrl,
  });

  final String audioUrl;
  final String trackId;
  final String trackName;
  final String artistName;
  final String jamendoPageUrl;

  @override
  List<Object?> get props =>
      [audioUrl, trackId, trackName, artistName, jamendoPageUrl];
}
```

---

### Step 8 — Add BLoC handler
**File:** `lib/features/analysis/presentation/bloc/analysis_bloc.dart`

Register in constructor:
```dart
on<CatalogTrackAnalyzeRequested>(_onCatalogTrackAnalyzeRequested);
```

Handler:
```dart
Future<void> _onCatalogTrackAnalyzeRequested(
  CatalogTrackAnalyzeRequested event,
  Emitter<AnalysisState> emit,
) async {
  emit(state.copyWith(
    catalogStatus: CatalogAnalysisStatus.analyzing,
    catalogError: null,
    currentCatalogAnalysis: null,
  ));

  final result = await _repository.analyzeCatalogTrack(
    audioUrl: event.audioUrl,
    trackId: event.trackId,
    trackName: event.trackName,
    artistName: event.artistName,
    jamendoPageUrl: event.jamendoPageUrl,
  );

  result.fold(
    (failure) => emit(state.copyWith(
      catalogStatus: CatalogAnalysisStatus.error,
      catalogError: failure.message,
    )),
    (analysis) => emit(state.copyWith(
      catalogStatus: CatalogAnalysisStatus.success,
      currentCatalogAnalysis: analysis,
    )),
  );
}
```

---

### Step 9 — Extend repository contract
**File:** `lib/features/analysis/domain/repositories/analysis_repository.dart`

```dart
ResultFuture<AudioUploadAnalysis> analyzeCatalogTrack({
  required String audioUrl,
  required String trackId,
  required String trackName,
  required String artistName,
  required String jamendoPageUrl,
});
```

**File:** `lib/features/analysis/data/repositories/analysis_repository_impl.dart`

```dart
@override
ResultFuture<AudioUploadAnalysis> analyzeCatalogTrack({
  required String audioUrl,
  required String trackId,
  required String trackName,
  required String artistName,
  required String jamendoPageUrl,
}) async {
  try {
    final json = await _uploadRemote.analyzeCatalogTrack(
      audioUrl: audioUrl,
      trackId: trackId,
      trackName: trackName,
      artistName: artistName,
      jamendoPageUrl: jamendoPageUrl,
    );
    return Right(AudioUploadAnalysisModel.fromJson(json).toDomain());
  } on DioException catch (e) {
    return Left(NetworkFailure(e.message ?? 'Network error'));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

---

### Step 10 — Add datasource method
**File:** `lib/features/analysis/data/datasources/audio_upload_datasource.dart`  
(`AudioUploadRemoteDataSource` — unauthenticated, reuses existing extended 90 s timeouts)

```dart
Future<Map<String, dynamic>> analyzeCatalogTrack({
  required String audioUrl,
  required String trackId,
  required String trackName,
  required String artistName,
  required String jamendoPageUrl,
}) async {
  final response = await _dio.post<Map<String, dynamic>>(
    '/catalog/analyze',
    data: {
      'audio_url': audioUrl,
      'track_id': trackId,
      'track_name': trackName,
      'artist_name': artistName,
      'jamendo_page_url': jamendoPageUrl,
    },
  );
  return response.data!;
}
```

> **No model changes needed.** `AudioUploadAnalysisModel.fromJson()` already reads `jamendo_track_url` from JSON at line 158.

---

### Step 11 — Update confirm sheet
**File:** `lib/features/catalog/presentation/widgets/catalog_confirm_sheet.dart`

Replace:
```dart
context.read<AnalysisBloc>().add(AnalyzeSongRequested(track.id));
```
With:
```dart
context.read<AnalysisBloc>().add(CatalogTrackAnalyzeRequested(
  audioUrl: track.audioUrl,
  trackId: track.id,
  trackName: track.name,
  artistName: track.artistName,
  jamendoPageUrl: track.jamendoPageUrl,
));
```

---

### Step 12 — Update loading page listener
**File:** `lib/features/analysis/presentation/view/analysis_loading_page.dart`

Change the catalog branch in `BlocListener`:

```dart
// SUCCESS — catalog
if (widget.source == AnalysisSource.catalog &&
    state.catalogStatus == CatalogAnalysisStatus.success &&
    state.currentCatalogAnalysis != null) {
  _phaseTimer?.cancel();
  _timeoutTimer?.cancel();
  context.go(RouteNames.result, extra: AnalysisSource.catalog);
  return;
}

// ERROR — catalog
// In BlocBuilder, change hasCatalogError check to:
final hasCatalogError = widget.source == AnalysisSource.catalog &&
    state.catalogStatus == CatalogAnalysisStatus.error &&
    state.catalogError != null;
final errorMsg = widget.source == AnalysisSource.upload
    ? (state.uploadError ?? '')
    : (state.catalogError ?? '');
```

---

### Step 13 — Simplify results page
**File:** `lib/features/analysis/presentation/view/results_page.dart`

The catalog branch now produces `AudioUploadAnalysis`. Replace `_buildCatalogResult()` with a call to `_buildUploadResult()` using `state.currentCatalogAnalysis`:

```dart
return widget.source == AnalysisSource.upload
    ? _buildUploadResult(context, state, isGuest)
    : _buildUploadResult(   // catalog now uses same path
        context,
        state.copyWith(currentUploadAnalysis: state.currentCatalogAnalysis),
        isGuest,
      );
```

Delete `_CatalogMoodHero` and `_AudioDetailsCatalog` widgets (no longer needed). Jamendo attribution row will appear automatically because `analysis.jamendoTrackUrl != null` for catalog results.

---

## Files Modified Summary

| # | File | Change |
|---|------|--------|
| 1 | `requirements.txt` | Confirm/add `httpx>=0.27` |
| 2 | `app/schemas/catalog_analysis.py` | **New** — `CatalogAnalyzeRequest` |
| 3 | `app/schemas/audio_analysis.py` | Add `jamendo_track_url: Optional[str] = None` |
| 4 | `app/api/v1/catalog.py` | **New** — `POST /analyze` handler |
| 5 | `app/api/v1/api.py` | Register catalog router |
| 6 | `lib/.../bloc/analysis_state.dart` | `CatalogAnalysisStatus` enum + 3 new state fields |
| 7 | `lib/.../bloc/analysis_event.dart` | `CatalogTrackAnalyzeRequested` event |
| 8 | `lib/.../bloc/analysis_bloc.dart` | Handler + event registration |
| 9 | `lib/.../domain/repositories/analysis_repository.dart` | Abstract `analyzeCatalogTrack` method |
| 10 | `lib/.../data/repositories/analysis_repository_impl.dart` | Implementation |
| 11 | `lib/.../data/datasources/audio_upload_datasource.dart` | JSON POST method |
| 12 | `lib/.../widgets/catalog_confirm_sheet.dart` | Dispatch new event |
| 13 | `lib/.../view/analysis_loading_page.dart` | Update catalog BLoC listener + error check |
| 14 | `lib/.../view/results_page.dart` | Use `currentCatalogAnalysis`; delete dead widgets |

---

## Verification

1. **Backend smoke test:**
   ```bash
   curl -X POST http://localhost:8000/api/v1/catalog/analyze \
     -H "Content-Type: application/json" \
     -d '{"audio_url":"<jamendo_stream_url>","track_id":"2234203","track_name":"Test","artist_name":"Artist","jamendo_page_url":""}'
   ```
   Expected: HTTP 200, response contains `mood.primary_mood`, `mood.descriptors`, `jamendo_track_url`.

2. **Flutter catalog flow:** Open catalog → search → tap track → "Analyse this track" → loading screen completes without 403 → Results screen shows `MoodHeroCard` with correct mood gradient, descriptor tags, and reasoning.

3. **Jamendo attribution row:** When `analysis.jamendoTrackUrl` is non-null the attribution row renders; for upload results it does not.

4. **Upload flow regression:** Upload a file and confirm it still completes and renders results correctly (the `copyWith` additions to state are additive — no existing fields change).

5. **Guest mode:** Complete the catalog flow without signing in — `SignUpStrip` appears on the Results screen and the endpoint returns 200 (no auth required).

6. **`flutter analyze`:** No new warnings or errors.
