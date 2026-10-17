# On-device Mood Classification: Build Log

Plan: [ROADMAP.md §6](ROADMAP.md) · Spike: [spikes/clap/README.md](../../spikes/clap/README.md) · Showcase: [on-device-mood-system-design.md](on-device-mood-system-design.md)
Statuses: not started → in progress → in code → merged → verified

## Status

| Phase | Item | Status | Evidence |
|---|---|---|---|
| OD-0 | Spike: YAMNet vs CLAP vs heuristic on 200 tracks | verified | `spikes/clap/README.md` findings, 2026-10-13 (44% vs 32%). Committed only on backend `chore/clap-spike` (`bcce878`, no PR) and app `9e82299` (stranded); **on neither `main`**. The OD-6 script `05_feature_parity.py` exists only in the untracked parent folder |
| OD-1 | Raw vs calibrated scoring chosen on a held-out split | in progress | Calibrated shipped (PR #26); no held-out comparison recorded |
| OD-1 | Calibration + mood mapping exported (`yamnet_mood.json`) | merged | PR #26 (`43ead0f`); `mood.minScore` added in `4f64ecd` |
| OD-1 | Sound-tag allowlist | merged | PR #26; 61 classes, max 3 tags, peak pooling |
| OD-1 | Tag score threshold | not started | Still `threshold: null`; deferred 2026-10-16 |
| OD-1 | Golden fixtures for parity tests | verified | `yamnet_mood_model_test.dart` passes: 5 labelled tracks + 1 no-mood track, probabilities ±1e-4, tags with a cutoff that keeps and drops tags (PR #26, `4f64ecd`) |
| OD-2 | iOS decoder + `moodtune/audio_decode` channel | merged | PR #24 (`67c73d0`) |
| OD-2 | Android decoder (MediaCodec + resampler) | not started | Android now skips on-device entirely (`isSupported`, `7c024df`) |
| OD-2 | Upload page passes `file.path`; Jamendo clip to temp file | merged | PR #27 (`d1e5c0c`): `upload_music_page.dart`; `DioAudioDownloader` (30 MB cap, 20 s total) |
| OD-2 | Decoder parity vs librosa | verified | macOS parity, PR #24: 20/20 labels, correlation 0.97–1.00, worst score diff 0.005 |
| OD-3 | Runtime chosen + model and config bundled | merged | PR #26: `flutter_litert` ^3.9.3, `assets/models/` |
| OD-3 | `YamnetEngine` (frames, isolate, lazy interpreter) | merged | PR #26; rejects non-16 kHz audio (`4f64ecd`) |
| OD-3 | `OnDeviceMoodClassifier` (timeout, fallback, DI) | merged | PR #26; `attempt()` with failure categories and `busy` guard (PR #27, `4f64ecd`) |
| OD-3 | Unit tests + on-device golden test | merged | PR #26/#27. Integration test 4/4 on an iPhone 16 Pro **simulator** (iOS 18.6); not yet run on a physical iPhone, and no run recorded after `4f64ecd` changed its expectation to "no mood" |
| OD-3 | YAMNet Apache 2.0 notice in app licenses | merged | PR #26 (`registerYamnetLicense()`) |
| OD-4 | Shadow classification on upload + catalog | merged (not shadow) | PR #27 classifies alongside the backend but **shows** the result; shadow period skipped |
| OD-4 | Logging: both labels, latency, device, failures | merged | PR #27 → backend PR #9 (`513b80a`, review fixes `0c6c83c`) **deployed to Railway production** 2026-10-16 19:26 UTC. Jordan ran `db/mood_observations.sql`, then re-ran it for the mood CHECK constraints. No rows confirmed yet: the first build with this code is going to TestFlight |
| OD-4 | "Does this feel right?" feedback + mood picker | merged | PR #27 `MoodFeedbackPrompt` → `PATCH /mood-observations/{id}/feedback` |
| OD-4 | Gate: p95 < 1 s, failures < 2%, beats backend on user picks | not started | No phone or user data yet; cutover shipped before the gate. History's "Compare engines" view (PR #33) shows a per-user version of the agreement metric |
| OD-5 | On-device owns mood; backend fallback; kill switch | merged | PR #27 `MoodSwitchover`; kill switch live in production (`GET /config` → `{"on_device_mood":true}`, checked 2026-10-16). TestFlight build from `f7115cc` in progress (Jordan filling in "What to Test"); not yet in testers' hands |
| OD-5 | Sound tags feed `NarrationInput` + `isGrounded` | merged | PR #27; guard covers every tag in `yamnet_mood.json` (`7c024df`) |
| OD-5 | Recalibrate from shadow data; temperature for confidence | not started | On-device moods hide the confidence ring meanwhile (PR #27) |
| OD-6 | Parity spike: tempo, energy, brightness, texture from the phone's windows | verified | `spikes/clap/05_feature_parity.py` → `results/feature_parity.md`, 200 tracks on the M4 Pro (untracked parent folder, not committed) |
| OD-6 | Dart feature extractor (RMS, centroid ×1.218, HPSS ratio, mel-onset tempo) | not started | |
| OD-6 | Backend mood rule on the phone (keeps `backend_mood` in observations) | not started | Spike: replica agrees with the backend 82% |
| OD-6 | Uploads skip the backend on iOS (fallback upload on failure; Android unchanged) | not started | |
| OD-6 | History: result saved without audio (chosen over local history) | merged | Backend PR #10 (`962e46b`, deployed 21:15 UTC), app PR #33 (`e468a91`); review fixes `5629db3`, `9196432` |
| OD-7 | Embedding head trained on user labels | not started | |

## Mistakes and lessons learned

Newest first. One line each: date · name · lesson · commit/PR.

- 2026-10-16 · Read the data flow before stating a constraint · Claude said OD-6 would break upload history, but the upload route never saved history (guest-only), and Jordan decided on that basis; check the route and CRUD before presenting a dependency as fact · corrected before building PR #33
- 2026-10-16 · Sample-rate-dependent features need rescaling · At 16 kHz the spectral centroid reads ~18% lower than the backend's 22.05 kHz, so brightness labels agreed only 78%; map with a fitted scale (×1.218, 91%) or refit thresholds before reusing a server's cut-offs · `spikes/clap/05_feature_parity.py`
- 2026-10-16 · "Loaded" is a state, not a non-empty list · The post-save reload checked `history.isNotEmpty`, so a user with empty history never saw their first saved row; track `historyLoaded` · `9196432` (cubic, PR #33)
- 2026-10-16 · A user action beats a pending read · The comparison toggle's `load()` and a tap waited on the same `SharedPreferences.getInstance()`, and the load resumed first and reset the tap; let a write invalidate in-flight loads · `9196432` (cubic, PR #33)
- 2026-10-16 · Mutation-check every regression test, especially for races · The first race test passed with the fix removed because its fake let the write land before the read; reproduce the real await ordering and confirm the test fails without the fix · `9196432`
- 2026-10-16 · Use absolute paths in parallel shell calls · Two parallel commands ran in the wrong repo (switched the backend's branch, tried a PR there); harmless, but pass `git -C <repo>` or absolute paths when running commands side by side · this session
- 2026-10-16 · Check a PR is still open before pushing to its branch · The spike commit was pushed to `feat/on-device-yamnet` two minutes after PR #26 merged, so it never reached `main`; run `gh pr view` first, and branch fresh once a PR has merged · `9e82299` (stranded)
- 2026-10-16 · Commit the generator with what it generates · The golden fixture's generator lived in an untracked folder, so nobody could regenerate or audit the expectations; keep the script in the repo that holds its output · `9e82299`, backend `bcce878` (cubic, PR #26)
- 2026-10-16 · Run `pub get` before formatting a fresh worktree · Without a package config, `dart format` used the newest language version and reformatted 28 unrelated files; set up the worktree first, and format only the files you touched · `4f64ecd` (caught before commit)
- 2026-10-16 · A suggestion isn't a build · An accepted review suggestion removed `stopwatch` but left a use of it, and PR #26 stopped compiling; run `flutter analyze` after accepting bot suggestions on GitHub · `0326030` → `4f64ecd`
- 2026-10-16 · Match numeric types in the reference implementation · Python derived golden expectations from float64 values that Dart reads as float32, so a tag exactly at the cutoff disagreed; derive expectations from the same types the port uses · `4f64ecd`
- 2026-10-16 · Prove a fixture exercises the branch · The tag-cutoff golden used a threshold above every tag score, so it passed whatever the code did; assert the fixture both keeps and drops, and mutation-check `>=` vs `>` · `4f64ecd` (cubic, PR #26); seen again in PR #33's failed-save test, which asserted nothing its name claimed (`9196432`)
- 2026-10-16 · If work can't be cancelled, gate re-entry · A timeout only stopped waiting, so repeated attempts could stack decode and inference work; refuse new attempts (`busy`) until the old one finishes · `4f64ecd` (cubic, PR #26)
- 2026-10-16 · Telemetry gets fixed categories, never error text · Raw exception text sent with observations could carry file paths and track URLs; record `timeout`, `download: <type>`, `decode: <code>` instead · `7c024df` (cubic P1, PR #27)
- 2026-10-16 · Network timeouts bound gaps, not totals · Dio's `receiveTimeout` let a trickling catalog download run on after the result was shown; cap the whole download (20 s) · `7c024df` (cubic, PR #27)
- 2026-10-16 · Guards derived from data, not a hand list · Narration's instrument guard missed tags YAMNet can emit (banjo, flute, organ); build it from `yamnet_mood.json` and test it against the file · `7c024df` (cubic, PR #27)
- 2026-10-16 · No signal, no label (corrects "Softmax is overconfident") · The chord's 95% "angry" wasn't untempered softmax: every mood class scored 0, so softmax ran on the epsilon floor and the lowest reference mean won; a temperature wouldn't fix it. Check the input has signal (`mood.minScore`) before reading a probability, and still fit a temperature before showing confidence · `4f64ecd` (cubic, PR #26)
- 2026-10-16 · Validate specs on both sides of a channel · Invalid window specs crashed the native decoder; check them in Dart and Swift and return a typed `bad_args` · PR #24 (cubic review)
- 2026-10-16 · Average pooling hides instruments · Mean over frames gave 87% of tracks no tags; pool tags by peak frame, keep mood on mean · `spikes/clap/03_tag_sheet.py`
- 2026-10-13 · Small test sets lie · 40 tracks suggested a CLAP + YAMNet blend helped; 200 showed it didn't · spike
- 2026-10-13 · Pick the top label, don't sum per bucket · Summing label probabilities favours buckets made of more labels · spike
- 2026-10-13 · Converted models can ship broken temperatures · `larger_clap_music` softmax sat at ~0.2 for every label; ranking survived, probabilities didn't · spike
- 2026-10-13 · Label bias dominates zero-shot · Centring each label's score on its mean across tracks took CLAP from 37% to 50%, with no ground truth needed · spike

## Entries

### 2026-10-16 (evening) · Backend live, OD-6 parity spike, history compares both engines

**Done**

- **OD-4 and OD-5 backend in production.** Backend PR #9 (`513b80a`, with review fixes `0c6c83c`) deployed to Railway production at 19:26 UTC. `GET /config` returns `{"on_device_mood":true}` (checked 2026-10-16). Jordan ran `db/mood_observations.sql`, and then re-ran it to add the mood CHECK constraints, which are added by name in a guarded `DO` block so a re-run upgrades an existing table.
- **PR #9 review fixes** (`0c6c83c`):
  - generic 500 details, with the exception logged server-side;
  - a shared `Mood` literal for `backend_mood`, `on_device_mood`, `displayed_mood` and the probability keys, mirrored by SQL CHECKs;
  - trimmed, non-empty tags;
  - a test fake that asserts updates filter on `id`.

  The migration was tested locally on Postgres 16 three ways: a fresh run, a re-run, and an upgrade over the original table with a row in it.
- **OD-6 parity spike** (`spikes/clap/05_feature_parity.py`, untracked parent folder). It computes the backend's four audio rows from the phone's three 10 s windows at 16 kHz, in plain NumPy written to port directly to Dart, and compares them with the backend on all 200 tracks. Results are under Measurements.
- **History compares both engines** (an OD-6 item, done early):
  - **Backend PR #10** (`962e46b`, deployed 21:15 UTC): `POST /song/history` (auth required) saves a finished upload or catalog result. It carries title, source, displayed mood and source, backend mood, on-device mood, confidence and observation id, and no audio. `GET /song/history` joins the caller's own 👍/👎 from `mood_observations`. `/catalog/analyze` gains `save_to_history` (default true). Review fixes: `5629db3`.
  - **App PR #33** (`e468a91`): `AnalysisBloc` saves the record after the result is shown (fire and forget; guests skipped) and sends `save_to_history: false` for catalog tracks. History has a "Compare engines" toggle (off by default, stored with `shared_preferences`) that shows `On-device SERENE · Backend UPBEAT`, a match mark, the answer and which engine it's about, plus a summary card. Review fixes: `9196432`.
- **Release prep:** a version bump on `main` (`f7115cc`); Jordan is uploading a TestFlight build.

**Decisions**

- **Tempo: port an estimator, don't drop the row** (Jordan, 2026-10-16). Mel-band onset flux → autocorrelation → 120 BPM log-normal prior → parabolic peak.
- **History: send the result, not local-only storage** (Jordan). Keeps cross-device history and the existing History page; the audio still never goes there. This answers ROADMAP OD-6's "persist history locally, or send only the result".
- **Comparison is behind a toggle, off by default** (Jordan). Testers see a normal history; Jordan turns it on.
- **Engines are compared at the 4-bucket level** (`happy` and `energetic` both count as UPBEAT), because that's what users see and pick. A 👍 credits the shown engine. A 👎 credits whichever engine matches the picked bucket; a 👎 without a pick isn't counted.
- **No environment column on `mood_observations`** (Jordan). Jordan tests on the production build, so a flavor tag wouldn't separate those rows anyway. Filter by Jordan's `user_id` when signed in; simulator rows are filterable via `device_model = 'arm64'`.
- **Brightness: map with a scale, keep the backend thresholds.** Use the fitted ×1.218 (backend ≈ 1.2179·phone − 2.98) rather than refitted cut points. It's one constant, and it also feeds the mood rule. Energy and texture keep the backend thresholds.
- **Port the backend's mood rule to the phone** (proposed, not built), so observations keep a `backend_mood` once uploads skip the server. Mark those rows as phone-computed when it lands.

**Roadmap open questions resolved**

- OD-6 tempo: port an estimator (mel onset version), rather than dropping it.
- OD-6 history: send the result to the backend, no audio.
- Not settled: tag threshold (still `null`); raw vs calibrated on a held-out split; whether uploads stop going to the backend on iOS once OD-6 lands.

**Measurements**

All of these are from the M4 Pro, on the 200 Jamendo spike tracks. The phone pipeline was emulated in NumPy on librosa's 16 kHz decode, not the Swift decoder.

| Row | Agreement with backend label | Notes |
|---|---|---|
| Energy (mean RMS) | 92% with the backend thresholds (94% refit) | correlation 0.970 |
| Brightness (centroid) | 78% as is, 91% scaled ×1.218 | correlation 0.952 |
| Texture (HPSS ratio in the spectrogram) | 95% with the backend thresholds | correlation 0.933 |
| Tempo, mel onsets | 84% within 4%, 93% at any octave; median error 1.7 BPM; slow/mid/fast agrees 82% | |
| Tempo, linear bins | 76% within 4%, 90% at any octave | worse; not chosen |
| Backend mood rule on phone values | 82% same label as the backend (mapped inputs, mel tempo); 74% raw | |
| Accuracy vs Jamendo truth | phone replica 34%, real backend 32% | n=200, chance 25% |

- Synthetic checks (M4 Pro): click tracks at 72–150 BPM within 0.4 BPM; 174 BPM read as 87 (the half-tempo error librosa's prior also makes); a 440 Hz tone has centroid 440 Hz and harmonic ratio 1.00; white noise has centroid 4 kHz and ratio 0.50.
- Tests: app 816 → 858 (PR #33) → 862 (review fixes). Backend 43 → 56 (PR #9 fixes) → 78 (PR #10) → 80 (review fixes).
- **Still no physical-phone numbers** for YAMNet. The only phone run this session was narration on Jordan's iPhone.

**Blockers / risks found**

- **No gate data yet.** The cutover and telemetry are live on the server, but no tester build carries them until the TestFlight build ships.
- **Spike drift.** `05_feature_parity.py` exists only in the parent folder, which has no commits. The spike's three copies have now diverged.
- **Shared table with dev testing.** Jordan's own tests land in the same `mood_observations` and `song_analyses` rows as testers'. Signed-out rows from Jordan's phone can't be separated later.
- **The phone's backend label isn't the backend's.** Once OD-6 lands, `backend_mood` for uploads will be the phone's copy of the rule, which agrees 82% with the real one; analyses must know which rows came from where.
- **History filter chips never match.** They compare the stored label (`calm`) with the bucket (`serene`). This bug predates the session; noted in PR #33, not fixed.
- **Upload titles now stored.** Signed-in users' upload titles are kept in their own RLS-protected history. `mood_observations` stays title-free.

**Mistakes, bugs and lessons learned**

- **Wrong claim about upload history (Claude).**
  - **What went wrong:** Claude told Jordan that moving uploads on device would break history, and asked Jordan to choose a history strategy on that basis.
  - **How it was found:** reading `audio_upload.py` while designing the history endpoint: the route is guest-only and saves nothing.
  - **Root cause:** assumed uploads were saved like catalog tracks, without reading the route.
  - **Fix:** corrected before any code was written; Jordan then chose to add upload history as a new feature (PRs #10, #33).
  - **Lesson:** read the data flow in code before presenting it as a constraint.
- **Brightness drift at 16 kHz.**
  - **What went wrong:** brightness labels agreed only 78% with the backend.
  - **How it was found:** the OD-6 parity spike.
  - **Root cause:** the centroid depends on sample rate and bandwidth: the phone decodes at 16 kHz (8 kHz Nyquist), the backend at 22.05 kHz.
  - **Fix:** a linear map (×1.218 → 91%), to go into the Dart port.
  - **Lesson:** rescale sample-rate-dependent features before reusing server thresholds.
- **PR #33 review bugs** (cubic), all fixed in `9196432`:
  - an empty history counted as "not loaded", so the first saved row never appeared (now `historyLoaded`);
  - the toggle's async load could overwrite a tap (a write now invalidates in-flight loads);
  - the type tag jumped left when confidence was missing (`Spacer`);
  - the failed-save test asserted nothing it was named for;
  - the comparison line didn't say which engine a 👍/👎 was about or what was picked.
- **Race test that couldn't fail (Claude).**
  - **What went wrong:** the first regression test for the toggle race passed with the fix removed.
  - **How it was found:** a mutation check.
  - **Root cause:** the fake let the tap's write finish before the load read the stored value; in the app, both await one pending `getInstance()` and the load resumes first.
  - **Fix:** the test now shares one pending future between load and tap (`9196432`); it fails without the guard.
  - **Lesson:** reproduce the real await ordering, and mutation-check every regression test.
- **PR #10 review bugs** (cubic), fixed in `5629db3`:
  - `user_mood` typed as any string instead of `UserMood`;
  - the history query's user scope was untested;
  - the guest catalog path was untested.
- **PR #9 review bugs** (cubic), fixed in `0c6c83c`:
  - raw storage errors in 500s;
  - unvalidated mood labels and empty tags;
  - a test fake that ignored the filter column.

  Rate limiting was deferred, with the reason posted in the thread: it needs the real client IP behind Railway's proxy, and abuse filtering is planned before OD-7 trains.
- **Wrong working directory in parallel commands (Claude).** Two parallel commands ran in the backend repo: one switched it from the merged `feat/mood-observations` to `main`, another tried to open the app PR there. No work was lost.
- **App Store Connect "What to Test" error with a blank message.** Most likely the emoji (👍/👎) in the text; an emoji-free version was provided. Whether that fixed it is unconfirmed.

**Next step**

Once the TestFlight build is installed, run `integration_test/yamnet_device_test.dart` on Jordan's iPhone and do one upload and one catalog track signed in. Record decode, inference and total time, and check that a `mood_observations` row and a `song_analyses` row land. Those are the first phone latencies the OD-4 gate needs. After that, port the OD-6 feature extractor to Dart, against fixtures exported from `05_feature_parity.py`.

### 2026-10-16 (later) · OD-3 merged, cutover shipped, review fixes

**Done**

- **OD-3 merged** in PR #26 (`43ead0f`, from `c18b143`): `YamnetEngine`, `YamnetMoodModel`, `OnDeviceMoodClassifier`, assets, license notice, unit tests and the device integration test.
- **Review fixes for PR #26** in `4f64ecd`, merged with it:
  - restored the stopwatch an accepted suggestion (`0326030`) had broken;
  - `mood.minScore` (5e-4): below it there's no mood, and the backend's is kept;
  - a `busy` guard while timed-out work is still running;
  - non-16 kHz audio rejected by the engine; config `version` and `input` framing checked against the engine;
  - a missing log-score mean fails as a `FormatException`;
  - golden fixture regenerated: pretty-printed with `source` and `version`, a no-mood track, and a cutoff some tags sit exactly on.
- **OD-5 cutover and the app half of OD-4** in PR #27 (`d1e5c0c`, from `767821b`, `ca0d8da`, `f5bf179`, fixes `7c024df`):
  - `MoodSwitchover` classifies uploads (local path) and catalog tracks (downloaded by `DioAudioDownloader`: 30 MB cap, 20 s total, deleted afterwards), and swaps the on-device mood and tags into the backend's result. Tempo, energy and the other rows stay the backend's.
  - `AnalysisBloc` starts on-device classification before the backend call and waits at most 3 s (`onDeviceGrace`) after the backend answers; a backend error shows immediately.
  - Failures are fixed categories: `disabled`, `unsupported`, `download: <type>`, `busy`, `timeout`, `no_mood`, `late`, `decode: <code>`, `classification_failed`.
  - On-device moods hide the confidence ring and show sound tags as pills. Narration hears the tags and may name an instrument, vocals or genre only when a tag backs it.
  - `mood_feedback` feature: `MoodObservationRecorder` stores each result fire-and-forget (both labels, tags, probabilities, latency, failure, platform, OS, device model, app version; no titles, files or audio). `MoodFeedbackPrompt` asks "Does this feel right?", with a 4-mood picker on 👎. Feedback waits until its observation is stored.
  - Android skips on-device entirely (`isSupported`).
- **Backend PR #9** (`513b80a`): `POST /mood-observations`, `PATCH /mood-observations/{id}/feedback`, `GET /config` with the `ON_DEVICE_MOOD_ENABLED` kill switch, and `db/mood_observations.sql`.
- **Spike committed**: backend `bcce878` on `chore/clap-spike` (pushed, no PR). App `9e82299` on `feat/on-device-yamnet`, which isn't on `main` (see mistakes). Scripts now find the app and backend as the current repo or a sibling.

**Decisions**

- **Cut over without a shadow period.** PR #27 shows the on-device mood straight away instead of running it dark first, so the OD-4 gate hasn't been measured. Safeguards: the remote kill switch, both labels recorded for every result, user feedback, and a backend fallback for every failure. Why the shadow period was skipped isn't recorded (asked below).
- **"No mood" is a fallback, not a label.** If no mood class reaches `minScore`, the backend's mood is shown. Only 1 of the 200 reference tracks falls below it.
- **3 s grace after the backend.** The results screen never waits more than 3 s for on-device after the backend answers; a late result is recorded as `late`.
- **One attempt at a time.** Decode and inference can't be cancelled, so a new attempt during timed-out work returns `busy`.
- **The kill switch fails open.** `GET /config` is cached 10 minutes, and network errors keep the last known value, defaulting to enabled.
- **Telemetry to the backend table, not Sentry.** Observations go to `mood_observations` (Supabase via FastAPI) so they can be joined with feedback; Talker still logs locally.
- **No confidence for on-device moods** until a temperature is fitted (OD-5).

**Roadmap open questions resolved**

- Shadow mode vs direct cutover (OD-4/OD-5): direct cutover with kill switch and side-by-side logging.
- Ground-truth source (§7): in-app "Does this feel right?" plus picker, stored against each observation.
- Hybrid vs fully on-device: hybrid confirmed. Only the mood, tags and narration come from the phone.
- Not settled: tag threshold (still `null`), raw vs calibrated on a held-out split.

**Measurements**

- iPhone 16 Pro **simulator**, iOS 18.6 (runs on the Mac's CPU, so not phone numbers): YAMNet 95 ms first run including model load, 53 ms warm (PR #26); 56 ms warm, integration test 4/4 (PR #27).
- Mood-score floor, from the spike's 200 Jamendo tracks: the highest mood-class mean per track is 0 for 1 track, under 1e-3 for 5, 0.0014 at the 5th percentile and 0.0074 at the median. 5e-4 drops 1 track.
- Unit tests: 718 (PR #26) → 816 (PR #27).
- Regenerating the assets and fixtures (scores all 200 tracks): ~46 s on the M4 Pro.
- **Still no physical-phone numbers.**

**Blockers / risks found**

- Cutover is merged before any OD-4 gate data exists. The kill switch is the only brake until observations arrive.
- Never run on a physical iPhone. All latency is from the simulator.
- Backend PR #9's deploy and the Supabase migration aren't confirmed. Until then observations fail silently (logged), so no gate data is being collected. cubic's P1 on `db/mood_observations.sql` is still unresolved: re-running it fails if older rows hold invalid moods.
- The observation and feedback endpoints are public; abuse could pollute the training data (cubic, PR #9).
- History, served by the backend, still shows the backend's mood for catalog tracks, so it can differ from what was displayed.
- `minScore` and the calibration means come from Jamendo; real uploads may sit differently.
- The spike now exists in three copies (parent folder, backend branch, app branch), which can drift. The app copy isn't on `main`.

**Mistakes, bugs and lessons learned**

- **"Angry at 95%" was a no-signal artifact, not overconfidence.**
  - **What went wrong:** silence or a test tone came out a confident "angry". The device test asserted that label as "parity".
  - **How it was found:** cubic review on PR #26 (mood expectation computed from the epsilon floor only).
  - **Root cause:** all five mood classes scored 0, so softmax ran on `log(1e-9)` minus each reference mean, and "angry" has the lowest mean. A temperature fit wouldn't fix it.
  - **Fix:** `mood.minScore` guard in Python and Dart, a no-mood golden track, and the device test now expects "no mood" (`4f64ecd`).
  - **Lesson:** check that the input carries signal before reading any probability.
- **Accepted suggestion broke the build.**
  - **What went wrong:** PR #26 stopped compiling: `stopwatch` was used but no longer defined.
  - **How it was found:** reading the classifier while fixing review comments.
  - **Root cause:** a cubic suggestion applied on GitHub renamed the variable in two of three places.
  - **Fix:** `4f64ecd`.
  - **Lesson:** run `flutter analyze` after accepting a suggestion.
- **Vacuous cutoff test.**
  - **What went wrong:** the golden "tags with a cutoff" checks passed whatever the code did.
  - **How it was found:** cubic review.
  - **Root cause:** threshold 0.1, but no tag peak exceeded 0.082, so every expectation was `[]`.
  - **Fix:** the threshold is now 15/256 (a quantised YAMNet score), and a test asserts the cutoff both keeps and drops tags. A `>` mutation fails (`4f64ecd`).
  - **Lesson:** prove a fixture exercises the branch it claims to test.
- **float32 parity gap.**
  - **What went wrong:** with a real cutoff, Python kept a tag Dart dropped (Human Light, Love is a Journey).
  - **How it was found:** the newly non-vacuous test failed.
  - **Root cause:** the generator compared float64-rounded scores, while Dart reads the fixture into `Float32List`s, so a stored 0.0585938 became slightly less than the threshold. Production compares the same float32s on both sides; only the fixture disagreed.
  - **Fix:** the generator derives expectations from float32 values, and the threshold is that exact float32 (`4f64ecd`).
  - **Lesson:** a reference implementation must use the port's numeric types.
- **Other PR #26 review bugs** (cubic), all fixed in `4f64ecd`:
  - The timeout didn't stop work, so attempts could stack. Fixed with a `busy` guard.
  - Non-16 kHz audio was scored silently wrong. Now rejected.
  - Config `version` and `input` framing were never checked. Now validated.
  - A missing log-score mean surfaced as a null-check error. Now a `FormatException`.
  - The stack trace was dropped from the catch-all. Now logged.
  - The fake engine ignored its input. It now asserts it received the decoder's audio.
  - The device test leaked its temp folder. Now deleted in `tearDownAll`.
- **PR #27 review bugs** (cubic), fixed in `7c024df` unless noted:
  - P1: raw exception text in `onDeviceError` could carry the file path or track URL. Now fixed categories.
  - Android downloaded up to 30 MB and loaded the model only to fail at decode. Now `isSupported`.
  - Downloads had no total limit. Now capped at 20 s.
  - A backend error waited up to 3 s for on-device. Now shown immediately.
  - The narration guard missed tags such as banjo, flute and organ. It now covers every tag in `yamnet_mood.json`.
  - A clock rollback kept a stale kill-switch value. Now refetched.
  - The simulator reported `arm64` as its device model. Now null.
  - The domain layer imported `dart:io` for `AudioDownloader`. It now returns a path.
  - Several always-true test assertions were tightened: elapsed time, any `Left`, a "404" test that sent a 500.
  - Still open: the thank-you shows even when feedback failed to store (P3).
- **Backend PR #9 review bugs** (cubic), fixed in `0c6c83c`: storage errors leaked to callers; mood labels and tags weren't validated. Still open: the migration re-run P1. The rate-limiting thread was resolved without a recorded fix.
- **Process mistakes (Claude):**
  - `dart format` run in a fresh worktree before `flutter pub get` reformatted 28 unrelated files. Caught by `git status` and reverted before commit.
  - The spike commit `9e82299` was pushed to PR #26's branch two minutes after that PR merged (14:55 merge, 14:57 push), so it isn't on `main`.
  - Lesson: check PR state before pushing follow-ups.

**Next step**

Deploy backend PR #9 (fix the migration re-run first, then run `db/mood_observations.sql`). Then use a physical iPhone for one upload and one catalog track, run `integration_test/yamnet_device_test.dart`, and confirm the observation rows land. That gives the first phone latencies and starts the OD-4 gate data that the cutover skipped.

### 2026-10-16 · Seed entry (OD-0 to OD-3 so far)

**Done**

- OD-0 spike (2026-10-13, `spikes/clap`): 200 Jamendo tracks, 50 per display bucket. YAMNet scored 44% (37–51) at 4 MB and ~30 ms per track on an M4 Pro CPU. Calibrated CLAP scored 50% (44–57) at 34 MB, and the rule-based backend 32% (26–39). Chance is 25%.
- OD-1 artifacts exported by `04_export_app_assets.py` into `assets/models/yamnet_mood.json`:
  - the five mood classes (indices 271–275) mapped to the backend's labels
  - per-label log-score means for calibration
  - 61 tag classes collapsing into display tags, at most 3 per song, with no threshold yet
- OD-2 iOS decoder merged in PR #24 (`67c73d0`). `AudioWindowDecoder.swift` reads only three 10 s windows centred at 25/50/75% of the track, downmixes to mono and resamples to 16 kHz with `AVAudioConverter`. The `moodtune/audio_decode` channel returns `Float32List` windows or a typed error (`unreadable`, `empty`, `decode_failed`, `bad_args`); 9 Dart tests cover it.
- OD-3 in progress on `feat/on-device-yamnet` (uncommitted):
  - `flutter_litert` added; model, config and license bundled as assets.
  - `YamnetEngine` frames each window (15,600 samples, 7,680 hop, ~57 frames per track) and runs them all in one `Isolate.run`. It rebuilds the interpreter there from its address, after loading it once lazily, and serialises runs.
  - `YamnetMoodModel.interpret` mirrors the Python `interpret`: calibrated log-scores, then softmax, then the top label; tags take the best peak scores.
  - `OnDeviceMoodClassifier` wraps decode, score and interpret in a 5 s timeout and returns null on any failure. It is registered in GetIt next to `MoodNarrator`.
  - Unit tests plus an integration test that runs the real pipeline on a device against the spike's expected scores (tolerance 0.02 mean, 0.05 peak).

**Decisions**

- **YAMNet over CLAP for the phone.** It is statistically level on accuracy (44% vs 50%, overlapping intervals) at a tenth of the size. It also computes its own spectrogram inside the `.tflite`, so no mel front-end has to be ported.
- **Native code only decodes; everything else is Dart.** Framing, calibration and tags exist once for both platforms and are unit-testable.
- **Three 10 s windows, not the whole file.** This bounds decode and inference cost regardless of track length; it is what the spike evaluated.
- **Mean pooling for mood, peak pooling for tags.** Mood keeps what was evaluated; instruments that play in only part of a song survive peak pooling.
- **Same contract as narration:** an engine interface, one timeout and a null fallback, so the results screen never depends on the model.
- **Hybrid first.** The backend still supplies tempo, energy, brightness and texture rows until OD-6.
- **Show the top label only.** Probabilities are logged, not displayed, until recalibrated (OD-5).

**Roadmap open questions resolved**

- On-device runtime: `flutter_litert` chosen over `tflite_flutter` (pubspec on `feat/on-device-yamnet`). Reasons below, as listed on each package's pub.dev page (checked 2026-10-16); Jordan confirmed them.
  - **Maintenance.** `flutter_litert` 3.9.4 was released days ago. `tflite_flutter` 0.12.1 is about 11 months old.
  - **Simulator.** `tflite_flutter` warns that inference may not work in the iOS simulator. The device integration test should run on simulators too.
  - **Release IPAs.** `tflite_flutter` has a known "symbol not found" IPA failure unless Xcode's strip style is changed, and the app now builds IPAs locally (`tool/build_ipa.sh`).
  - **Packaging.** `flutter_litert` bundles its native libraries, including through Swift Package Manager, which the iOS build already uses.
  - **Low switching cost.** `flutter_litert` forked `tflite_flutter` and kept the `Interpreter` API (`fromAsset`, `fromAddress`, `run`), so going back is mostly an import change.
  - **Accepted risk:** a single community maintainer instead of the TensorFlow org.
- Tag allowlist scope: instruments, vocals collapsed to one tag, and a few reliable genres (decided 2026-10-16).

**Measurements**

- macOS decoder parity (PR #24): 20/20 mood labels; correlation 0.97–1.00 per window; worst class-score difference 0.005; ~200 ms to decode a 4.5 min stereo MP3 on an M4 Pro.
- YAMNet ~0.5 ms per frame on an M4 Pro CPU (spike). **No phone numbers yet.**

**Blockers / risks found**

- Android has no decoder and no platform resampler (biggest unknown).
- Ogg decoding on the oldest supported iOS is unconfirmed; unsupported files fall back to the backend.
- Accuracy ceiling: 44% is wrong about half the time; `serene` vs `reflective` is the hard pair for every engine.
- Calibration constants come from Jamendo, which may not match real uploads.
- Neither runtime's pub.dev page mentions Google Play's 16 KB page-size requirement. Check `flutter_litert`'s Android libraries in a built APK once the Android decoder exists (OD-2, OD-3).

**Mistakes, bugs and lessons learned**

- **Invalid window specs crashed the decoder** (PR #24).
  - **How it was found:** cubic review.
  - **Root cause:** non-finite or negative sample rates and window lengths reached native code unchecked.
  - **Fix:** Swift validates before opening the file, Dart mirrors the checks, and both return `bad_args` (#24).
  - **Lesson:** validate inputs on both sides of a platform channel.
- **Softmax overconfidence.**
  - **What went wrong:** a synthetic chord with no mood came out "angry" at 95%.
  - **How it was found:** recorded in the ROADMAP OD-5 note, on a synthetic chord input. Which run surfaced it isn't recorded.
  - **Root cause:** calibrated log-scores pushed through an untempered softmax.
  - **Fix:** not fixed yet. Probabilities are hidden for now, and a temperature fit is planned for OD-5.
  - **Lesson:** don't show a model's probability before checking it against real outcomes.
- Spike lessons: label bias, small test sets, per-bucket summing, broken temperatures, and pooling for tags. See the lessons list above.

**Next step**

Commit OD-3 on `feat/on-device-yamnet`, then run `integration_test/yamnet_device_test.dart` on a real iPhone and record decode, inference and total time. Those are the first phone numbers, needed before OD-4's p95 < 1 s gate means anything.
