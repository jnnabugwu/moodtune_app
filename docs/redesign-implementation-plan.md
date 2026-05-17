# MoodTune — Full Redesign Implementation Plan

**Based on:** `docs/moodtune-ux-spec.md` (v1.2) + MoodTune Wireframes v2.html  
**Source of truth:** UX spec §1–9 + Appendix A  
**Date:** 2026-05-14

---

## Branch Strategy

Each part lives on its own branch off `main`. Merge each part before starting the next — this keeps PRs reviewable and rollbacks safe.

| Part | Branch name | Base branch |
|------|-------------|-------------|
| Part 1 | `feat/redesign-p1-backend-domain` | `main` |
| Part 2 | `feat/redesign-p2-design-system` | `main` |
| Part 3 | `feat/redesign-p3-guest-auth-upload` | `feat/redesign-p2-design-system` |
| Part 4 | `feat/redesign-p4-loading-results-home` | `feat/redesign-p3-guest-auth-upload` |

> **Note:** Parts 1 and 2 can be worked in parallel (they don't depend on each other). Part 3 depends on Part 2. Part 4 depends on Parts 1, 2, and 3.

---

## Context

The app's current UI is functional scaffolding (plain Cupertino widgets, no mood design system, no design intent). The wireframes v2 define a complete redesign: 11+ screens, 4 mood identities, animated loading states, Jamendo catalog integration, History screen, and auth flows (email verification, forgot password). The backend (FastAPI + Supabase) mostly exists but needs domain entity updates and a new Catalog (Jamendo) data layer.

**No architectural refactoring.** BLoC/GetIt/GoRouter/Cupertino stack stays. Focus is UI/UX implementation + Jamendo feature + History feature.

---

## ⛔ BREAK — Before Part 1

**You (Jordan) need to create the branch manually:**

```bash
git checkout main
git pull origin main
git checkout -b feat/redesign-p1-backend-domain
```

Then give Claude the go-ahead to start Part 1.

---

## Part 1 — Backend: Domain + Data Layer Updates

**Goal:** Extend entities, models, and data sources so the UI has everything it needs. No new infrastructure — just filling gaps.

### 1.1 Update domain entities for upload analysis

**File:** `lib/features/analysis/domain/entities/audio_upload_analysis.dart`

Add to `UploadMoodResult`:
```dart
final List<String> descriptors;   // ["upbeat", "danceable", "bright"] — from backend
final String reasoning;            // "Fast tempo and high harmonic ratio suggest…"
```

Add to `UploadAudioFeatures` (or separate helper model):
```dart
final String energyLabel;          // "High (0.84)" — pre-formatted by backend
final String brightnessLabel;      // "Bright"
final String textureLabel;         // "Smooth"
```

Verify with FastAPI response shape. If backend already returns these, just update the model. If not, note as [BACKEND TODO] — backend must add them.

**File:** `lib/features/analysis/data/models/` — update the upload analysis model to parse new fields.

Also add: `jamendoTrackUrl` (nullable String) to `AudioUploadAnalysis` so catalog results can carry the Jamendo attribution link through to the Results screen.

### 1.2 Add Jamendo Catalog feature (new)

Create `lib/features/catalog/` with Clean Architecture structure:

**Domain:**
- `lib/features/catalog/domain/entities/jamendo_track.dart`
  ```dart
  class JamendoTrack {
    final String id;
    final String name;
    final String artistName;
    final String albumImageUrl;     // 48×48 thumbnail URL
    final Duration duration;
    final List<String> tags;        // up to 2 shown in UI
    final String audioUrl;          // for backend to stream
    final String jamendoPageUrl;    // for attribution link
    final bool audiodownloadAllowed;
  }
  ```
- `lib/features/catalog/domain/repositories/catalog_repository.dart`
  ```dart
  abstract class CatalogRepository {
    Future<Either<Failure, List<JamendoTrack>>> searchTracks({
      String? query,
      String? moodTag,
    });
  }
  ```
- `lib/features/catalog/domain/usecases/search_catalog.dart` — wraps repo, filters `audiodownloadAllowed: false`

**Data:**
- `lib/features/catalog/data/models/jamendo_track_model.dart` — fromJson
- `lib/features/catalog/data/datasources/jamendo_remote_datasource.dart`
  - Calls Jamendo API v3: `GET https://api.jamendo.com/v3.0/tracks/?client_id=…&namesearch={query}&tags={moodTag}&limit=20&audiodownload=on`
  - Client ID injected via env var `JAMENDO_CLIENT_ID` (add to `.env.example`)
- `lib/features/catalog/data/repositories/catalog_repository_impl.dart`

**State:**
- `lib/features/catalog/presentation/bloc/catalog_bloc.dart`
  - Events: `CatalogSearchRequested({String? query, String? moodTag})`, `CatalogCleared`
  - States: `CatalogInitial`, `CatalogLoading`, `CatalogLoaded(List<JamendoTrack>)`, `CatalogError`
  - Debounce: 300ms on search events

**DI:** Register in `lib/di/injector.dart`

### 1.3 History — verify and extend

The `AnalysisBloc` already has `AnalysisHistoryRequested`. Check:
- Does the repo method paginate or cap at 50? If not, add `limit: 50` param.
- Does the returned list include the mood label and confidence in a format the History screen can display without re-fetching?
- Add `moodFilter` param to `AnalysisHistoryRequested` so mood chip filtering works client-side (filter in-memory from loaded 50 items — no extra API call needed).

**File:** `lib/features/analysis/presentation/bloc/analysis_bloc.dart` — add `AnalysisHistoryFilterChanged(String? mood)` event; filter the currently loaded `history` list in state.

### 1.4 Auth — Email Verification + Forgot Password

**Email verification** — uses Supabase email confirm flow. No new data source needed:
- On sign-up success, navigate to `/email-verify` and pass the email address.
- Listen for `AuthChangeEvent.userUpdated` / `confirmed` in `AuthBloc` → navigate to `/home`.
- Resend: call `supabase.auth.resend(type: OtpType.signup, email: email)`.

**Forgot password:**
- Call `supabase.auth.resetPasswordForEmail(email)`.
- Handle `AuthChangeEvent.passwordRecovery` in `AuthBloc` → navigate to `/reset-password` (stub page, out of scope this pass — log an issue).

**Files:** `lib/features/auth/presentation/bloc/auth_bloc.dart` — add events `ResendVerificationRequested`, `ForgotPasswordRequested(email)`.

### 1.5 Route additions

**File:** `lib/core/routing/route_names.dart` — add:
```dart
static const landing      = '/';
static const signIn       = '/sign-in';
static const emailVerify  = '/email-verify';
static const forgotPw     = '/forgot-password';
static const homeAuth     = '/home';
static const history      = '/history';
static const catalog      = '/catalog';
static const analysisLoad = '/analysis/loading';
static const result       = '/analysis/result';
```

**File:** `lib/core/routing/app_router.dart` — add routes for all new pages; keep existing Spotify routes for backward compat but set `initialLocation` to `/` with auth guard redirect logic: if session active → `/home`, else → `/`.

---

## ⛔ BREAK — Before Part 2

**You (Jordan) need to:**
1. Review / merge the Part 1 PR on GitHub
2. Create the Part 2 branch:

```bash
git checkout main
git pull origin main
git checkout -b feat/redesign-p2-design-system
```

Then give Claude the go-ahead to start Part 2.

---

## Part 2 — Frontend: Design System & Shared Widgets

**Goal:** Build all reusable components before touching individual screens. Everything in Part 3 and 4 imports from here.

### 2.1 MoodTheme

**File:** `lib/app/theme/mood_theme.dart`

```dart
enum MoodIdentity { upbeat, serene, charged, reflective }

class MoodTheme {
  static MoodColors colorsFor(MoodIdentity mood) { ... }
  static IconData iconFor(MoodIdentity mood) { ... }
  static String quadrantLabel(MoodIdentity mood) { ... }   // "Happy & Energetic"
  static String shortLabel(MoodIdentity mood) { ... }      // "UPBEAT"

  /// Maps primaryMood string from backend → MoodIdentity
  static MoodIdentity fromString(String mood) { ... }
}

class MoodColors {
  final Color background;    // hero card gradient start
  final Color backgroundEnd; // hero card gradient end
  final Color text;          // label color on hero
  final Color accent;        // ring, pill buttons, tags
  final Color tagBackground; // pill bg at ~15% opacity
}
```

**Four palettes:**

| Mood | Background | Accent |
|------|-----------|--------|
| Upbeat | Warm amber #F5A623 → orange #E8721A | #E8721A |
| Serene | Soft teal #4ECDC4 → warm white #A8E6CF | #2BAF9A |
| Charged | Deep purple #2D1B69 → electric red #C0392B | #C0392B |
| Reflective | Cool slate #4A6FA5 → dark blue-grey #2C3E50 | #4A6FA5 |

All palettes must pass WCAG AA on their own background.

### 2.2 Shared Widgets

Create `lib/shared/widgets/` — imported by all features.

**`confidence_ring.dart`** — `ConfidenceRing({required double value, required Color color})`
- CustomPainter donut ring, animates 0→value on first build (400ms ease-out)
- Percentage counter inside ring (TweenAnimationBuilder, integer steps)
- Below ring: "Strong match" / "Good match" / "Possible match" text label
- Respects `MediaQuery.of(context).disableAnimations`

**`mood_hero_card.dart`** — `MoodHeroCard({required AudioUploadAnalysis analysis})`
- Full-width gradient container using `MoodTheme.colorsFor()`
- Mood illustration/icon (from `MoodTheme.iconFor()`), primary label, quadrant name, `ConfidenceRing`
- Reveal animation: stagger in elements per spec §5.3

**`mood_descriptor_tags.dart`** — `MoodDescriptorTags({required List<String> tags, required Color accentColor})`
- Horizontal `Wrap`, pill shapes, `accentColor` at 15% opacity background, full opacity text
- Not tappable in MVP

**`history_row_item.dart`** — `HistoryRowItem({required HistoryAnalysis item, required VoidCallback onTap})`
- Mood chip (filled pill, mood accent color), title (truncated 24 chars), confidence %, date
- Tappable row

**`animated_waveform.dart`** — `AnimatedWaveform({required Color color})`
- 7 vertical bars, staggered pulse animation (varying speed/height per bar)
- Stops when `isAnimating: false` (for reduced motion)

**`collapsible_section.dart`** — `CollapsibleSection({required String title, required Widget child})`
- Chevron-right header row, smooth height animation 200ms ease-out, chevron rotates 180°

**`bottom_sheet_base.dart`** — `MoodTuneBottomSheet({required Widget child, ...})`
- Drag handle, standard padding, modal presentation helper

**`mood_chip.dart`** — `MoodChip({required String label, required MoodIdentity mood, bool isSelected})`
- Filter chip with mood accent color when selected, outlined when not

**`error_banner.dart`** — `ErrorBanner({required String message})` — red-tinted inline banner

**`sign_up_strip.dart`** — `SignUpStrip({required VoidCallback onSignUp})` — persistent 60dp bottom strip, "Save this & see your history" + pill Sign Up button

---

## ⛔ BREAK — Before Part 3

**You (Jordan) need to:**
1. Review / merge the Part 2 PR on GitHub
2. Create the Part 3 branch **off Part 2** (or off main if Part 2 is already merged):

```bash
# If Part 2 is merged into main:
git checkout main && git pull origin main
git checkout -b feat/redesign-p3-guest-auth-upload

# If Part 2 is NOT yet merged (working in sequence):
git checkout feat/redesign-p2-design-system
git checkout -b feat/redesign-p3-guest-auth-upload
```

Then give Claude the go-ahead to start Part 3.

---

## Part 3 — Frontend: Guest, Auth & Upload Screens

**Goal:** Implement the lefthand flows (Rows A + B of wireframes). All use Part 2 components.

### 3.1 Landing / Guest Home — redesign `GuestPage`

**File:** `lib/features/analysis/presentation/view/guest_page.dart`

Replace entirely. No nav bar. Centered content column:
1. MoodTune wordmark (large display text + subtle waveform icon)
2. Hero graphic (abstract waveform or four-quadrant placeholder — use a placeholder `Container` with mood accent gradient until designer provides asset)
3. Headline: "Drop a song.\nFind its mood." (two separate `Text` lines)
4. Subhead: "Upload any audio file and we read its energy, rhythm, and feel — instantly."
5. Primary CTA: "Try it — upload now" → `context.push(RouteNames.uploadMusic)`
6. Ghost CTA: "Browse the catalog" → `context.push(RouteNames.catalog)`
7. Text link: "Sign in" → `context.push(RouteNames.signIn)`
8. Offline banner: Listen to connectivity → show `ErrorBanner` below CTAs when offline

### 3.2 Sign In / Sign Up — merge `AuthPage` + `SignupPage`

**File:** `lib/features/auth/presentation/view/sign_in_page.dart` (new unified file)

- Toggle tabs ("Sign in" / "Sign up") using `TabBar` with underline indicator — no navigation on toggle, just `setState`
- Email + Password fields (cupertino text fields)
- Confirm Password field — `AnimatedSize` to appear only in Sign Up mode
- Primary button ("Sign in" / "Sign up") → dispatches `LoginRequested` or `SignupRequested`
- "or" divider
- Google OAuth button → `url_launcher` (placeholder if not yet wired)
- Apple OAuth button → same
- "Forgot password?" text link (Sign In mode only) → `context.push(RouteNames.forgotPw)`
- Error: inline `ErrorBanner` below CTA
- Success: `AuthBloc` state change → if signed up → push `/email-verify`; if signed in → push `/home`

Update `app_router.dart`: map `/sign-in` to new page; mark old `/login` and `/signup` as redirects.

### 3.3 Email Verification — new screen

**File:** `lib/features/auth/presentation/view/email_verify_page.dart`

- No back button (replace with "Wrong email? Go back" link at bottom)
- Envelope icon (✉ in a large rounded box)
- Heading: "Check your inbox"
- Body: "We sent a link to **{email}**. Tap it to confirm your account."
- "Resend email" link — `ResendVerificationRequested` event → 60s cooldown timer (`Timer.periodic`)
- "Wrong email? Go back" → `context.pop()`
- Listen to `AuthBloc` for `userUpdated` / confirmed state → navigate to `/home` with "You're in!" `ScaffoldMessenger` snackbar

### 3.4 Forgot Password — new screen

**File:** `lib/features/auth/presentation/view/forgot_password_page.dart`

Two states managed locally (`bool _sent`):

**Default state:**
- Back button → sign in
- Heading: "Reset your password"
- Body: "Enter your email and we'll send you a link to reset it."
- Email field (pre-filled from router `extra` if passed from sign-in)
- "Send reset link" button → `ForgotPasswordRequested` → flips to `_sent = true`

**Sent state:**
- Envelope icon
- Heading: "Link sent"
- Body: "Check your email for a reset link. It expires in 1 hour."
- "Resend" link (60s cooldown, same pattern as email verify)
- "Back to sign in" link → `context.go(RouteNames.signIn)`

### 3.5 Upload Screen — redesign `UploadMusicPage`

**File:** `lib/features/analysis/presentation/view/upload_music_page.dart`

State (local `StatefulWidget`):
- `PlatformFile? _selectedFile`
- `bool _metadataExpanded = false`
- `String? _title, _artist, _album`
- `FileError? _fileError` (enum: none / tooLarge / wrongFormat)

**Layout:**
1. Nav bar: "← Back" + "Upload Music"
2. Section heading: "Choose a file to listen to" + format/size hint row
3. Upload drop zone card (dashed border, 30–35% screen height):
   - **Empty:** ♪ icon, "Tap to choose a file" → `FilePicker.platform.pickFiles(...)`
   - **Selected:** ✓ + ♪ icon, filename, "X.X MB · M:SS", duration estimate ("Analysis takes ~30 secs"), "Change file" link
   - **Error (too large):** red-tinted border, `!` icon, error message, "Choose a different file" link
4. "Add song details ▾" collapsible (`CollapsibleSection`): Title / Artist / Album text fields
5. Spacer
6. "Analyze song" button — disabled until valid file selected; on tap → show `ConsentBottomSheet`

**Duration estimate logic** (`_estimateAnalysisTime(double durationSeconds)`):
```dart
if (duration < 180) return "~15 secs";
if (duration < 300) return "~30 secs";
if (duration < 480) return "~45 secs";
return "about a minute";
```
Use `audio_metadata_reader` or `just_audio` to read metadata before upload. Add package to `pubspec.yaml` if not present.

**File validation** (client-side, before consent):
- Size > 15 MB → `_fileError = FileError.tooLarge`
- Extension not in `{mp3, m4a, flac, wav, ogg}` → `_fileError = FileError.wrongFormat`

**Consent bottom sheet** (`ConsentBottomSheet`) — shown via `showCupertinoModalPopup`:
- Drag handle, "One quick thing" heading, body copy per spec §3.3
- "Yes, let's hear it" → dismiss + dispatch `AudioUploadRequested` + push `/analysis/loading`
- "Cancel" → dismiss only (preserves file selection)

---

## ⛔ BREAK — Before Part 4

**You (Jordan) need to:**
1. Review / merge Parts 1, 2, and 3 PRs on GitHub (Part 4 depends on all three)
2. Create the Part 4 branch:

```bash
# If Parts 1–3 are all merged into main:
git checkout main && git pull origin main
git checkout -b feat/redesign-p4-loading-results-home

# If Part 3 is NOT yet merged:
git checkout feat/redesign-p3-guest-auth-upload
git checkout -b feat/redesign-p4-loading-results-home
```

Then give Claude the go-ahead to start Part 4.

---

## Part 4 — Frontend: Loading, Results, Authenticated Home, History & Catalog

**Goal:** Implement the right-hand flows (Rows C–F of wireframes). The hero screens.

### 4.1 Analysis Loading Screen — redesign `SongAnalyzingPage` / `AnalyzingPage`

**File:** `lib/features/analysis/presentation/view/analysis_loading_page.dart` (new unified name)

Parameters: `AnalysisSource` enum (upload / catalog), inherits file/track context via BLoC state.

**UI structure:**
1. Top-right "Cancel" text button → `context.go(RouteNames.uploadMusic)` (or catalog, based on source)
2. Vertically centered `AnimatedWaveform` (7 bars, pulsing) — 200px height
3. Phase message (cross-fades every ~5s using `AnimatedSwitcher` with 400ms fade)
4. Step dots (6 dots: filled=done, solid=active, outline=pending) — `_currentPhase` tracked via `Timer`
5. At ~28s: blur reveal layer appears behind waveform using `BackdropFilter` (20px Gaussian) over a `Positioned` ghost result card with mood gradient color bleed-through

**6-phase messages** (upload flow):
```
Phase 1: "Uploading your track…"     (catalog: "Fetching the track…")
Phase 2: "Listening to the rhythm…"
Phase 3: "Reading the energy…"
Phase 4: "Feeling the texture…"
Phase 5: "Finding the mood…"
Phase 6: "Almost there…"
```

**Timeout (>35s):** Cancel timer, replace animation with `⚠` icon + "This one's taking longer than usual. Give it another try." + [Try again] [Cancel] buttons.

**Error states:** Listen to `AnalysisBloc` for `AnalysisError`:
- Generic failure: `×` icon + "Something went wrong. It's not your file — try again."
- Offline: `⚡` icon + "Looks like you went offline."
- Rate limit: `⏱` icon + "You've done a lot of listening today." — only "OK" button (no retry)

**On success:** `AnalysisBloc` → `AnalysisSuccess` → push `/analysis/result` with `AudioUploadAnalysis` as extra.

### 4.2 Results Screen — unified redesign

**File:** `lib/features/analysis/presentation/view/results_page.dart` (replaces `SongResultPage` + `AnalysisResultPage`)

Parameters: `AudioUploadAnalysis analysis`, `bool isAuthenticated`, `bool isCatalogSource`.

**Layout (scrollable, `CustomScrollView` with `SliverList`):**
1. Nav bar: "← Back" + "Song Analysis"
2. `MoodHeroCard` — full-width, animated reveal on first frame (see §5.3 of spec)
3. `MoodDescriptorTags` — `analysis.mood.descriptors`
4. Reasoning text — `analysis.mood.reasoning`
5. `CollapsibleSection("Audio details")`:
   - Tempo: `${tempo.toStringAsFixed(0)} BPM`
   - Energy: `analysis.mood.audioFeatures.energyLabel`
   - Brightness: `analysis.mood.audioFeatures.brightnessLabel`
   - Texture: `analysis.mood.audioFeatures.textureLabel`
6. "Analyze another song" ghost button → `context.go(RouteNames.uploadMusic)`
7. (If catalog source): Jamendo attribution row — "[Artist Name] on Jamendo ↗" + "Via Jamendo Free Music", `url_launcher` tap → Jamendo track page

**Guest variant:** `SignUpStrip` pinned below `SafeArea` bottom — "Save this & see your history" + "Sign up" pill button.

**Authenticated variant:** "Saved to your history." toast via `ScaffoldMessenger.showSnackBar` ~800ms after screen loads.

**Reveal animation sequence** (`TickerProvider`, single `AnimationController`):
- T+0ms: mood hero bg fades in
- T+200ms: illustration/icon fades in
- T+300ms: label slides up from +12px
- T+400ms: quadrant name fades
- T+500ms: confidence ring draws to value
- T+700ms: descriptor tags stagger in (50ms each)
- T+850ms: reasoning fades in
- T+950ms: sign-up strip slides up (guest only)

### 4.3 Authenticated Home — new screen

**File:** `lib/features/analysis/presentation/view/home_auth_page.dart`

Uses a `CupertinoTabScaffold` (Home + History tabs) or `Scaffold` with bottom `BottomNavigationBar`.

**Home tab content:**
1. Nav bar: "MoodTune" wordmark left, avatar/initials right (taps to sign-out action sheet)
2. Upload card (full-width, prominent, light gradient bg, music note icon, "Analyze a new song", "Tap to upload a file") → tap → `context.push(RouteNames.uploadMusic)`
3. Catalog card (secondary, smaller, grid icon, "Browse the catalog", "Explore free music") → tap → `context.push(RouteNames.catalog)`
4. "Recent analyses" section label
5. `ListView` of up to 3 `HistoryRowItem` from `AnalysisBloc` history state — dispatch `AnalysisHistoryRequested` on init
6. "See all history →" text link → switch to History tab
7. **Empty state**: replace items 5+6 with "Your past analyses will appear here." + "Analyze your first song →" ghost button

On mount: dispatch `AnalysisHistoryRequested`.

### 4.4 History Screen — new screen

**File:** `lib/features/analysis/presentation/view/history_page.dart`

**Layout:**
1. Nav bar: "← Back" + "My History"
2. Horizontal scrollable mood filter chips ("All · Upbeat · Serene · Charged · Reflective") — `_selectedMood` local state → dispatches `AnalysisHistoryFilterChanged(mood)`
3. `ListView` of `HistoryRowItem` widgets from filtered history state
4. At bottom (if cap reached): "Showing your 50 most recent analyses." muted footnote
5. **Empty state**: waveform illustration placeholder + "Nothing here yet." + "Analyze a song" primary button

### 4.5 Catalog Search Screen — new screen

**File:** `lib/features/catalog/presentation/view/catalog_search_page.dart`

**Layout:**
1. Nav bar: "← Back" + "Browse Catalog"
2. Search field (full-width, `CupertinoSearchTextField`, autofocused, debounced 300ms → `CatalogSearchRequested`)
3. Horizontal scrollable mood chip row ("All · Upbeat · Serene · Charged · Reflective") — combines with search
4. **Pre-search / empty state:** "Search for a track or pick a mood to explore." muted text centered
5. **Loading state (shimmer):** `ListView` of placeholder shimmer cards (3 visible)
6. **Results:** `ListView` of `CatalogTrackCard`
7. **No results:** "No tracks found for '[query]'.\nTry different keywords or clear the mood filter."
8. **API error:** "Couldn't reach the catalog right now." + "Try again" link

**`CatalogTrackCard` widget** (`lib/features/catalog/presentation/widgets/catalog_track_card.dart`):
- 48×48 album art thumbnail (`CachedNetworkImage` or `Image.network`, music note placeholder)
- Track name (1 line, ellipsis at 28 chars)
- "Artist Name · M:SS" subtitle
- Up to 2 tag pills (muted)
- "Analyze →" filled pill button → show `CatalogConfirmSheet`
- Row height ~72–80px

### 4.6 Catalog Confirm Bottom Sheet

**File:** `lib/features/catalog/presentation/widgets/catalog_confirm_sheet.dart`

Shown via `showCupertinoModalPopup` from `CatalogTrackCard` tap.

- Drag handle
- 64×64 album art
- Track name + "Artist · M:SS"
- Body: "We'll analyze the mood of this track from Jamendo's free music library."
- "Analyze this track" primary button → dismiss + dispatch `AnalyzeSongRequested` (with Jamendo track ID) + push `/analysis/loading` with `source: AnalysisSource.catalog`
- "Cancel" text link → dismiss only

---

## Verification Plan

### Part 1 (Backend)
- [ ] Run app with upload flow; confirm `descriptors`, `reasoning`, `energyLabel`, `brightnessLabel`, `textureLabel` fields populated in `AudioUploadAnalysis` from API response
- [ ] Confirm `AnalysisHistoryRequested` returns ≤50 items from Supabase
- [ ] Test `CatalogRepository.searchTracks(query: "piano")` returns valid `JamendoTrack` list with `audiodownloadAllowed: true`
- [ ] Auth: sign up → email arrives → deep link → app navigates to `/home`
- [ ] Auth: forgot password → email arrives → `passwordRecovery` event fires

### Part 2 (Design System)
- [ ] Render each `MoodTheme` palette variant visually (create a dev route `/debug/theme` that shows all 4 mood cards)
- [ ] `ConfidenceRing` animates from 0→value on mount; respects `disableAnimations`
- [ ] `AnimatedWaveform` pulses; stops cleanly when `isAnimating: false`

### Part 3 (Guest + Auth + Upload)
- [ ] Guest Landing: "Try it" → Upload, "Browse catalog" → Catalog, "Sign in" → Auth. Offline banner appears when disconnected.
- [ ] Sign In / Sign Up: toggle switches mode without navigation; error shown inline; success navigates correctly
- [ ] Email Verify: Resend has 60s cooldown; deep link returns user to `/home`
- [ ] Upload: file too large → red error state; wrong format → error state; valid file → Analyze enabled → Consent sheet appears; consent → loading screen
- [ ] Duration estimate shows correct bucket

### Part 4 (Loading, Results, Home, History, Catalog)
- [ ] Loading screen cycles through 6 phases with cross-fade; step dots advance; at ~28s blur layer appears; at 35s timeout state shows
- [ ] Results screen: all 4 moods render correct palettes; confidence ring animates; audio details expand/collapse with chevron rotation; guest strip pinned bottom; auth "Saved" toast appears 800ms post-load and auto-dismisses; Jamendo attribution shows only for catalog source
- [ ] Home (Auth): upload card and catalog card navigate correctly; recent history shows 3 items; empty state shows when no history
- [ ] History: mood chip filter works in-memory; 50-cap footnote shows; empty state correct
- [ ] Catalog: debounced search returns results; shimmer shows during load; no-results state; track card tap opens confirm sheet; confirm → loading screen → results with Jamendo attribution

---

## Critical Files

| File | Action |
|------|--------|
| `lib/features/analysis/domain/entities/audio_upload_analysis.dart` | Add `descriptors`, `reasoning`, `energyLabel`, `brightnessLabel`, `textureLabel`, `jamendoTrackUrl` |
| `lib/features/catalog/` | Create entire feature folder |
| `lib/features/catalog/presentation/bloc/catalog_bloc.dart` | New BLoC |
| `lib/di/injector.dart` | Register `CatalogRepository`, `CatalogBloc` |
| `lib/core/routing/app_router.dart` | Add 8+ new routes |
| `lib/core/routing/route_names.dart` | Add new route constants |
| `lib/app/theme/mood_theme.dart` | New — 4 mood palettes |
| `lib/shared/widgets/` | New folder — 8 shared widgets |
| `lib/features/analysis/presentation/view/guest_page.dart` | Full rewrite |
| `lib/features/auth/presentation/view/sign_in_page.dart` | New unified auth screen |
| `lib/features/auth/presentation/view/email_verify_page.dart` | New |
| `lib/features/auth/presentation/view/forgot_password_page.dart` | New |
| `lib/features/analysis/presentation/view/upload_music_page.dart` | Major rewrite |
| `lib/features/analysis/presentation/view/analysis_loading_page.dart` | New unified loading |
| `lib/features/analysis/presentation/view/results_page.dart` | New unified results |
| `lib/features/analysis/presentation/view/home_auth_page.dart` | New |
| `lib/features/analysis/presentation/view/history_page.dart` | New |
| `lib/features/catalog/presentation/view/catalog_search_page.dart` | New |
| `lib/features/catalog/presentation/widgets/catalog_track_card.dart` | New |
| `lib/features/catalog/presentation/widgets/catalog_confirm_sheet.dart` | New |

---

## Key Reuse Notes

- **Existing BLoC infrastructure:** `AnalysisBloc`, `AuthBloc` — extend events, do not replace.
- **GoRouter:** Existing `AppRouter` class — add routes, adjust `initialLocation` logic.
- **GetIt DI:** Existing `injector.dart` — add registrations for catalog feature.
- **Supabase auth:** `supabase.auth.resend()` for verify resend; `supabase.auth.resetPasswordForEmail()` for forgot password — no new data source.
- **`file_picker`:** Already in pubspec. Use for upload zone.
- **`url_launcher`:** Already in pubspec. Use for Jamendo attribution links.
- Add: `audio_metadata_reader` or `just_audio` (choose one) for duration extraction from file metadata.
- Add: `cached_network_image` if not already present for Jamendo album art thumbnails.
