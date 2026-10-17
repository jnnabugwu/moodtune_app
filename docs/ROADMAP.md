# MoodTune — Roadmap

> Living document. Charts the evolution of the mood engine from hand-crafted
> acoustic heuristics toward learned, semantic audio understanding (CLAP), with
> an optional LLM layer for reasoning and descriptors, and an on-device track
> (YAMNet) that runs mood classification on the phone.
> Last updated: 2026-10-16.

---

## 1. Where we are today

MoodTune classifies mood through **two independent heuristic paths**, both of
which reduce audio to a `(valence, energy)` point and bucket it:

| Path | Input | Feature source | Code |
|---|---|---|---|
| **Playlist analysis** | Spotify playlist | Spotify's precomputed audio features (`valence`, `energy`, `danceability`, `tempo`) | `app/services/analysis_service.py` |
| **Song / upload analysis** | Uploaded file or Spotify preview | librosa features (spectral centroid, tempo, RMS, chroma, MFCC, HPSS) hand-mapped to valence/energy | `app/services/audio_analysis_service.py` |

Both funnel into the same valence/energy quadrant model:

- **Backend** emits one of **5 labels** — `happy`, `sad`, `angry`, `calm`,
  `energetic` (`determine_mood`, `audio_analysis_service.py:263`).
- **Flutter** collapses those into **4 display identities** — `upbeat`,
  `serene`, `charged`, `reflective` (`lib/app/theme/mood_theme.dart`).

Confidence = Euclidean distance from the `(0.5, 0.5)` neutral center.

See [MOOD_TAXONOMY.md](MOOD_TAXONOMY.md) and [ARCHITECTURE.md](ARCHITECTURE.md)
for the full current-state description.

---

## 2. Why change — limitations of the current engine

1. **Valence is guessed, not measured.** On the upload path, `_estimate_valence`
   is a fixed `0.6·brightness + 0.4·tempo` weighting
   (`audio_analysis_service.py:146`). Brightness and tempo correlate weakly with
   perceived happiness — a bright, fast sad song scores "happy." There is no
   ground truth behind the weights.
2. **Arbitrary normalization.** Energy normalizes against a hardcoded `[0, 0.5]`
   RMS range; anything louder clamps to 1.0. Already flagged in
   [moodtune-backend/IMPROVEMENTS.md](https://github.com/jnnabugwu/moodtune-backend/blob/main/IMPROVEMENTS.md).
3. **Hard threshold cliffs.** `valence > 0.6` vs `0.599` flips the entire label
   and theme. No smoothing, no probability.
4. **Strategic dependency risk — Spotify audio features.** The playlist path
   leans entirely on Spotify's precomputed `valence`/`energy`. Spotify
   deprecated the Audio Features / Audio Analysis endpoints for new
   applications (Nov 2024). New client IDs cannot call them, so the playlist
   engine is not portable to fresh Spotify apps and needs an owned replacement.
5. **Two inconsistent surfaces.** `results_page.dart` renders the themed 4-bucket
   view; `song_result_page.dart` prints the raw 5-label string and numeric rows.
   (Open item already tracked in MOOD_TAXONOMY.md.)
6. **No semantics.** The engine knows tempo and brightness but not genre, mood
   nuance, instrumentation, or lyrical tone. "Nostalgic," "dreamy," "aggressive
   but joyful" are unreachable with 2 axes and 5 buckets.

---

## 3. Vision

Replace hand-tuned acoustic heuristics with a **learned audio embedding** that
understands music semantically, then layer optional **LLM reasoning** on top for
natural-language mood descriptions and playlist narratives.

```
 Audio ──▶ CLAP audio encoder ──▶ 512-d embedding
                                      │
                    ┌─────────────────┼──────────────────┐
                    ▼                 ▼                  ▼
          zero-shot text        valence/energy      LLM reasoning
          mood labels           regression head     (descriptors,
          (cosine to prompts)   (trained probe)      narrative copy)
```

This keeps the existing `(valence, energy)` contract intact where useful (so the
Flutter theme layer needs no rewrite) while giving us a semantic backbone that is
**owned, portable, and not dependent on Spotify's deprecated features.**

---

## 4. Research — the learned-audio path

### 4.1 CLAP (Contrastive Language-Audio Pretraining)

**What it is.** A LAION model that learns a joint audio–text embedding space —
the CLIP idea applied to sound. Trained on **LAION-Audio-630K** (audio paired
with natural-language captions).

**How it works.** Two encoders (audio + text) trained contrastively: matching
audio/caption pairs are pulled together in embedding space, non-matching pairs
pushed apart. The audio encoder learns **semantic** concepts, not just acoustic
statistics like tempo or RMS.

**Why it fits MoodTune.** Because audio and text share one space, we can:
- **Zero-shot classify** by embedding prompts like *"a happy upbeat song"*,
  *"a sad melancholic ballad"* and taking cosine similarity to the track
  embedding — no training data required to ship a first version.
- **Train a lightweight probe** (linear / small MLP) on top of frozen CLAP
  embeddings to regress `valence`/`energy` or predict our 5 labels, once we have
  ground-truth data.
- **Extend the taxonomy freely** — new moods are just new text prompts, not new
  threshold code.

**Key paper.** *Large-Scale Contrastive Language-Audio Pretraining with Feature
Fusion and Keyword-to-Caption Augmentation* (LAION) — evaluated across 16
downstream tasks in 8 domains.

**Checkpoints.**

| Checkpoint | Notes |
|---|---|
| `laion/clap-htsat-unfused` | Lightest, general-purpose, good for feature extraction |
| `laion/larger_clap_music_and_speech` | Larger, trained on music + speech. Untested. Its sibling `larger_clap_music` scored at chance in the spike (§4.3), likely a bad Hugging Face conversion, so verify before trusting it |

**Links.**
- GitHub: https://github.com/LAION-AI/CLAP
- HuggingFace: https://huggingface.co/laion/larger_clap_music_and_speech
- HuggingFace `transformers` also ships a `ClapModel` wrapper for both encoders.

**Cost / infra considerations.**
- Inference is a forward pass through a ~audio-transformer; feasible on CPU for a
  30-second clip but noticeably faster on GPU. Railway's current CPU dynos will
  work for low volume; a GPU inference service (or batched/cached embeddings)
  is the scale path.
- Model weights are a few hundred MB — a real change to the deploy image size and
  cold-start time vs. the current librosa-only backend. Plan for a dedicated
  inference service or a model-loading warmup step.
- Embeddings are cacheable by track ID — compute once, reuse across users.

### 4.2 The optional LLM layer

CLAP gives *understanding*; an LLM gives *language*. Two distinct roles — keep
them separate:

- **CLAP = classifier.** Cheap, deterministic, runs per track. Owns the
  valence/energy + label prediction.
- **LLM = narrator.** Given CLAP's structured output (mood, confidence,
  descriptors, per-track distribution), an LLM writes the human-facing
  copy: the reasoning paragraph, richer descriptor tags, and playlist-level
  narratives ("this playlist drifts from bright morning energy into late-night
  melancholy"). This replaces the hardcoded `reasoning` string and static
  `_mood_descriptors` table.

Guidance for when we build this layer lives in the `claude-api` skill (model
ids, pricing, structured output, caching) — **read it before wiring any LLM
call.** Default to the latest Claude models (Opus 4.8 / Sonnet 5 / Haiku 4.5;
pick Haiku for cheap per-track descriptor generation, a larger model for
playlist narrative). Do **not** put an LLM on the hot per-track classification
path — it is a presentation-layer enrichment, ideally cached and batched.

### 4.3 Spike results: CLAP vs YAMNet (2026-10)

Code and full write-up: `spikes/clap/README.md` in the local `moodtune/` workspace (not in a repo yet).

200 Jamendo tracks, 50 per display bucket, "truth" taken from the artists' mood
tags (a noisy proxy, not the hand-labelled Phase 0 set). Chance is 25%;
brackets are 95% confidence intervals.

| Engine | Accuracy | Size | Time per track (M4 Pro CPU) |
|---|---|---|---|
| Current rule-based backend | 32% (26–39) | — | ~7.4 s |
| CLAP `clap-htsat-unfused`, calibrated | **50% (44–57)** | 34 MB int8 | ~60 ms |
| **YAMNet (TFLite)** | 44% (37–51) | **4 MB** | ~30 ms |
| CLAP + YAMNet equal blend | 48% (41–55) | 38 MB | ~90 ms |
| CLAP `larger_clap_music` | 28% (23–35) | ~78 MB int8 | ~100 ms |

Takeaways:

- **Both learned models beat the heuristic**, which almost never predicts
  `charged` (3/50) and calls most `serene` tracks `reflective` (34/50).
- **Raw zero-shot is dominated by label bias.** Calibrating (centring each
  label's score on its mean across tracks, no ground truth needed) took CLAP
  from 37% to 50%.
- **YAMNet wins for on-device** (see §6): statistically level with CLAP at a
  tenth of the size, and its spectrogram is computed inside the `.tflite`, so
  there's no DSP front-end to port.
- **`serene` vs `reflective` is the hard pair for every engine.** They differ
  mainly in valence, which audio predicts poorly. Fixing it needs labelled data
  and a trained head (Phase 2 / OD-7), not better prompts.

---

## 5. Phased roadmap

### Phase 0 — Consolidate the current engine *(near term, no ML)*
Ship value and reduce risk before introducing models.
- [ ] Reconcile the two result screens — route `song_result_page.dart` through
      `MoodTheme`/`MoodHeroCard` (MOOD_TAXONOMY.md open item).
- [ ] Fix energy normalization (adopt percentile/adaptive approach from
      IMPROVEMENTS.md Option 1/2).
- [ ] Add a `mood_scores` render on the client (currently parsed, never shown).
- [ ] Establish an **evaluation set**: ~100–200 hand-labeled tracks spanning all
      moods. This is the prerequisite for measuring any future model.

### Phase 1 — CLAP zero-shot classifier (spike)
Prove semantic classification with zero training.
- [x] Stand up a CLAP inference path. Done in `spikes/clap` with
      `clap-htsat-unfused` and `larger_clap_music` (§4.3).
- [x] Embed three 10 s windows per track; cosine-match against a prompt bank
      for the 5 labels, with per-label calibration.
- [x] Compare accuracy vs. the current heuristic on a 200-track Jamendo-tag
      proxy set. **Gate passed on proxy data** (50% vs 32%). Re-check on the
      hand-labelled Phase 0 set once it exists.
- [ ] Decide hosting: in-process on the FastAPI dyno vs. a separate inference
      service. (Lean toward a separate service to keep the API lightweight.)

### Phase 2 — CLAP embeddings + trained probe
Move from prompts to a learned head once data exists.
- [ ] Cache CLAP embeddings by track ID (compute once, reuse).
- [ ] Train a small valence/energy regression + label-classification head on
      frozen embeddings using the labeled set.
- [ ] Keep the `(valence, energy)` output contract so the Flutter theme layer is
      unchanged; swap the *source* of those numbers from heuristic → learned.
- [ ] Retire `_estimate_valence` / hardcoded thresholds behind a feature flag;
      run both in shadow mode and compare before cutover.

### Phase 3 — Reduce Spotify dependence
De-risk the deprecated audio-features API.
- [ ] Replace the playlist path's reliance on Spotify precomputed valence/energy
      with our own CLAP-derived scores computed from previews/uploads.
- [ ] Playlist mood = aggregate of per-track CLAP scores instead of Spotify
      feature averages.

### Phase 4 — LLM narration layer
- [ ] Feed structured CLAP output into an LLM (via `claude-api` skill guidance)
      to generate descriptors, reasoning copy, and playlist narratives.
- [ ] Cache generated copy; never block the classification path on the LLM.
- [ ] Optionally expand the taxonomy beyond 5/4 buckets (richer semantic tags
      surfaced from CLAP prompt matching + LLM phrasing).

---

## 6. On-device track: YAMNet mood classification

Runs in parallel with Phases 1–4. Goal: classify mood **on the phone** for the
flows that have audio there (file upload and Jamendo catalog), with the backend
as fallback. Spotify library tracks stay server-side: there's no audio on the
device for them.

**Why YAMNet** (evidence in §4.3):

- 44% vs the heuristic's 32%, statistically level with CLAP (50%).
- 4.1 MB `.tflite`, 3.7M params, Apache 2.0, runs on iOS and Android.
- Takes raw 16 kHz audio and computes its own spectrogram inside the model, so
  there's no mel front-end to port (the riskiest step of an on-device CLAP).
- Bonus: its 521 AudioSet classes include instruments and vocal types, the
  "sound facts" narration currently has no source for.
- Uploads are the core interaction ([product.md](product.md)); classifying
  on-device is a step toward "your song never leaves your phone."

### 6.1 Target architecture

```
 Upload file / Jamendo clip (local file path)
        │
        ▼
 Native decoder: method channel `moodtune/audio_decode`
   iOS: AVAudioFile + AVAudioConverter
   Android: MediaExtractor + MediaCodec + resampler
   → three 10 s windows, mono float32 @ 16 kHz
        │  List<Float32List>
        ▼
 Dart: YamnetEngine (TFLite plugin, assets/models/yamnet.tflite)
   0.975 s frames, 0.48 s hop → mean of 521 class scores
        │
        ▼
 Dart: OnDeviceMoodClassifier
   5 mood classes → calibration (shipped JSON) → label, bucket, confidence
   sound tags (instrument/vocal allowlist + threshold)
        │
        ├──▶ UploadMoodResult: primaryMood, confidence, descriptors
        │      (any failure or timeout → keep the backend's mood)
        └──▶ NarrationInput: sound tags for MoodNarrator
```

Design decisions:

- **Native code only decodes; everything else is Dart.** Framing, mood mapping,
  calibration and tags exist once for both platforms and are unit-testable,
  like `MoodNarrator`. The decoder is reusable for upload trimming or a later
  on-device CLAP.
- **Same contract as narration:** an engine interface (`isAvailable`,
  `classify`), a timeout, and a fallback. The results screen never waits on
  or depends on the model.
- **Hybrid at first.** The backend still supplies tempo, energy, brightness and
  texture rows; on-device owns only mood, confidence and descriptors until
  OD-6.

### 6.2 Phases

**OD-0: Spike** ✅ *(2026-10-13)*. YAMNet via LiteRT in `spikes/clap`: 44%
(37–51) vs 32% for the heuristic; ~0.5 ms per frame on an M4 Pro.

**OD-1: Freeze model artifacts** *(~1 day, Python in `spikes/clap`)*
- [ ] Choose raw vs calibrated scoring on a **held-out split**. Both score 44%
      on the 200 tracks but fail differently: raw over-predicts `upbeat`,
      calibrated over-predicts `reflective`.
- [ ] Export `yamnet_calibration.json`: mood-class indices + per-label
      log-score mean/std.
- [ ] Define the sound-tag allowlist. Decided 2026-10-16:
      - **Categories:** instruments, vocals, and a few reliable genres
        (hip hop, metal, jazz). Other genre classes stay out; they're noisy
        ("Christmas music" on pop tracks).
      - **Vocals:** all vocal classes collapse into one "vocals" tag for now.
      - **Count:** 2–3 tags per song.
      - **Display wording:** chosen by ear with the listening sheet
        (`spikes/clap/results/tag_sheet.html`); all 61 classes kept, 55
        distinct tags. Saved as `spikes/clap/tag_decisions.json` →
        `results/yamnet_tag_allowlist.json` (peak pooling, threshold TBD).
      - **Score threshold (strictness):** deferred.
- [ ] Export golden fixtures for 5 tracks (decoded-window stats + expected mean
      scores) for parity tests in the app.

**OD-2: Native decode channel** *(~3–4 days)*
- [ ] `moodtune/audio_decode`: `decodeWindows(path, positions, seconds,
      sampleRate)` → `List<Float32List>`. Seek and decode only the 3 windows.
- [ ] iOS (`AudioWindowDecoder.swift` + channel in `AppDelegate.swift`):
      AVAudioFile + AVAudioConverter. Parity with librosa verified on macOS
      2026-10-16 (`spikes/clap/swift_parity`): 20/20 mood labels match, worst
      YAMNet score diff 0.005, ~200 ms per track. All five upload formats
      decode on macOS 26.6, ogg included; confirm ogg on the oldest supported
      iOS, where unsupported files fall back to the backend.
- [ ] Android (`MainActivity.kt`, the app's first Android channel):
      MediaExtractor + MediaCodec → PCM16 → mono → 16 kHz. Android has no
      public resampler, so write a windowed-sinc one or vendor a small library.
- [ ] Upload page: pass `file.path` to the classifier (it currently only
      sends `file.bytes` to the backend). Jamendo: download the clip to a temp
      file.
- [ ] Parity test: decoded windows vs librosa on the golden tracks.

**OD-3: Dart inference + domain layer** *(~2–3 days)*
- [ ] Bundle `yamnet.tflite` + calibration JSON as assets. Pick the runtime:
      `tflite_flutter` (official TensorFlow org, last release 2025-10) vs
      `flutter_litert` (community LiteRT wrapper, actively released). Check
      Google Play 16 KB page-size compliance and simulator support first.
- [ ] `YamnetEngine`: 15,600-sample frames, 7,680 hop, mean scores;
      interpreter loaded lazily, once.
- [ ] `OnDeviceMoodClassifier`: mapping → calibration → label, bucket,
      confidence, tags; timeout and fallback. Register in `injector.dart`
      next to `MoodNarrator`.
- [ ] Tests: unit tests on fixed score vectors (mapping, calibration, tags);
      on-device golden-score test within tolerance.
- [ ] Add YAMNet's Apache 2.0 notice to the app's licenses.

**OD-4: Shadow mode** *(~2 days to build, then 1–2 weeks of real use)*
- [ ] Classify on-device alongside the backend for upload and catalog, without
      showing it.
- [ ] Log both labels, latency, device model and failures (Talker + Sentry).
- [ ] Add "Does this feel right?" on the results screen, with a "which fits
      better?" mood picker on a thumbs-down. This is the first real
      ground-truth source (§7) and grades both engines.
- [ ] **Gate:** p95 latency < 1 s on the oldest supported devices (iOS 15,
      Android minSdk), failure rate < 2%, and on-device agrees with user picks
      more often than the backend.

**OD-5: Cutover** *(~2 days)*
- [ ] On-device owns `primaryMood`, confidence and descriptors for upload and
      catalog; backend mood is the fallback. Keep a kill switch.
- [ ] Feed sound tags into `NarrationInput`. Allow instrument and vocal words
      in narration only when a tag supports them (update the prompt and
      `MoodNarrator.isGrounded`).
- [ ] Recompute calibration constants from shadow-mode data (Jamendo isn't
      what users upload).
- [ ] Fix overconfident probabilities before showing confidence (decided
      2026-10-16: after the model works on device). Calibrated scores plus
      softmax are very peaky: a synthetic chord with no mood comes out
      "angry" at 95%. Fit a temperature on OD-4's user labels so stated
      confidence matches how often the label is right. Until then, use the
      top label only and log, don't display, the probability.

**OD-6: Fully on-device upload** *(optional, later)*
- [ ] Compute energy (RMS) and brightness (spectral centroid) from the same
      PCM. Tempo needs beat tracking: port a simple onset-autocorrelation
      estimator or drop the tempo row.
- [ ] Persist history locally, or send only the result (not the audio) to the
      backend.

**OD-7: Beyond zero-shot** *(once ground truth exists)*
- [ ] Re-export YAMNet with its 1024-d embedding output (the MediaPipe
      `.tflite` only returns the 521 scores) and train a small head on
      user-labelled data: the on-device version of Phase 2. This is the
      realistic fix for `serene` vs `reflective`.
- [ ] Revisit on-device CLAP if it stays ahead on the hand-labelled set; the
      OD-2 decoder is reusable.

**Estimate:** OD-1 to OD-5 ≈ 10–14 dev days plus the shadow period. The core
(OD-2 + OD-3) is about a week.

### 6.3 Risks

- **Accuracy ceiling.** 44% beats today's engine but is still wrong about half
  the time. Keep the confidence ring honest and the copy modest.
- **Calibration drift.** Constants fitted on Jamendo may not suit real
  uploads; refit from shadow data (OD-5).
- **Android decoding** is the biggest unknown: codec variety and no platform
  resampler.
- **ogg on older iOS** may not decode natively → backend fallback.
- **App size** grows by ~4 MB.

---

## 7. Open questions / decisions

- **Where does CLAP run?** In-process vs. dedicated GPU inference service vs.
  batch-precompute-and-cache. Drives cost and latency. (For upload and catalog
  mood, §6 moves classification onto the device instead.)
- **On-device scoring:** raw or calibrated YAMNet scores? Decide on a held-out
  split in OD-1.
- **On-device runtime:** `tflite_flutter` vs `flutter_litert` (OD-3).
- **Hybrid or fully on-device uploads?** OD-6 removes the backend round trip
  but needs on-device tempo and local history.
- **Do we keep the 2-axis valence/energy contract**, or let CLAP drive a richer
  multi-label taxonomy end to end? Keeping the contract minimizes Flutter churn;
  replacing it unlocks nuance.
- **Ground truth.** Where do labels come from — internal hand-labeling, user
  feedback capture, or an existing labeled music-mood dataset?
- **Preview availability.** Spotify preview URLs are increasingly unreliable;
  how much does the analysis pipeline depend on them vs. user uploads?
- **Confidence semantics.** Distance-from-center confidence is heuristic; a
  trained probe can emit calibrated probabilities instead.

---

## 8. Related docs

- `spikes/clap/README.md` (local `moodtune/` workspace, not in a repo yet) — CLAP vs YAMNet spike: code, results, lessons
- [MOOD_TAXONOMY.md](MOOD_TAXONOMY.md) — current 5-label / 4-bucket taxonomy
- [ARCHITECTURE.md](ARCHITECTURE.md) — full system architecture
- [moodtune-backend/IMPROVEMENTS.md](https://github.com/jnnabugwu/moodtune-backend/blob/main/IMPROVEMENTS.md) — engine improvement backlog
