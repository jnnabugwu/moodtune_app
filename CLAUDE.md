# CLAUDE.md

Guidance for agents working in this repository.

## What this is

MoodTune is a Flutter app (iOS first; Android builds but lacks the native features) that tells you the mood of a song. Users upload an audio file, pick a Jamendo catalog track, or analyze their Spotify library. A FastAPI backend ([moodtune-backend](https://github.com/jnnabugwu/moodtune-backend), Python/librosa) analyzes the audio; on iOS the app also classifies the mood on device with YAMNet and shows that mood instead. Supabase handles auth.

Product and design context lives in `docs/`:

- `docs/ROADMAP.md`: the plan. Code comments cite its phases (`ROADMAP OD-4`, `OD-5`); read the phase before changing that code.
- `docs/ARCHITECTURE.md`: whole-system architecture, backend included.
- `docs/MOOD_TAXONOMY.md`: the backend's 5 mood labels and the 4 display identities they collapse into (`MoodTheme` in `lib/app/theme/mood_theme.dart`).
- `docs/product.md`: what the product is for.

## Commands

```sh
# Run (always pass env via --dart-define-from-file; dev.env = dev keys, .env = prod keys)
flutter run --flavor development --target lib/main_development.dart --dart-define-from-file=dev.env

# Everything CI checks, locally: deps, format, analyze, tests at 80% coverage, cspell on Markdown, PR title
tool/ci_check.sh
tool/ci_check.sh format analyze test   # just these steps
tool/ci_check.sh test coverage         # coverage of each lib/ file this branch touches (for the PR)

# One test file
flutter test test/path/to/file_test.dart

# Native on-device pipeline (decoder → YAMNet) on an iOS simulator
flutter test integration_test/yamnet_device_test.dart --flavor development -d <simulator id>

# Translations (ARB in lib/l10n/arb/, output in lib/l10n/gen/)
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

## Workflow

- **Green before push.** `tool/ci_check.sh` passing locally means the required checks pass: `build / build` (format, analyze, tests, 80% coverage of `lib/`), `semantic-pull-request / build`, and `spell-check / build`. `main` only accepts changes that pass them.
- **PR titles are Conventional Commits** (`feat(scope): …`, `fix(scope): …`, `chore: …`); the semantic-pull-request check enforces it. Commit messages follow the same style.
- **Markdown is spell-checked**, every `.md` in the repo. Add legitimate project words to `words` in `.github/cspell.json`.
- **Parallel work uses sibling git worktrees** (`../moodtune_app-<topic>`). A new worktree needs `flutter pub get` before anything else, plus copies of the gitignored `dev.env` / `.env`. Run `dart format` only after `pub get`: without package resolution the formatter picks the wrong language version and reformats files you never touched.
- **Stacked PRs** (base is another feature branch) get the same CI as PRs into `main`. Once the lower PR merges, merge `origin/main` into the upper branch and retarget it to `main`.
- **Keep diffs to the change.** Format only the files you edited; formatting sweeps go in their own `chore` PR.

### Cloud sessions (claude.ai/code)

- Flutter (3.47.5, Dart 3.13.4) is preinstalled and runs as root; ignore the root warning. `tool/ci_check.sh` runs as-is, with no `dev.env` / `.env`.
- The repo must be attached with push access. An anonymous clone reads code but can't push, and the GitHub API returns 403 for it.
- GitHub GraphQL is blocked, so `gh pr view`, `gh pr list` and `gh pr create` fail. Use REST: `gh api repos/{owner}/{repo}/pulls -f title=… -f head=<branch> -f base=main -f body=…` to open a PR, `gh api repos/{owner}/{repo}/pulls/<n>` to read one.
- There is no iOS simulator or Xcode, so `integration_test/` and anything under `ios/` can't be run; say so in the PR.

## Architecture

Clean architecture, three layers per feature under `lib/features/<feature>/`: `data/` (Dio datasources, JSON models with `.toDomain()`, repository implementations), `domain/` (Equatable entities, abstract repositories returning `ResultFuture<T>`, use cases), `presentation/` (BLoCs, pages, widgets). Dependencies point inward.

| Feature | What it does |
|---|---|
| `analysis` | Upload, catalog, song and playlist analysis; result history. `AnalysisBloc` owns all of it. |
| `on_device_mood` | YAMNet mood + sound tags on the phone; `MoodSwitchover` swaps the on-device mood into the backend's result. |
| `narration` | One- or two-sentence mood narration from Apple's on-device Foundation Models, validated by `MoodNarrator.isGrounded`. |
| `mood_feedback` | Records what each result showed (both engines) and the "Does this feel right?" answer; remote kill switch via `GET /config`. |
| `catalog` | Jamendo search (client calls Jamendo directly with `JAMENDO_CLIENT_ID`). |
| `sharing` | Share a result as a branded card to Instagram Stories (own `moodtune/share` platform channel), X and the system sheet (`share_plus`). `ShareRepository` hides the plugin layer; `MoodShareCard` is rasterized offscreen. |
| `auth` | Supabase email/password. |
| `spotify` | Spotify OAuth, profile, playlists. |

Shared pieces: `lib/core/` (failures/exceptions, Talker logger, `AuthInterceptor`, `AppRouter` + `RouteNames`), `lib/di/injector.dart` (GetIt, `configureDependencies()` called from `bootstrap.dart`), `lib/shared/widgets/` (hero card, confidence ring, chips…).

### Error handling

Repositories return `ResultFuture<T>` (`Future<Either<Failure, T>>`, dartz). Datasources return plain values and throw `Exception` subclasses from `lib/core/error/exceptions.dart`; repositories catch them and map to `Failure`s from `lib/core/error/failures.dart`. BLoCs `fold` the result into state.

### State

One state class per BLoC with `copyWith`, an enum status, and inline loading/error fields for secondary operations. Global BLoCs (`AuthBloc`, `SpotifyBloc`, `AnalysisBloc`) are provided in `lib/app/view/app.dart`; `CatalogBloc` is a GetIt factory, fresh per screen.

### HTTP

Each backend datasource builds its own `Dio` with `AuthInterceptor` (refreshes the Supabase session on 401 and retries), `TalkerDioLogger`, and `SentryDio`. The `tokenProvider` lambda reads the Supabase token at call time. Uploads use longer timeouts (30 s connect, 90 s send/receive). The Jamendo client is a plain `Dio`, and auth goes through the Supabase SDK.

### Routing

Static `GoRouter` in `lib/core/routing/app_router.dart`, paths in `RouteNames`. Complex objects travel in `state.extra` and are cast on arrival. The app starts at `/splash`, which sends signed-in users to `/home` and everyone else to the landing page (`/`).

### UI

`ShadApp.custom` (light `ShadSlateColorScheme`) wraps `CupertinoApp.router`. Screens are built from Cupertino widgets and the custom widgets in `lib/shared/widgets/` on a warm light palette; mood colors and icons come from `MoodTheme`. Most strings are inline English; only a few screens use `l10n`.

## On-device mood

The parts that run natively live in `ios/Runner/` (`AppDelegate.swift`, `AudioWindowDecoder.swift`) behind two method channels: `moodtune/audio_decode` (AVAudioFile → 16 kHz windows) and `moodtune/narration` (Foundation Models). Android registers neither, so the Dart side treats `MissingPluginException` as "unavailable" and the switchover is gated to iOS in the injector.

- The model is `assets/models/yamnet.tflite` run through `flutter_litert`; `assets/models/yamnet_mood.json` maps YAMNet classes to mood labels and sound tags. That JSON is generated by `spikes/clap/04_export_app_assets.py`, which lives only in the local `moodtune/` workspace; regenerate it there rather than hand-editing it.
- Classification runs alongside the backend call and gets a grace period after the backend answers; everything falls back to the backend mood.
- `OnDeviceMoodAttempt.failure` is a fixed category (`disabled`, `unsupported`, `download: <type>`, `timeout`, `late`, `busy`, `no_mood`, `decode: <code>`, `classification_failed`). It is uploaded with each observation, so it carries categories only, never error text, file paths or URLs.
- Narration may mention an instrument, vocals or genre only when a sound tag backs it; `MoodNarrator`'s guarded vocabulary covers every tag in `yamnet_mood.json` (a test enforces this).

## Testing

`mocktail` for mocks, `bloc_test` for BLoCs; shared helpers in `test/helpers/` (`pumpApp`, mocks). Tests mirror `lib/` paths. CI runs them in random order, so each test sets up its own state. Unit tests cover Dart only; changes under `ios/Runner/` are covered by the integration test above, which the `ios_on_device` workflow runs on a simulator whenever native or on-device code changes.

## Environment variables

Copy `env.example` to `.env` / `dev.env`.

| Variable | Purpose |
|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Supabase project |
| `API_BASE_URL` | Backend base URL, e.g. `https://moodtune-backend-production-e4fe.up.railway.app/api/v1` (local: `http://127.0.0.1:8000/api/v1`) |
| `JAMENDO_CLIENT_ID` | Jamendo catalog search |
| `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` | Google Sign-In OAuth clients; the Google button is hidden until they're set (iOS needs both, Android the web one) |
| `SENTRY_DSN` | Optional; monitoring is skipped when empty |
| `META_APP_ID` | Meta App ID for Instagram Stories sharing (public, not a secret); Instagram Stories is hidden from the share sheet when empty |

## Backend API surface

Paths are relative to `API_BASE_URL`; the datasources in each feature's `data/datasources/` are the source of truth.

| Area | Endpoints |
|---|---|
| Analysis | `POST /audio-upload/analyze` (multipart), `POST /catalog/analyze`, `POST /song/analyze/{trackId}`, `POST /analysis/analyze/{playlistId}`, `GET /analysis/{id}`, `GET /song/history` |
| Mood feedback | `GET /config`, `POST /mood-observations`, `PATCH /mood-observations/{id}/feedback` |
| Spotify | `/spotify/authorize`, `/spotify/callback`, `/spotify/status`, `/spotify/profile`, `/spotify/playlists`, `/spotify/disconnect`, `/song/playlist/{id}/tracks` |

Auth (sign-in, sign-up) goes straight to Supabase.

## Release

iOS ships through Codemagic (`codemagic.yaml`, workflow `ios-testflight`, started manually). It builds the production flavor with secrets from Codemagic env groups and uploads to TestFlight.
