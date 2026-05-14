# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

MoodTune is a Flutter mobile app (iOS + Android) that analyzes songs for mood. Users upload audio files or analyze tracks from their Spotify library. A FastAPI backend (Python/librosa) does the heavy lifting; Supabase handles auth.

## Commands

### Run the app

Always pass env vars via `--dart-define-from-file`. The `.env` file holds `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `API_BASE_URL`.

```sh
# Development (most common)
flutter run --flavor development --target lib/main_development.dart --dart-define-from-file=.env

# Staging / Production
flutter run --flavor staging --target lib/main_staging.dart --dart-define-from-file=.env
flutter run --flavor production --target lib/main_production.dart --dart-define-from-file=.env
```

### Test

```sh
very_good test --coverage --test-randomize-ordering-seed random

# Single test file
flutter test test/path/to/test.dart
```

Coverage report:
```sh
genhtml coverage/lcov.info -o coverage/ && open coverage/index.html
```

### Analyze / format

```sh
flutter analyze
dart format .
```

### Code generation

```sh
# One-shot
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch mode
flutter packages pub run build_runner watch
```

### Translations

```sh
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

ARB files live in `lib/l10n/arb/`. Generated output goes to `lib/l10n/gen/` (excluded from linting).

## Architecture

Clean architecture, three layers per feature. Dependencies point inward: Presentation → Domain ← Data.

```
lib/
├── app/view/app.dart       # Root widget — provides global BLoCs + routing
├── bootstrap.dart          # Initializes Sentry, Supabase, GetIt DI, BlocObserver
├── core/
│   ├── error/              # Failure + Exception base classes
│   ├── logging/talker.dart # Global Talker logger instance
│   ├── network/auth_interceptor.dart  # Dio interceptor: refreshes Supabase session on 401
│   └── routing/            # AppRouter (GoRouter) + RouteNames constants
├── di/injector.dart        # GetIt setup — call configureDependencies() in bootstrap
├── features/
│   ├── analysis/           # Mood analysis (playlist, song, audio upload)
│   ├── auth/               # Supabase email/password auth
│   └── spotify/            # Spotify OAuth, playlists, profile
├── l10n/                   # Localization (en + es)
└── utils/typedef.dart      # ResultFuture<T> = Future<Either<Failure, T>>
```

Each feature follows the same structure:

```
feature/
├── data/
│   ├── datasources/   # Dio HTTP clients — talk directly to backend
│   ├── models/        # JSON deserialization + .toDomain() extension
│   └── repositories/  # Implements domain contracts, maps exceptions → Failures
├── domain/
│   ├── entities/      # Pure Dart, Equatable, no framework deps
│   ├── repositories/  # Abstract contracts returning ResultFuture<T>
│   └── usecases/      # Single-operation classes (spotify feature only)
└── presentation/
    ├── bloc/          # BLoC + events + states (use copyWith state pattern)
    ├── view/          # Pages — one per route
    └── widgets/       # Reusable UI components
```

## Key patterns

### Error handling

`ResultFuture<T>` (dartz `Either`) is the return type for all repository and datasource methods:

```dart
// typedef in lib/utils/typedef.dart
typedef ResultFuture<T> = Future<Either<Failure, T>>;

// Consuming in BLoC
final result = await _repository.analyzePlaylist(event.playlistId);
result.fold(
  (failure) => emit(state.copyWith(status: AnalysisStatus.error, error: failure.message)),
  (analysis) => emit(state.copyWith(status: AnalysisStatus.success, currentAnalysis: analysis)),
);
```

Failures extend `Failure` from `lib/core/error/failures.dart`. Datasources throw typed `Exception` subclasses from `lib/core/error/exceptions.dart`; repositories catch and map them.

### State management

BLoCs use a single state class with `copyWith`, an enum status field, and inline loading/error fields for secondary operations:

```dart
// AnalysisBloc handles: playlist analysis, song analysis, audio upload, history
// All provided globally at App level via MultiBlocProvider in app/view/app.dart
```

Global BLoCs (provided at app root): `AuthBloc`, `SpotifyBloc`, `AnalysisBloc`.

### Dependency injection

GetIt singleton — `getIt` from `lib/di/injector.dart`. `configureDependencies()` is called in `bootstrap.dart`. The `tokenProvider` lambda captures the Supabase session token at call time and passes it to data sources as Bearer auth.

### Routing

`AppRouter` in `lib/core/routing/app_router.dart` — static `GoRouter` instance. Route constants are in `RouteNames`. Complex objects are passed between routes via `state.extra` (cast on arrival). The guest flow starts at `/guest`; authenticated flow starts at `/spotify`.

### HTTP clients

Each datasource constructs its own `Dio` instance configured with:
- `AuthInterceptor` — auto-refreshes Supabase session on 401 and retries
- `TalkerDioLogger` — structured logging
- `SentryDio` — error capture

Audio upload datasource uses longer timeouts (30s connect, 90s receive/send).

### UI framework

`shadcn_ui` with a forced dark `ShadSlateColorScheme`. The root widget is `ShadApp.custom` wrapping `CupertinoApp.router`. Use `ShadButton`, `ShadCard`, etc. from shadcn_ui before reaching for Material widgets.

## Environment variables

| Variable | Purpose |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon key |
| `API_BASE_URL` | FastAPI backend base URL (e.g. `https://moodtune-backend-production-e4fe.up.railway.app/api/v1`) |
| `SENTRY_DSN` | Sentry DSN (optional; monitoring is skipped if empty) |

Copy `env.example` to `.env` to get started. Local backend default: `http://127.0.0.1:8000/api/v1`.

## Backend API surface

The Flutter app talks to two datasource objects:

| Datasource | Endpoints |
|---|---|
| `AnalysisRemoteDataSource` | `POST /analysis/analyze/{playlistId}`, `GET /analysis/history`, `GET /analysis/{id}`, `POST /song/analyze/{trackId}` |
| `AudioUploadRemoteDataSource` | `POST /audio-upload/analyze` (multipart) |
| `SpotifyRepositoryImpl` | `/spotify/authorize-url`, `/spotify/connect`, `/spotify/connection`, `/spotify/profile`, `/spotify/playlists`, `/spotify/disconnect` |

Auth endpoints (`/auth/sign-in`, `/auth/sign-up`) are handled directly by Supabase, not the FastAPI backend.
