# Mood taxonomy

Custom valence/energy taxonomy — not Russell's 8-region circumplex. Two tiers: a
5-label backend classification, collapsed into a 4-bucket display theme on the
main Flutter results screen (with one screen that bypasses the theme entirely).

## 1. Backend classification (5 labels)

`moodtune-backend/app/services/audio_analysis_service.py:20-28, 263-292`

Valence/energy quadrant model. Each track's `valence` and `energy` (0-1,
derived from librosa features — brightness, tempo, RMS loudness) is bucketed
into one of:

| Label | Rule (`determine_mood`) |
|---|---|
| `happy` | valence > 0.6 and energy > 0.6 |
| `sad` | valence < 0.4 and energy < 0.4 |
| `angry` | valence < 0.4 and energy > 0.6 |
| `calm` | energy < 0.4 (and not already sad) |
| `energetic` | everything else |

Each primary mood also gets 3 short descriptor tags (`_mood_descriptors`,
line 353), e.g. `happy` → `["upbeat", "bright", "lively"]`, with one tag
swapped for tempo/harmonic-ratio specifics (e.g. `"fast-paced"` if
tempo > 140 BPM).

`mood_scores` (raw valence/energy/tempo/brightness) is returned by the API but
currently **unused on the client** — parsed into the model, never rendered.

## 2. Flutter display layer (4 buckets)

`lib/app/theme/mood_theme.dart`

```dart
enum MoodIdentity { upbeat, serene, charged, reflective }
```

`MoodTheme.fromString()` maps backend strings down into one of these 4, each
with a fixed icon, gradient, all-caps label, and subtitle:

| Identity | Maps from (backend's 5 + unused synonyms*) | Look |
|---|---|---|
| `upbeat` | happy, energetic, joyful*, excited*, cheerful* | sun icon, warm gradient, "Happy & Energetic" |
| `serene` | calm, peaceful*, relaxed*, chill*, tranquil* | cool gradient, "Calm & Positive" |
| `charged` | angry, intense*, aggressive*, powerful*, fierce* | bolt icon, "Intense & Powerful" |
| `reflective` | sad, melancholic*, thoughtful*, somber*, nostalgic* (+ default fallback) | cloud icon, "Melancholic & Thoughtful" |

\* Synonym strings the backend never actually emits today — forward-compat
that isn't currently exercised.

## Where it's shown (and the inconsistency)

- **`results_page.dart`** (upload + catalog "analyze playlist" flow) — goes
  through the 4-identity theme: `MoodHeroCard` (icon/gradient/label/subtitle),
  `ConfidenceRing` donut, descriptor pill tags, reasoning paragraph, and
  tempo/energy/brightness/texture as human-readable label rows. Never shows
  the raw 5-label string.
- **`song_result_page.dart`** (Spotify catalog "analyze song" flow) —
  bypasses the theme entirely. Prints `primaryMood.toUpperCase()` as plain
  text plus raw numeric tempo/energy/valence/danceability/loudness rows. No
  icon, no color, no 4-bucket grouping.

## Open question

Reconcile the two result screens so the catalog "song analyze" flow also
renders through `MoodTheme`/`MoodHeroCard` instead of raw text — currently
the only place a user sees the unstyled 5-label taxonomy directly.
