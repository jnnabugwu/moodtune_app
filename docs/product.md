# MoodTune — Product

## Purpose

To explain a song to someone by the mood the song gives.

## What this means

- **A complex array of moods is fine.** The goal isn't to force every song into a small, tidy label set — it's to describe what the song actually feels like, even if that takes more than one word or axis. (See [ROADMAP.md](ROADMAP.md) section 6 — this is the reasoning behind letting CLAP drive a richer taxonomy instead of staying locked to the current 5-label / 4-bucket system.)
- **The user can upload a song and get the mood it's giving.** Upload is the core interaction, not an alternate path — whatever mood output the product settles on has to work from a raw uploaded file, not just from a catalog track with pre-existing metadata.
- **The mood is something to act on, not just read.** The output isn't a trivia fact about the song — it's meant to inform a decision the user makes next (what to play, what to add to a playlist, what fits the moment).

## Related docs

- [ROADMAP.md](ROADMAP.md) — how the mood engine gets from heuristics to CLAP
- [MOOD_TAXONOMY.md](MOOD_TAXONOMY.md) — current label/bucket definitions
- [ARCHITECTURE.md](ARCHITECTURE.md) — full system architecture
