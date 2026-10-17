# MoodTune — Architecture & Technical Overview

> Interview study guide for the MoodTune full-stack project.
> Backend: **FastAPI (Python)** | Frontend: **Flutter (Dart)** | DB: **Supabase (PostgreSQL)**

---

## Table of Contents

1. [High-Level System Overview](#1-high-level-system-overview)
2. [Backend Architecture](#2-backend-architecture)
   - [Project Layout](#21-project-layout)
   - [Routes](#22-routes)
   - [Services](#23-services)
   - [CRUD Layer](#24-crud-layer)
   - [Schemas (Pydantic)](#25-schemas-pydantic)
   - [Authentication & Security](#26-authentication--security)
3. [Frontend Architecture](#3-frontend-architecture)
   - [Clean Architecture Layers](#31-clean-architecture-layers)
   - [BLoC State Management](#32-bloc-state-management)
   - [Networking](#33-networking)
4. [Database Schema](#4-database-schema)
5. [Data Flows](#5-data-flows)
   - [Spotify OAuth Flow](#51-spotify-oauth-flow)
   - [Playlist Analysis Flow](#52-playlist-analysis-flow)
   - [Audio Upload Flow](#53-audio-upload-flow)
   - [Token Refresh Flow](#54-token-refresh-flow)
6. [External Integrations](#6-external-integrations)
7. [Key Interview Concepts](#7-key-interview-concepts)

---

## 1. High-Level System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
│  ┌─────────────┐  ┌─────────────────┐  ┌────────────────────┐  │
│  │  Auth (BLoC)│  │ Spotify (BLoC)  │  │  Analysis (BLoC)   │  │
│  └──────┬──────┘  └────────┬────────┘  └─────────┬──────────┘  │
│         │                  │                       │             │
│         └──────────────────┼───────────────────────┘             │
│                    Dio HTTP Client                               │
│                  (+ AuthInterceptor)                             │
└──────────────────────┬───────────────────────────────────────────┘
                       │  HTTPS  (Bearer JWT)
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                     FastAPI Backend                              │
│                  /api/v1/...                                     │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │
│  │  /spotify  │  │  /analysis   │  │  /song  /audio-upload    │ │
│  └─────┬──────┘  └──────┬───────┘  └────────────┬─────────────┘ │
│        └────────────────┼──────────────────────┘              │
│                  Services Layer                                  │
│         (spotify_api, analysis_service, audio_analysis)         │
│                  CRUD Layer (Supabase)                           │
└──────────────────────┬────────────────────────┬─────────────────┘
                       │                        │
            ┌──────────▼──────────┐   ┌─────────▼──────────┐
            │  Supabase (Postgres) │   │   Spotify API       │
            │  - users            │   │   - Audio Features  │
            │  - spotify_connect. │   │   - Playlists       │
            │  - playlist_analyses│   │   - OAuth           │
            └─────────────────────┘   └────────────────────┘
```

---

## 2. Backend Architecture

### 2.1 Project Layout

```
moodtune-backend/
├── app/
│   ├── main.py              # FastAPI app, CORS, Sentry init, router mount
│   ├── core/
│   │   ├── config.py        # Pydantic Settings (env vars)
│   │   ├── supabase.py      # Supabase client factory
│   │   └── security.py      # HTTPBearer scheme
│   ├── api/
│   │   ├── deps.py          # get_current_user() dependency
│   │   └── v1/
│   │       ├── spotify.py        # /spotify routes
│   │       ├── analysis.py       # /analysis routes
│   │       ├── song_analysis.py  # /song routes
│   │       └── audio_upload.py   # /audio-upload routes
│   ├── services/
│   │   ├── spotify_auth.py       # OAuth token exchange/refresh
│   │   ├── spotify_api.py        # Spotify REST wrapper
│   │   ├── audio_analysis_service.py  # librosa analysis
│   │   └── analysis_service.py   # Mood classification logic
│   ├── schemas/
│   │   ├── spotify.py        # Spotify Pydantic models
│   │   ├── analysis.py       # Playlist analysis models
│   │   ├── song_analysis.py  # Song analysis models
│   │   └── audio_analysis.py # Audio upload models
│   └── crud/
│       ├── analysis.py       # playlist_analyses table ops
│       ├── spotify.py        # spotify_connections table ops
│       └── spotify_state.py  # spotify_oauth_states table ops
```

---

### 2.2 Routes

All routes live under `/api/v1/` and require a Supabase JWT unless noted.

#### Spotify Routes — `/api/v1/spotify`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| `GET` | `/authorize` | Returns Spotify OAuth URL + state | Required |
| `GET` | `/callback` | Exchanges OAuth code → tokens, saves to DB | Required |
| `GET` | `/status` | Returns `{connected: bool}` | Required |
| `GET` | `/profile` | Returns Spotify user profile | Required |
| `POST` | `/disconnect` | Deletes `spotify_connections` row | Required |
| `GET` | `/playlists` | Returns paginated playlists (`limit`, `offset`) | Required |

#### Analysis Routes — `/api/v1/analysis`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| `POST` | `/analyze/{playlist_id}` | Full playlist mood analysis | Required |
| `GET` | `/history` | Paginated analysis history | Required |
| `GET` | `/{analysis_id}` | Single analysis by ID | Required |

#### Song Routes — `/api/v1/song`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| `GET` | `/playlist/{playlist_id}/tracks` | Tracks with preview URLs | Required |
| `POST` | `/analyze` | Upload audio → librosa analysis | Required |
| `POST` | `/analyze/{track_id}` | Upload audio + Spotify track metadata | Required |

#### Audio Upload Route — `/api/v1/audio-upload`

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| `POST` | `/analyze` | Guest audio upload → librosa analysis | **Public** |

#### Utility

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | `{status: "healthy"}` |
| `GET` | `/` | Welcome message |

---

### 2.3 Services

Services hold all business logic. Routes call services; services call CRUD and external APIs.

```
┌─────────────────────────────────────────────────────────┐
│                     Services Layer                       │
│                                                         │
│  spotify_auth.py          spotify_api.py                │
│  ┌─────────────────┐      ┌─────────────────────────┐  │
│  │ generate_auth_  │      │ get_valid_spotify_token  │  │
│  │ url()           │      │ (auto-refresh if expired)│  │
│  │ exchange_code_  │      │ get_user_profile()       │  │
│  │ for_tokens()    │      │ get_user_playlists()     │  │
│  │ refresh_access_ │      │ get_playlist_info()      │  │
│  │ token()         │      │ get_playlist_tracks()    │  │
│  │ get_spotify_    │      │ get_audio_features()     │  │
│  │ user_id()       │      │ get_track_info()         │  │
│  └─────────────────┘      └─────────────────────────┘  │
│                                                         │
│  analysis_service.py      audio_analysis_service.py     │
│  ┌─────────────────────┐  ┌───────────────────────────┐ │
│  │ analyze_playlist_   │  │ analyze_audio_bytes()     │ │
│  │ mood()              │  │ (librosa feature extract) │ │
│  │ classify_track_     │  │ determine_upload_mood()   │ │
│  │ mood()              │  │ Extracts: tempo, spectral │ │
│  │ calculate_mood_     │  │ centroid, MFCC, RMS, etc. │ │
│  │ distribution()      │  └───────────────────────────┘ │
│  │ calculate_          │                               │
│  │ confidence()        │                               │
│  │ select_top_tracks() │                               │
│  └─────────────────────┘                               │
└─────────────────────────────────────────────────────────┘
```

#### Mood Classification Logic

**From Spotify Audio Features** (playlist analysis):

```
valence >= 0.6 AND energy >= 0.6  →  Happy & Energetic (upbeat)
valence >= 0.6 AND energy < 0.6   →  Happy & Calm (peaceful)
valence < 0.4  AND energy >= 0.6  →  Intense & Dark (intense)
valence < 0.4  AND energy < 0.4   →  Calm & Melancholic (melancholic)
otherwise                          →  Mixed
```

**From Librosa Audio Features** (file upload):

```
high tempo + high energy   →  Energetic / Happy
low energy + low valence   →  Sad
low valence + high energy  →  Angry
low energy                 →  Calm
```

**Confidence Score**:

```
Euclidean distance from center point (0.5, 0.5) on the valence-energy plane.
The further from center, the higher the confidence.
```

---

### 2.4 CRUD Layer

Thin database layer — only reads and writes, no business logic.

| File | Table | Operations |
|------|-------|------------|
| `crud/spotify.py` | `spotify_connections` | get, create, update (tokens), delete |
| `crud/analysis.py` | `playlist_analyses` | create, get by id, list by user (paginated) |
| `crud/spotify_state.py` | `spotify_oauth_states` | create state, get state, delete state (single-use) |

---

### 2.5 Schemas (Pydantic)

Every request body and response is typed with Pydantic models. FastAPI uses these for automatic:

- Request validation
- Response serialization
- OpenAPI docs generation

Key models:

```
PlaylistAnalysisResponse
├── playlist_id: str
├── playlist_name: str
├── mood_result: MoodResult
│   ├── primary_mood: str
│   ├── mood_category: str
│   ├── confidence: float
│   ├── mood_descriptors: list[str]
│   └── mood_distribution: MoodDistribution
├── audio_features_summary: AudioFeaturesSummary
│   ├── avg_valence: float
│   ├── avg_energy: float
│   ├── avg_danceability: float
│   └── avg_tempo: float
├── top_tracks: list[TrackAnalysis]
└── track_count: int
```

---

### 2.6 Authentication & Security

```
Flutter App
    │
    │  Authorization: Bearer <Supabase JWT>
    ▼
FastAPI Route
    │
    │  Depends(get_current_user)
    ▼
deps.py → get_current_user()
    │
    │  supabase.auth.get_user(token)
    ▼
 ✓ Valid → returns {id, email, user_metadata}
 ✗ Invalid → 401 Unauthorized
```

- Tokens are **Supabase JWTs** (RS256 signed)
- Backend verifies via Supabase SDK (no custom JWT parsing)
- Spotify tokens stored encrypted in DB; auto-refreshed by `get_valid_spotify_token()`
- OAuth state param is single-use with a 10-minute TTL (CSRF protection)

---

## 3. Frontend Architecture

### 3.1 Clean Architecture Layers

Every feature (`auth`, `spotify`, `analysis`) is split into 3 layers:

```
┌─────────────────────────────────────────────────────┐
│              Presentation Layer                      │
│   Pages / Screens                                   │
│   BLoC (events → states)                           │
│   Widgets                                          │
└────────────────────┬────────────────────────────────┘
                     │ calls use cases
┌────────────────────▼────────────────────────────────┐
│               Domain Layer                           │
│   Entities (pure Dart, no Flutter/framework)        │
│   Repository Interfaces (abstract classes)          │
│   Use Cases (single-responsibility business logic)  │
└────────────────────┬────────────────────────────────┘
                     │ implements interfaces
┌────────────────────▼────────────────────────────────┐
│                Data Layer                            │
│   Models (JSON ↔ Entity mapping)                   │
│   Remote Data Sources (Dio HTTP calls)              │
│   Repository Implementations                        │
└─────────────────────────────────────────────────────┘
```

**Why this matters**: Domain has zero dependencies on frameworks. Business logic is testable in isolation. Data sources are swappable.

---

### 3.2 BLoC State Management

```
UI Widget
   │ dispatches Event
   ▼
BLoC
   │ calls Use Case / Repository
   ▼
Repository Impl → Remote Data Source → Backend API
   │ returns Either<Failure, Entity>
   ▼
BLoC emits new State
   │
   ▼
UI rebuilds via BlocBuilder
```

Example — `SpotifyBloc`:

| Event | Triggered By | State Emitted |
|-------|-------------|---------------|
| `SpotifyStarted` | App launch | `connected` or `disconnected` |
| `SpotifyAuthorizeRequested` | "Connect" button | `loading` → browser opens |
| `SpotifyAuthCodeReceived` | Deep link callback | `loading` → `connected` |
| `SpotifyProfileRequested` | Connected screen | `profileLoaded` |
| `SpotifyDisconnectRequested` | "Disconnect" button | `disconnected` |

Example — `AnalysisBloc`:

| Event | State Emitted |
|-------|---------------|
| `AnalyzePlaylistRequested` | `analyzing` → `success` or `error` |
| `AnalysisHistoryRequested` | `historyLoaded` |
| `AnalyzeSongRequested` | `analyzing` → `songAnalysisSuccess` |
| `AudioUploadRequested` | `analyzing` → `uploadSuccess` |

---

### 3.3 Networking

```
Dio Client
├── BaseURL: http://127.0.0.1:8000/api/v1 (dev)
│            https://[prod-url]/api/v1     (prod)
├── Interceptors:
│   ├── AuthInterceptor
│   │   └── On 401: calls Supabase.refreshSession()
│   │               retries request with new token
│   ├── TalkerDioLogger (HTTP logging)
│   └── SentryDio (error tracking)
└── Headers: Authorization: Bearer <JWT>
```

Deep link for Spotify callback: `moodtune://spotify/callback?code=X&state=Y`
Handled by `app_links` package → dispatches `SpotifyAuthCodeReceived` event.

---

## 4. Database Schema

```
┌─────────────────────────────────┐
│          users (Supabase Auth)   │
│  id (UUID) PK                   │
│  email                          │
│  user_metadata                  │
└──────────────┬──────────────────┘
               │ 1:1
               ▼
┌─────────────────────────────────┐
│       spotify_connections        │
│  id (UUID) PK                   │
│  user_id (UUID) FK              │
│  spotify_user_id                │
│  access_token                   │
│  refresh_token                  │
│  expires_at (timestamp)         │
│  created_at / updated_at        │
└─────────────────────────────────┘
               │ 1:N
               ▼
┌─────────────────────────────────┐
│       playlist_analyses          │
│  id (UUID) PK                   │
│  user_id (UUID) FK              │
│  playlist_id                    │
│  playlist_name                  │
│  mood_results (JSONB)           │
│    └─ primary_mood              │
│    └─ confidence                │
│    └─ mood_distribution         │
│    └─ top_tracks                │
│    └─ averages                  │
│  created_at                     │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│      spotify_oauth_states        │
│  state (text) PK                │
│  user_id (UUID)                 │
│  expires_at (timestamp)         │
│  (Single-use, 10-min TTL)       │
└─────────────────────────────────┘
```

---

## 5. Data Flows

### 5.1 Spotify OAuth Flow

```
Flutter                    Backend                   Spotify
  │                           │                         │
  │── GET /spotify/authorize ─▶│                         │
  │                           │── generate state ──────│
  │◀── {authorize_url, state} ─│                         │
  │                           │                         │
  │── open browser ──────────────────────────────────▶  │
  │                           │                         │
  │                           │◀── redirect with code ──│
  │                           │   ?code=X&state=Y       │
  │                           │                         │
  │                           │── verify state TTL      │
  │                           │── POST /api/token ────▶ │
  │                           │◀── {access, refresh} ── │
  │                           │── save to DB            │
  │                           │── delete state          │
  │                           │                         │
  │◀── deep link callback ────│                         │
  │   moodtune://spotify/     │                         │
  │   callback                │                         │
  │                           │                         │
  │── GET /spotify/status ───▶│                         │
  │◀── {connected: true} ─────│                         │
```

### 5.2 Playlist Analysis Flow

```
Flutter                         Backend                    Spotify API
  │                                │                           │
  │── POST /analysis/analyze/{id} ─▶                          │
  │                                │── get_valid_token() ────▶ │
  │                                │   (refresh if expired)    │
  │                                │◀── access_token ─────── │
  │                                │── GET /playlists/{id} ──▶ │
  │                                │◀── playlist info ──────── │
  │                                │── GET /playlists/{id}/    │
  │                                │   tracks (batched) ─────▶ │
  │                                │◀── tracks + metadata ──── │
  │                                │── GET /audio-features     │
  │                                │   (max 100/request) ────▶ │
  │                                │◀── valence, energy, etc.  │
  │                                │                           │
  │                                │── analyze_playlist_mood()
  │                                │   (classify + distribute) │
  │                                │── save to DB              │
  │◀── PlaylistAnalysisResponse ───│                           │
  │    {mood, confidence,          │                           │
  │     distribution, top_tracks}  │                           │
```

### 5.3 Audio Upload Flow

```
Flutter                         Backend (librosa)
  │                                │
  │── POST /audio-upload/analyze ──▶
  │   multipart/form-data          │
  │   audio_file (mp3/wav/etc)     │── validate format + size
  │                                │── write to /tmp/
  │                                │── librosa.load()
  │                                │── extract features:
  │                                │   tempo, spectral_centroid,
  │                                │   MFCC, RMS, zero_crossing
  │                                │── determine_upload_mood()
  │                                │── delete temp file
  │◀── AudioAnalysisResponse ──────│
  │    {mood, features, confidence}│
```

### 5.4 Token Refresh Flow

```
Flutter (Dio)                    Backend               Supabase
  │                                │
  │── API request ────────────────▶│
  │                                │── verify JWT ────▶
  │◀── 401 Unauthorized ───────────│◀── expired ───────│
  │                                │
  │  AuthInterceptor fires:
  │  Supabase.auth.refreshSession()
  │  ──────────────────────────────────────────────────▶│
  │◀── new JWT ────────────────────────────────────────│
  │                                │
  │── Retry original request ─────▶│
  │◀── 200 OK ─────────────────────│
```

---

## 6. External Integrations

### Spotify API

- **Auth**: OAuth 2.0 Authorization Code Flow
- **Scopes**: `user-read-private`, `user-read-email`, `playlist-read-private`, `playlist-read-collaborative`
- **Token storage**: Backend DB (never sent to client)
- **Key insight**: Audio features (`valence`, `energy`, `danceability`, `tempo`) are the core of the mood engine

### Supabase

- **Auth**: JWT-based; SDK handles token storage and refresh on client
- **Database**: Postgres with Supabase client (REST, no raw SQL in this project)
- **Service key**: Used server-side for admin operations (bypasses RLS)

### Sentry

- **Backend**: `sentry_sdk` with FastAPI integration, 10% trace sampling
- **Frontend**: `sentry_flutter` + `sentry_dio` for HTTP error tracking
- **Environment**: Production only (`SENTRY_ENABLE=True`)

---

## 7. Key Interview Concepts

### Why FastAPI?

- Async by default (ASGI/Uvicorn)
- Automatic OpenAPI/Swagger docs
- Pydantic integration for type-safe request/response handling
- Dependency injection system (cleaner than decorators)

### Why Clean Architecture in Flutter?

- **Testability**: Domain layer has no Flutter dependencies; can unit test use cases/entities in pure Dart
- **Replaceability**: Swap Supabase for Firebase by re-implementing the data layer only
- **Separation of concerns**: UI never touches raw HTTP; BLoC never touches Dio

### Why BLoC?

- Predictable unidirectional data flow
- Events are explicit, states are serializable → easier debugging
- `flutter_bloc` integrates well with `equatable` for state comparison

### Mood Engine — The Core Feature

```
Two approaches depending on input:

1. Spotify playlist  →  use Spotify's pre-computed audio features
                        (valence + energy = mood quadrant)

2. Uploaded file    →  use librosa to extract raw audio features
                        (tempo, MFCC, spectral features → estimated valence/energy)
```

The valence-energy 2D plane is the fundamental model:

```
                    Energy
                      1.0
                       │
    Intense & Dark ◄───┼───► Happy & Energetic
    (angry/intense)    │     (upbeat)
                    0.5│
  ────────────────────────────────────── Valence
             0.0       │       1.0
                    0.5│
    Calm & Melancholic─┼───► Happy & Calm
    (sad/melancholic)  │     (peaceful)
                      0.0
```

### Security Considerations

| Concern | Solution |
|---------|----------|
| API auth | Supabase JWT on every route |
| CSRF on OAuth | State param with 10-min TTL, single-use |
| Spotify token leakage | Never returned to client; stored server-side |
| File upload abuse | Size limit (15MB), format whitelist, temp file cleanup |
| CORS | Configured allowlist of origins |

### Deployment Architecture

```
Railway.app (Backend)
    FastAPI + Uvicorn (ASGI)
    Environment vars from Railway secrets

Supabase (Managed)
    PostgreSQL
    Auth service
    Hosted in US East

Flutter (Client)
    iOS / Android / Web
    Three flavors: dev, staging, production
    Base URL per flavor via main_*.dart
```
