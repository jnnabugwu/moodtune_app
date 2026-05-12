# MoodTune

**Track. Discover. Connect. Read.**

MoodTune is a mobile app that analyzes any song and tells you its mood — instantly. Upload a file or browse the free Jamendo music catalog, and MoodTune reads the audio's tempo, energy, brightness, and texture to return a primary mood label, confidence score, descriptors, and a plain-language explanation of what the music is doing.

No account required to try it. Authenticated users get auto-saved history and mood filtering across past analyses.

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

---

## Features

- **Mood analysis** — Upload any audio file (MP3, M4A, FLAC, WAV, OGG, up to 15 MB) and get a result in ~30 seconds
- **Four mood identities** — Upbeat, Serene, Charged, Reflective — each with a distinct visual identity and color palette
- **Jamendo catalog** — Browse and analyze free tracks from the Jamendo music library without uploading anything
- **Guest mode** — Full analysis with no account wall; sign-up prompt appears once, non-intrusively
- **History** — Authenticated users get auto-saved results, filterable by mood (capped at 50 analyses)
- **Confidence scoring** — Strong / Good / Possible match at ≥75% / 50–74% / <50%

---

## Screens

| Screen | Guest | Authenticated |
| --- | --- | --- |
| Landing / Home | Yes | — |
| Home (Authenticated) | — | Yes |
| Upload Screen | Yes | Yes |
| Consent Modal | Yes | Yes |
| Analysis Loading State | Yes | Yes |
| Results Screen | Yes | Yes |
| Catalog Search | Yes | Yes |
| Catalog Track Confirm | Yes | Yes |
| Sign In / Sign Up | Yes | Yes |
| History Screen | — | Yes |

Full UX spec (layouts, interactions, copy direction, error states): [`docs/moodtune-ux-spec.md`](docs/moodtune-ux-spec.md)

---

## Stack

| Layer | Tech |
| --- | --- |
| Mobile | Flutter (Dart), iOS + Android |
| Auth + DB | Supabase (PostgreSQL + Auth) |
| Backend | FastAPI (Python), hosted on Railway |
| Audio analysis | librosa (Python) |
| Music catalog | Jamendo API v3 |
| CI | Codemagic |

---

## Getting Started

This project uses three flavors:

```sh
# Development
flutter run --flavor development --target lib/main_development.dart

# Staging
flutter run --flavor staging --target lib/main_staging.dart

# Production
flutter run --flavor production --target lib/main_production.dart
```

### Environment setup

Copy the sample env and fill in values:

```sh
cp env.example .env
```

| Variable | Description |
| --- | --- |
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon key |
| `API_BASE_URL` | Backend base URL (e.g. `https://moodtune-backend-production-e4fe.up.railway.app/api/v1`) |

Run with dart-defines from `.env`:

```sh
flutter run --flavor development \
  --target lib/main_development.dart \
  --dart-define-from-file=.env
```

---

## Testing

```sh
very_good test --coverage --test-randomize-ordering-seed random
```

Coverage report:

```sh
genhtml coverage/lcov.info -o coverage/
open coverage/index.html
```

---

## Translations

Strings live in `lib/l10n/arb/`. To add a string:

1. Add it to `app_en.arb`
2. Add translated versions to each locale file (e.g. `app_es.arb`)
3. Regenerate:

```sh
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

Or just run `flutter run` — codegen runs automatically.

To add a new locale, update `CFBundleLocalizations` in `ios/Runner/Info.plist`.

---

## Docs

- [`docs/moodtune-ux-spec.md`](docs/moodtune-ux-spec.md) — Full UX design specification (v1.2), ready for Figma handoff

---

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
