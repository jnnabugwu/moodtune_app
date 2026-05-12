# MoodTune — UX Design Specification

**Version:** 1.2  
**Date:** 2026-05-11  
**Author:** Product (for designer handoff)  
**Status:** Ready for Figma

---

## Overview

MoodTune is a mobile app (Flutter, iOS + Android) that lets anyone upload a song and immediately discover its mood. The analysis reads audio features — tempo, energy, brightness, texture — and returns a primary mood label, confidence score, mood descriptors, and a plain-language explanation of what the music is doing.

The product has two user states: **Guest** (no account, full analysis, no save) and **Authenticated** (full analysis + auto-saved history). The guest experience is the primary conversion hook. Every design decision should serve delight-before-friction.

---

## 1. Design Principles

### 1.1 Delight before friction
The first thing a user does is get a result. No account wall. No onboarding slides. No "rate this app." Every screen between opening the app and seeing a mood result should feel effortless. Friction — consent copy, error messages — must be written with warmth, not legalese.

### 1.2 Mood first, data second
The primary mood label (e.g. "Upbeat") is the hero of the Results screen. Confidence, descriptors, reasoning, and audio stats are supporting cast — important, but visually subordinate. A user should be able to read the result in under two seconds without scrolling.

### 1.3 The app listens, not calculates
The product voice is curious and musical, not technical. Visually: favor warm gradients, fluid animations, and organic shapes (not dashboards with grids and bar charts). The experience should feel closer to album artwork than a data tool. The loading state, in particular, should feel like the app is genuinely paying attention.

### 1.4 Every mood has a personality
Each of the four mood quadrants has a distinct visual identity — a color palette, an icon or illustration character, and a feel. This is not cosmetic variation; it is the product's core delight mechanism. The moment the result reveals, the entire screen "becomes" that mood. The designer should define these identities; this spec calls them out as four named design targets.

### 1.5 Convert through quality, not coercion
The sign-up prompt appears exactly once: at the bottom of the Guest Results screen. It is never a modal interrupt, never a blocker, never repeated mid-session. The copy explains the benefit ("save this + track history"), not the product's need for an account. If a guest ignores it, that's fine.

---

## 2. Navigation Structure

### 2.1 Guest navigation

```
App Launch
    │
    ▼
[Landing / Home — Guest]
    │
    ├──► [Sign In / Sign Up Screen]
    │           │
    │           └──► [Home — Authenticated]  (on success)
    │
    ├──► [Upload Screen]           ← existing upload path
    │         │
    │    [Consent Modal] → [Analysis Loading State] → [Results Screen — Guest]
    │
    └──► [Catalog Search Screen]   ← NEW
              │
              └──► [Catalog Track Detail / Confirm]  ← NEW
                        │
                   [Analysis Loading State]  (same screen, different copy — see §9)
                        │
                   [Results Screen — Guest]
```

### 2.2 Authenticated navigation

```
App Launch (authenticated session)
    │
    ▼
[Home — Authenticated]
    │
    ├──► [Upload Screen]  (same as guest upload flow)
    │         │
    │         ▼
    │    [Consent Modal]
    │         │
    │    [Analysis Loading State]
    │         │
    │         ▼
    │    [Results Screen — Authenticated]
    │         │
    │         └──► [Upload Screen]  ("Analyze another song")
    │
    ├──► [Catalog Search Screen]   ← NEW (same catalog flow as guest)
    │         │
    │         └──► [Catalog Track Detail / Confirm]
    │                   │
    │              [Analysis Loading State]
    │                   │
    │              [Results Screen — Authenticated]
    │
    └──► [History Screen]  (tab or nav link from Home)
              │
              └──► [Results Screen — Authenticated]  (tap any history item)
```

### 2.3 Tab bar / navigation model

[ASSUME] Bottom navigation bar with two tabs for authenticated users: **Home** (upload + recent history) and **History** (full list). Guest users see no tab bar — they navigate linearly through the upload flow.

[VERIFY] Whether to use a tab bar or a single-page Home with a "See all" history link. A tab bar adds scaffolding complexity; a single-page Home with a "See all history" link may be lighter for MVP.

**Note on Catalog integration:** The Catalog Search Screen replaces the file picker step for the catalog path. Everything from the Analysis Loading State onward (Loading State, Results Screen, error handling) is shared between the upload flow and the catalog flow. The only differences are the Loading State copy (§9.5) and a small attribution line on the Results Screen (§9.6).

---

## 3. Screen Specs — Guest Flow

---

### 3.1 Landing / Home (Guest)

**Purpose:** First impression. Communicate the value proposition in under five seconds and give the user an unmistakable path to try the feature.

**Layout:**

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│         [App wordmark]          │  ← "MoodTune" — large, centered
│                                 │
│      [Illustrative graphic]     │  ← Mood quadrant illustration or abstract
│      (waveform / vinyl / icon)  │    waveform graphic. NOT a photo.
│                                 │
│    "Drop a song.              │
│     Find its mood."             │  ← Headline. Large type.
│                                 │
│  "Upload any audio file and we  │
│   read its energy, rhythm, and  │
│   feel — instantly."            │  ← Subhead. 2 lines max. Relaxed tone.
│                                 │
│  ┌───────────────────────────┐  │
│  │     Try it — upload now   │  │  ← Primary CTA. Filled. Full-width.
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │     Browse the catalog    │  │  ← Secondary CTA. Ghost/outlined. Full-width.
│  └───────────────────────────┘  │
│                                 │
│           Sign in               │  ← Tertiary CTA. Text link only.
│                                 │
└─────────────────────────────────┘
```

**Key UI elements:**

- **App wordmark:** "MoodTune" in display type. Consider a subtle musical motif (a small note, a waveform) adjacent to the word — not a literal logo lockup, more like a typographic accent.
- **Illustration / graphic:** The hero visual sets the tone for the whole product. It should feel warm and musical. [ASSUME] An abstract, stylized waveform or a four-quadrant graphic that hints at the mood system without explaining it. The designer should define this visual language; it will be reused on the Results screen.
- **Headline:** "Drop a song. Find its mood." — short, punchy, instructional. Two sentences on separate lines feels rhythmically better than one.
- **Primary CTA:** "Try it — upload now." Full-width, filled, visually dominant. This is the only button that needs to feel exciting.
- **Secondary CTA:** "Browse the catalog." Full-width, ghost/outlined style. Positioned directly below the primary CTA — same width, clearly related, visually subordinate. Navigates to Catalog Search Screen (§9.2).
- **Tertiary CTA:** "Sign in" — text link weight only. Sits below the catalog button. Does not compete with either CTA above it.

**States:**

- **Default (shown above):** No session.
- **No internet:** A small inline banner below the CTA: "No internet connection — analysis requires a connection." CTA remains visible but tapping it shows an inline error rather than navigating.

**Copy direction:**

- Headline should not say "AI" or "analysis." It should describe the experience, not the mechanism.
- The subhead can use "we read" (not "we analyze" or "our algorithm processes").
- Avoid exclamation points in the headline. Let the product confidence speak.

**Interactions:**

- Tap "Try it — upload now" → navigate to Upload Screen (push transition).
- Tap "Browse the catalog" → navigate to Catalog Search Screen (push transition).
- Tap "Sign in" → navigate to Sign In / Sign Up Screen (push transition).
- No swipe-to-dismiss, no modals on this screen.

---

### 3.2 Upload Screen

**Purpose:** Allow the user to select a file. Minimal friction. The only required action is picking a file; everything else is optional.

**Layout:**

```
┌─────────────────────────────────┐
│  ←  Back          Upload Music  │  ← Nav bar. Back goes to Landing.
├─────────────────────────────────┤
│                                 │
│  "Choose a file to listen to"   │  ← Section heading. Relaxed.
│                                 │
│  MP3 · M4A · FLAC · WAV · OGG  │  ← Supported formats. Small, muted.
│  Max file size: 15 MB           │
│                                 │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │   [Music note icon]         ││  ← Upload drop zone / tap target
│  │                             ││
│  │   "Tap to choose a file"    ││  ← Large tap target, dashed border
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  [Add song details ▾]           │  ← Collapsed by default. Tap to expand.
│                                 │
│  ┌───────────────────────────┐  │
│  │       Analyze song        │  │  ← Disabled until file selected
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**After file selected — layout updates:**

```
┌─────────────────────────────────┐
│  ←  Back          Upload Music  │
├─────────────────────────────────┤
│                                 │
│  "Choose a file to listen to"   │
│                                 │
│  ┌─────────────────────────────┐│
│  │  ✓ [Music note icon]        ││  ← Checkmark appears. Border changes
│  │                             ││    color (mood accent or system green).
│  │  track-name.mp3             ││  ← Filename truncated if long
│  │  8.4 MB · 3:47              ││  ← File size + duration (read from metadata)
│  │                             ││
│  │  Analysis takes ~30 secs    ││  ← Estimate based on duration. Muted text.
│  │                             ││
│  │  [Change file]              ││  ← Small text link, bottom right of card
│  └─────────────────────────────┘│
│                                 │
│  [Add song details ▾]           │  ← Collapsed by default. Tap to expand.
│                                 │
│  ┌───────────────────────────┐  │
│  │       Analyze song        │  │  ← Now active / enabled
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Duration estimate logic:**

Audio duration is read from the file's metadata header on-device before upload begins — no API call required. Flutter packages `audio_metadata_reader` or `just_audio` can extract this from the file before it is sent. The app maps duration to a display estimate using the following buckets:

| Song duration | Displayed estimate                  |
| ------------- | ----------------------------------- |
| < 3 min       | "Analysis takes ~15 secs"           |
| 3–5 min       | "Analysis takes ~30 secs"           |
| 5–8 min       | "Analysis takes ~45 secs"           |
| > 8 min       | "Analysis takes about a minute"     |

Copy uses "about" or "~" — never an exact number. This sets expectations before the user commits, reducing surprise during the loading state. If duration cannot be read from metadata (e.g. corrupt headers), omit the estimate line silently rather than showing a fallback.

**Key UI elements:**

- **Upload zone:** A large, tappable card with dashed border. Takes up roughly 30–35% of the screen height in the default state. On tap, it opens the OS file picker. After selection, it transitions to a "file selected" card state — same dimensions, different content.
- **Format + size hint:** Single line of muted text below the heading. Not a disclaimer block. Formats separated by dots, not commas.
- **Optional metadata fields (Title, Artist, Album):** These are optional. They allow users to label results in history more meaningfully. Fields are hidden by default behind an "Add song details ▾" expand toggle. When tapped, the row expands to reveal Title, Artist, and Album fields with a smooth height animation and chevron rotation (same pattern as the audio details collapsible on the Results screen). Each field should be clearly labeled as optional via placeholder text ("Title (optional)") or a small "(optional)" label.
- **Analyze button:** Disabled (visually muted, not interactive) when no file is selected. Becomes full-color and tappable once a file is selected. No file = no button affordance.

**Error states (inline, on this screen):**

- **File too large (>15 MB):** The upload zone updates with a red-tinted error state: "This file is too large. Max size is 15 MB." The Analyze button remains disabled. A "Choose a different file" link replaces "Change file."
- **Unsupported format:** "We can't read this file type. Supported formats: MP3, M4A, FLAC, WAV, OGG." Same visual treatment as file-too-large error.

**Interactions:**

- Tap upload zone → OS file picker opens (system sheet). User picks a file. Sheet closes. Upload zone card transitions to "selected" state.
- Tap "Change file" link → same OS file picker, replaces currently selected file.
- Tap "Analyze song" (active) → Consent Modal appears (bottom sheet, overlays this screen). Upload Screen remains visible behind modal.

---

### 3.3 Consent Modal

**Purpose:** A lightweight, friendly acknowledgment before analysis starts. Not a legal wall. Should take under 5 seconds to read and dismiss.

**Presentation:** Bottom sheet (modal). Slides up from below. Upload Screen visible behind it, darkened overlay. Sheet height: roughly 40–45% of screen height — enough to breathe, not enough to feel heavy.

**Layout:**

```
┌─────────────────────────────────┐
│         ▬▬▬ (drag handle)       │  ← Drag handle, centered
│                                 │
│  "One quick thing"              │  ← Section title. Friendly, not alarming.
│                                 │
│  "By uploading this file,       │
│   you're confirming you own     │
│   it or have the right to       │
│   analyze it. We never store    │
│   or share your audio — we      │
│   just read the mood and        │
│   send it back."                │  ← Body copy. 3–4 lines max. Conversational.
│                                 │
│  ┌───────────────────────────┐  │
│  │  Yes, let's hear it       │  │  ← Primary action. Filled button.
│  └───────────────────────────┘  │
│                                 │
│           Cancel                │  ← Text link or ghost button. Below primary.
│                                 │
└─────────────────────────────────┘
```

**Copy — exact wording suggestions:**

- Title: "One quick thing" (not "Terms of Use" or "Disclaimer")
- Body: "By uploading this file, you're confirming it's yours or that you have the right to analyze it. We never store or share your audio — we just read the mood and send it back to you."
- Primary CTA: "Yes, let's hear it"
- Secondary: "Cancel"

**Tone notes for this screen:**

- No bold-all-caps legal language. No "YOU AGREE THAT..." constructions.
- The word "confirm" is fine. "Warrant" and "indemnify" are not.
- The phrase "we just read the mood" reinforces the product voice while explaining what happens.

**Interactions:**

- Tap "Yes, let's hear it" → dismiss modal, immediately navigate to Analysis Loading State (full-screen transition).
- Tap "Cancel" or drag down → dismiss modal, return to Upload Screen (file selection state preserved — don't clear it).
- Tapping the overlay behind the modal → same as Cancel.

---

### 3.4 Analysis Loading State

**Purpose:** Hold the user's attention for ~30 seconds while the backend processes the audio. The user already knows the approximate wait time from the estimate shown on the Upload Screen. The loading state must feel alive and purposeful — like the app is genuinely working, not frozen.

**Presentation:** Full-screen. Replaces the Upload Screen. No nav bar back button — the user cannot go back mid-analysis. [ASSUME] A "Cancel" text button in the top-right corner allows aborting and returning to Upload.

**Layout:**

```
┌─────────────────────────────────┐
│                         Cancel  │  ← Top-right text button
│                                 │
│                                 │
│      [Animated waveform or      │
│       pulsing mood ring]        │  ← Hero animation. Center of screen.
│                                 │   ~200px diameter / width
│                                 │
│   "Listening to the rhythm…"   │  ← Staged message. Changes per phase.
│                                 │
│   ●●●○○○  Phase 2 of 6         │  ← Dot-step progress indicator (optional)
│                                 │
│                                 │
│   [Result preview — blurred]    │  ← Appears ~28s. Frosted glass. See below.
│                                 │
└─────────────────────────────────┘
```

**Animation options (designer to choose one):**

Three candidate directions — designer should select the one that best fits the overall visual language:

1. **Animated waveform bars:** A row of 5–7 vertical bars that pulse up and down at varying speeds, like an equalizer. Bars are colored in the app's accent color. Simple, music-native metaphor. Recommended.
2. **Pulsing mood ring:** A circular ring or halo that breathes in and out slowly — subtle scale + opacity animation. In the center: the app icon or a music note. More meditative feel.
3. **Rotating vinyl graphic:** A simple stylized vinyl record (top-down view) that slowly rotates. A tone arm illustration could be static or gently oscillating. Works best if art direction leans illustrative.

[ASSUME] Option 1 (waveform bars) is the default recommendation. It communicates "listening" most directly and is the most performant.

**Staged progress — 6 phases (~5 seconds each):**

The loading screen is broken into named phases. Each phase has a message that fades in, holds, then fades out as the next phase begins. Messages correspond to what librosa is actually computing — this makes the wait feel informative, not arbitrary.

| Phase | Timing | Message                    | What's actually happening    |
| ----- | ------ | -------------------------- | ---------------------------- |
| 1     | 0–5s   | "Uploading your track…"    | File transfer to backend     |
| 2     | 5–10s  | "Listening to the rhythm…" | Tempo + beat tracking        |
| 3     | 10–15s | "Reading the energy…"      | RMS energy + dynamic range   |
| 4     | 15–20s | "Feeling the texture…"     | Spectral + harmonic analysis |
| 5     | 20–25s | "Finding the mood…"        | LLM synthesis of features    |
| 6     | 25–30s | "Almost there…"            | Result formatting + response |

Each message cross-fades over 400ms. A subtle dot-step indicator (e.g. ●●●○○○) below the message shows which phase is active — this gives the user a concrete sense of progress without a percentage bar that might feel inaccurate.

**Blur / reveal at ~28 seconds:**

At approximately 28 seconds, the result card begins to bleed through behind the loading state — visible but blurred (frosted glass / Gaussian blur, ~20px). The mood color of the result is already visible through the blur, so the user can sense the answer is coming before it fully reveals. At ~30 seconds, the blur clears and the Results screen snaps into focus.

This technique makes the final second feel like a reveal moment rather than an abrupt screen transition.

**Timeout behavior (>35 seconds):**

If the analysis has not returned after 35 seconds, the animation stops and the screen shifts to a timeout state:

```
│   [Warning icon — soft, not alarming]  │
│                                        │
│   "This one's taking longer            │
│    than usual."                        │
│                                        │
│   "Give it another try."               │
│                                        │
│   [Try again]          [Cancel]        │
```

"Try again" re-submits the same file (no need to re-pick or re-consent). "Cancel" returns to Upload Screen with file selection preserved.

**Accessibility:**

- When the Loading State appears, announce to screen readers: "Analyzing your song. Please wait." (single announcement, not repeated).
- The Cancel button must be reachable via VoiceOver / TalkBack without navigating through the animation.
- Cycling messages should be announced once each as they change, not on a rapid cycle.

---

### 3.5 Results Screen (Guest)

**Purpose:** The hero screen. Deliver the mood result with impact, give the user enough detail to feel informed, and close with a single, non-intrusive sign-up invitation.

**Visual identity note for the designer:**

This is where the four mood identities become critical. When this screen loads, the full-screen background color (or gradient), the icon/illustration in the mood hero area, and the accent color of all interactive elements should all shift to match the detected mood. Define these four design targets:

| Mood Quadrant | Short label | Suggested palette direction | Icon / illustration character |
|---|---|---|---|
| Happy & Energetic | **Upbeat** | Warm yellows + orange | Sun, lightning bolt, dancing figure |
| Happy & Calm | **Serene** | Soft teals + warm white | Wave, leaf, crescent moon |
| Intense & Dark | **Charged** | Deep purples + electric red | Storm cloud, sharp lines |
| Calm & Melancholic | **Reflective** | Cool blues + slate grey | Rain drop, quiet moon, still water |

[ASSUME] Short labels ("Upbeat," "Serene," "Charged," "Reflective") are used as the primary display on the Results screen, with the quadrant name ("Happy & Energetic") shown below in smaller type. The designer may refine these label names.

**Layout — scrollable, with a persistent bottom strip:**

```
┌─────────────────────────────────┐
│  ←  Back         Song Analysis  │  ← Nav bar. Back goes to Upload.
│                                 │
│  ┌─────────────────────────────┐│
│  │  [Mood hero area]           ││  ← Full-width colored/gradient card
│  │                             ││    or full-bleed colored background
│  │  [Mood illustration/icon]   ││
│  │                             ││
│  │  UPBEAT                     ││  ← Primary mood label. Largest type.
│  │  Happy & Energetic          ││  ← Quadrant name. Smaller, muted.
│  │                             ││
│  │  [Confidence ring/bar]      ││  ← See below
│  │  87% match                  ││
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  "upbeat · intense · danceable" │  ← Mood descriptor tags. Pill shapes.
│                                 │
│  "Fast tempo and high harmonic  │
│   ratio suggest an uplifting,   │
│   melodic quality."             │  ← Reasoning text. Small, secondary weight.
│                                 │
│  ┌─────────────────────────────┐│
│  │  Audio details   ▾          ││  ← Collapsed section header. Tap to expand.
│  └─────────────────────────────┘│
│                                 │
│                                 │
│                                 │
│ ─────────────────────────────── │
│  [Sign-up CTA strip — sticky]   │  ← Persistent, pinned to bottom
│  "Save this & track your        │
│   history"           [Sign up]  │
└─────────────────────────────────┘
```

**Mood hero area (top card/section):**

- Background: the mood's characteristic color or gradient. Should fill the full card width and feel immersive.
- Illustration / icon: centered above the label. [ASSUME] ~80px square or circular. This is the most expressive element per mood.
- Primary label ("UPBEAT"): display type, heavy weight, high contrast against the mood background.
- Quadrant name ("Happy & Energetic"): smaller, same color family as the background but at reduced opacity or a slightly different hue.
- Confidence display: A circular ring that animates in on reveal (see Section 5 for animation). Inside the ring: the percentage (e.g. "87%"). Ring fill tracks the confidence value. Below: "match" or "distinct mood" label in small text. [ASSUME] A ring/donut is more expressive than a linear bar for a hero metric.

**Mood descriptor tags:**

- 2–4 pill-shaped tags. Background: mood accent color at low opacity. Text: mood accent color at full opacity.
- Arranged in a horizontal row. If they don't fit in one row, they wrap.
- Not tappable in MVP — purely informational. [VERIFY] whether tags should eventually filter history.

**Reasoning text:**

- 1–2 sentences. Small type (body/caption scale). Not bold.
- Sits below the descriptor tags. Visually secondary.
- Should not be truncated — the backend sentence is short enough to show in full.

**Audio details section (collapsible):**

Default state: collapsed. Header row shows "Audio details" with a chevron-down icon on the right. Tap to expand.

Expanded state:

```
│  ┌─────────────────────────────┐│
│  │  Audio details   ▲          ││
│  │                             ││
│  │  Tempo       128 BPM        ││
│  │  Energy      High (0.84)    ││
│  │  Brightness  Bright         ││
│  │  Texture     Smooth         ││
│  └─────────────────────────────┘│
```

- Each row: label left, value right.
- "High," "Bright," "Smooth" are human-readable interpretations of numerical values — not the raw numbers alone. Raw values shown in parentheses.
- The backend already returns human-readable interpretations for Energy, Brightness, and Texture (e.g. "high energy, very dynamic", "bright", "melodic/harmonic"). The app displays these strings directly — no client-side bucketing needed.

**"Analyze another song" button:**

- Below the collapsible audio section. Full-width, secondary style (outlined or ghost). Not the most important thing on screen.
- Tapping navigates to Upload Screen and clears the previous file selection.

**Sign-up CTA strip (persistent, pinned to bottom):**

- Always visible, even when scrolling. Sits above the system home indicator.
- Left side: short copy. "Save this & see your history."
- Right side: "Sign up" — pill button, filled, mood accent color.
- The strip should not be so tall that it crowds the content above. Approximately 56–64px tall.
- Tapping "Sign up" navigates to Sign In / Sign Up Screen.

**Reveal animation (on first landing):**

When the Results screen first appears, elements animate in sequentially — see Section 5.

**Empty / error states:**

This screen only appears with a valid result. Loading/error states are handled on the Loading State screen (timeout) and before this screen is reached.

---

### 3.6 Sign In / Sign Up Screen

**Purpose:** Collect credentials or OAuth. As light as possible. Toggle between signing in and signing up without navigating to a new screen.

**Entry points:**

1. From Landing Home → "Sign in" secondary CTA
2. From Guest Results → "Sign up" CTA strip

**Layout:**

```
┌─────────────────────────────────┐
│  ←  Back                        │
│                                 │
│         [MoodTune wordmark]     │
│                                 │
│  ┌──────────┐  ┌──────────┐    │
│  │ Sign in  │  │ Sign up  │    │  ← Toggle tabs (underline indicator)
│  └──────────┘  └──────────┘    │
│                                 │
│  [Email field]                  │
│  [Password field]               │
│                                 │
│  (Sign up only)                 │
│  [Confirm password field]       │  ← Only visible in Sign Up mode
│                                 │
│  ┌───────────────────────────┐  │
│  │    Sign in / Sign up      │  │  ← Label changes with toggle
│  └───────────────────────────┘  │
│                                 │
│  ─────────── or ──────────────  │
│                                 │
│  ┌───────────────────────────┐  │
│  │  [Google icon]  Continue with Google  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │  [Apple icon]   Continue with Apple   │
│  └───────────────────────────┘  │
│                                 │
│  [Forgot password?]             │  ← Small text link, sign-in mode only
│                                 │
└─────────────────────────────────┘
```

**Key UI elements:**

- **Toggle tabs:** Two labels ("Sign in" / "Sign up") with an underline or pill indicator showing the active mode. Switching modes is instant — no navigation, just field visibility change.
- **Email field:** Standard text input. Email keyboard. Autocomplete/autofill compatible.
- **Password field:** Standard secure text input. Show/hide toggle icon on the right.
- **Confirm password field:** Visible only in Sign Up mode. Appears with a smooth height animation when toggling to Sign Up.
- **Primary CTA button:** Full-width, filled. Label reads "Sign in" or "Sign up" matching the active mode.
- **Social buttons:** Google and Apple, in that order. Full-width, each on its own row. Standard platform button styling (Google: white bg, Google logo; Apple: black bg, Apple logo on light theme, or inverse on dark theme).
- **Forgot password:** Text link below the primary button, Sign In mode only. Tapping navigates to the Forgot Password Screen (§3.8).

**States:**

- **Loading (after submit):** Inline spinner replaces the button label. Button stays full-width. Form fields become non-editable.
- **Error:** Inline error message below the relevant field(s), or a banner below the CTA: "That email and password don't match. Try again." Not a modal dialog.
- **Success:** Navigate to Home (Authenticated). No separate "Welcome!" screen. The user lands directly in the authenticated home.

**Copy direction:**

- Do not show "Create an account to unlock features." Frame it as access to history, not a gate.
- Error messages: "That didn't work — check your email and password." (Not: "Authentication failed. Error code 401.")

Email verification is required on sign-up. After successful sign-up form submission, the user is taken to the Email Verification Interstitial screen (§3.7) before accessing the authenticated home.

---

### 3.7 Email Verification Interstitial

**Purpose:** Inform the user that a verification email has been sent and prompt them to check their inbox before continuing.

**Entry point:** Immediately after successful sign-up form submission (before navigating to Home).

**Layout:**

```
┌─────────────────────────────────┐
│                                 │  ← No nav bar back button (mid-flow)
│                                 │
│         [Envelope icon]         │  ← Simple email/envelope illustration
│                                 │
│       "Check your inbox"        │  ← Heading. Warm, not alarming.
│                                 │
│  "We sent a link to             │
│   you@email.com. Tap it to      │
│   confirm your account."        │  ← Body. Shows actual email address.
│                                 │
│                                 │
│       Resend email              │  ← Text link. 60-second cooldown.
│                                 │
│                                 │
│    Wrong email? Go back         │  ← Small text link at bottom.
│                                 │
└─────────────────────────────────┘
```

**States:**

- **Default (waiting):** As shown above. "Resend email" link is interactive.
- **Resend cooldown:** Link text changes to "Resend in Xs" (e.g. "Resend in 52s") and becomes non-interactive. Countdown ticks down from 60.
- **Resend triggered:** Brief "Sent!" confirmation text for 1.5 seconds, then returns to cooldown state.
- **Verified (deep link returns to app):** When the user taps the verification link in their email, the app opens and the auth state updates automatically. Navigate to Home (Authenticated) with a brief "You're in!" toast. No manual code entry required.

**Key UI elements:**

- **Envelope icon:** Simple, friendly illustration — not a warning icon. Centered, given visual prominence above the heading.
- **Heading:** "Check your inbox" — friendly and action-oriented. Do not use the word "verify."
- **Body copy:** Shows the actual email address the link was sent to. Helps the user know where to look.
- **Resend email link:** Text link weight. Initiates a 60-second cooldown on tap to prevent spam. During cooldown, displays "Resend in Xs" and is non-interactive. After cooldown expires, returns to "Resend email."
- **"Wrong email? Go back" link:** Small, bottom of screen. Returns user to the Sign Up form so they can correct their email address.

**Copy direction:**

- Friendly, not alarming. "Check your inbox" not "Verify your email address."
- Do not use the word "verify" anywhere on this screen.
- Body copy confirms what happened ("We sent a link") and what to do ("Tap it to confirm your account") in plain language.

**Note:** Verification happens via a deep link in the email. When the user taps the link, the app opens and the auth state updates automatically — no manual code entry.

---

### 3.8 Forgot Password Screen

**Purpose:** Allow the user to request a password reset email.

**Entry point:** "Forgot password?" text link on the Sign In / Sign Up Screen (sign-in mode only).

**Layout — default state:**

```
┌─────────────────────────────────┐
│  ←  Back                        │  ← Nav bar with back arrow (→ Sign In screen)
│                                 │
│     "Reset your password"       │  ← Heading
│                                 │
│  "Enter your email and we'll    │
│   send you a link to reset it." │  ← Body
│                                 │
│  [Email field]                  │  ← Pre-filled if email already entered on
│                                 │    the Sign In screen
│  ┌───────────────────────────┐  │
│  │     Send reset link       │  │  ← Full-width primary button
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**After submission — success state:**

The form is replaced with a confirmation view:

```
┌─────────────────────────────────┐
│  ←  Back                        │
│                                 │
│         [Envelope icon]         │
│                                 │
│           "Link sent"           │  ← Heading
│                                 │
│  "Check your email for a reset  │
│   link. It expires in 1 hour."  │  ← Body
│                                 │
│         Resend                  │  ← Text link. Same 60-second cooldown
│                                 │    as email verification screen.
│       Back to sign in           │  ← Text link
│                                 │
└─────────────────────────────────┘
```

**Error state:**

If the email is not found, show an inline error below the email field: "We don't recognise that email. Double-check it or sign up instead." — with a "Sign up" text link at the end of the error message.

**Code flow note:**

On the Flutter side, call `supabase.auth.resetPasswordForEmail(email)`. This triggers Supabase to send a password reset email with a magic link. The link opens a deep link back into the app. Handle the deep link in the auth listener — when a `passwordRecovery` event is received, navigate the user to a Set New Password screen (not scoped in this design pass — flag as a follow-on screen to design).

---

## 4. Screen Specs — Authenticated Flow

---

### 4.1 Home (Authenticated)

**Purpose:** Upload entry point + recent history in a single, scannable view. The user should be able to start a new analysis or jump back to a past result within two taps.

**Layout:**

```
┌─────────────────────────────────┐
│  MoodTune           [Avatar/    │
│                      initials]  │  ← Nav bar. Avatar taps to profile/sign out.
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │   [Music note icon]         ││  ← Upload card. Prominent. Top of screen.
│  │   "Analyze a new song"      ││
│  │   Tap to upload a file      ││
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │  [Catalog icon]             ││  ← Catalog card. Secondary. Below upload card.
│  │  "Browse the catalog"       ││
│  │  Explore free music         ││
│  └─────────────────────────────┘│
│                                 │
│  Recent analyses                │  ← Section heading
│  ─────────────────────────────  │
│                                 │
│  ┌─────────────────────────────┐│
│  │ [Mood chip] track-name.mp3  ││  ← History item (see below)
│  │ Upbeat · 87%   May 9, 2026  ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ [Mood chip] another-song.mp3││
│  │ Reflective · 61%  May 7     ││
│  └─────────────────────────────┘│
│                                 │
│  [See all history →]            │  ← Text link / ghost button
│                                 │
└─────────────────────────────────┘
```

**Upload card:**

- Full-width card. Rounded corners. Has a subtle background — either a light gradient or the app's brand accent at very low opacity.
- Contains: a centered music icon, a short heading ("Analyze a new song"), and a short subtext ("Tap to upload a file").
- The entire card is tappable → navigates to Upload Screen.

**Catalog card:**

- Full-width card. Rounded corners. Visually secondary to the upload card — lower visual weight (lighter background, smaller icon, less vertical padding — approximately 56px tall vs the upload card's larger presence).
- Contains: a catalog/browse icon (e.g. a grid or music library icon), heading ("Browse the catalog"), subtext ("Explore free music").
- The entire card is tappable → navigates to Catalog Search Screen (§9.2).
- Positioned immediately below the upload card, above "Recent analyses."

**History item:**

Each row in the "Recent analyses" list shows:

- **Mood chip:** A small pill badge, colored with the mood's accent color, containing the short mood label (e.g. "Upbeat"). This gives instant visual scannability.
- **Title:** Displayed label for the analysis. Two formats depending on source:
  - *Uploaded file:* audio filename or user-entered title (if provided). Truncated at ~24 characters.
  - *Catalog track:* "Track Name · Artist Name" — pulled from Jamendo metadata. Truncated at ~24 characters with ellipsis. No filename exists for catalog tracks.
- **Confidence:** Percentage, e.g. "87%".
- **Date:** Relative if recent ("Yesterday," "May 9"), absolute if older.

Tap → navigate to Results Screen (Authenticated) for that analysis.

**"See all history" link:**

Appears after 3–4 items. Routes to History Screen.

**Empty state (no past analyses):**

```
│  ┌─────────────────────────────┐│
│  │   "Analyze a new song"      ││  ← Upload card remains
│  └─────────────────────────────┘│
│                                 │
│  "Your past analyses will       │
│   appear here."                 │  ← Simple, no emoji, no illustration needed
│                                 │
│   Analyze your first song →     │  ← Ghost button, routes to Upload Screen
```

---

### 4.2 Results Screen (Authenticated)

**Purpose:** Same result content as Guest Results, minus the sign-up strip. Result is auto-saved — confirm this with a brief "Saved" toast, then it disappears.

**Differences from Guest Results Screen:**

1. **No sign-up CTA strip.** The bottom of the screen ends with the "Analyze another song" button, with normal bottom padding.
2. **"Saved" toast notification.** Approximately 1–2 seconds after the screen appears, a small toast/snackbar appears at the top or bottom (designer's choice — stay consistent with platform conventions): "Saved to your history." It auto-dismisses after 2 seconds. No action needed from the user.
3. **No other behavioral changes.** Mood hero, descriptor tags, reasoning, audio details collapsible section, and "Analyze another song" button are all identical to the Guest version.

**Layout:**

Identical to Guest Results Screen (Section 3.5) with:
- Bottom strip replaced with extra padding
- "Saved" toast appears briefly on load

---

### 4.3 History Screen

**Purpose:** Full chronological list of past analyses. Primarily a reference view — the user comes here to find and re-view a past result.

**Entry point:** "See all history" link from Home (Authenticated), or second tab in the bottom tab bar [ASSUME].

**Layout:**

```
┌─────────────────────────────────┐
│  ←  Back           My History  │
│                                 │
│  [Filter by mood]               │  ← Optional filter row. See below.
│                                 │
│  ┌─────────────────────────────┐│
│  │ [Mood chip] track-name.mp3  ││
│  │ Upbeat · 87%   May 9, 2026  ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ [Mood chip] another.mp3     ││
│  │ Reflective · 61%  May 7     ││
│  └─────────────────────────────┘│
│  ...                             │
│                                 │
└─────────────────────────────────┘
```

**Filter row:**

A horizontal scrollable chip row at the top: "All · Upbeat · Serene · Charged · Reflective". Default = "All". Tapping a mood chip filters the list to show only that mood category. This is in MVP scope.

**History cap — 50 analyses:**

The list shows the user's **50 most recent analyses** only. Older analyses beyond 50 are not displayed. A subtle note sits at the bottom of the list (below the last item) when the cap is reached:

```
│  ─────────────────────────────  │
│  Showing your 50 most recent    │
│  analyses.                      │
└─────────────────────────────────┘
```

No pagination, no "load more" — the list is capped at 50 and clearly labelled as such. This is a known product constraint for MVP; unlimited history may be a future feature.

**History item (same as Home):**

Same row design as the Home history items — mood chip, title (filename for uploads / "Track · Artist" for catalog tracks), confidence, date. Tap → Results Screen for that item.

**Empty state:**

```
│                                 │
│   [Subtle waveform illustration]│
│                                 │
│   "Nothing here yet."          │
│                                 │
│   "Analyze a song to see your  │
│    history here."               │
│                                 │
│   ┌─────────────────────────┐  │
│   │  Analyze a song         │  │  ← Routes to Upload Screen
│   └─────────────────────────┘  │
│                                 │
```

---

## 5. Key Interactions & Micro-interactions

### 5.1 File selection flow

```
User taps upload zone
    → OS file picker sheet opens (system UI, no custom design needed)
    → User selects file
    → Sheet closes
    → Upload zone card transitions:
        - Border changes color (success/accent color)
        - Checkmark icon fades in (top-left of card, or replaces music note)
        - Filename appears (truncated if needed)
        - File size appears below filename
        - "Change file" text link appears (bottom-right of card)
    → Analyze button transitions from disabled to enabled
        (color fills in, slight scale pulse — 150ms ease-out)
```

Transition for the upload zone card: not an abrupt swap. The card content cross-fades over ~200ms. The checkmark icon can "pop" in with a brief scale animation (0.8 → 1.0, 150ms, ease-out spring).

### 5.2 Consent → Loading transition

```
User taps "Yes, let's hear it" in Consent Modal
    → Modal slides down and dismisses
    → Immediately: full-screen Loading State appears (push or fade-up transition)
    → Animation starts
    → Cycling messages begin
```

No delay between dismissing consent and starting the loading state. The transition should feel instantaneous.

### 5.3 Loading → Results reveal

When the analysis result returns from the backend:

```
Loading State → Results Screen
    → Transition: the mood-colored background fades/slides in as the new screen base
    → Mood hero area: the illustration/icon fades in first (200ms)
    → Primary mood label: slides up from slightly below its final position (300ms, ease-out)
    → Quadrant name: fades in after label settles (100ms delay after label)
    → Confidence ring: draws from 0% to final value (400ms, ease-out, starts after label appears)
    → Percentage number: counts up from 0 to final value in sync with ring draw
    → Descriptor tags: fade in as a group, staggered 50ms per tag (after ring completes)
    → Reasoning text: fades in last (after tags)
    → Sign-up strip (guest): slides up from below (after reasoning text)
```

Total reveal sequence: approximately 800–900ms from screen transition to fully settled state. Nothing should feel slow — this is polish, not spectacle. If any element of this feels too long in testing, drop the stagger and have groups fade in together.

### 5.4 Confidence ring animation

- The ring is a circular progress indicator (donut chart shape).
- On page enter: ring animates from empty (0%) to the confidence value.
- Animation duration: 400ms. Easing: ease-out cubic.
- Simultaneously, the percentage number inside the ring counts up from 0 to the value (integer steps, no decimals in the animation).
- After the ring settles, there is no loop or idle animation — it is static.

Confidence thresholds are confirmed:

- ≥ 75% → "Strong match" — ring nearly or fully filled, mood accent color at full brightness.
- 50–74% → "Good match" — ring at medium fill, mood accent color.
- < 50% → "Possible match" — ring partially filled, yellow-orange tint to signal moderate confidence.

The designer should define the exact colors for each band.

### 5.5 "Analyze another song" tap

```
User taps "Analyze another song"
    → Navigate back to Upload Screen (push transition — not a full stack reset)
    → Upload zone resets to default state (file cleared)
    → Analyze button returns to disabled state
    → Metadata fields (Title, Artist, Album) are cleared
```

### 5.6 Collapsible audio details

```
User taps "Audio details" header row
    → Row expands to reveal 4 metric rows
    → Expansion animation: height grow from 0 to full, 200ms, ease-out
    → Chevron rotates 180° (▾ → ▴), in sync with expansion
    → Content fades in over the last 100ms of the expansion
    → Tap again to collapse (reverse)
```

### 5.7 "Saved" toast (Authenticated results)

```
Results Screen loads (authenticated)
    → After ~800ms (after reveal animation completes)
    → "Saved to your history." toast appears
    → Toast: slides in from top or fades in at bottom (consistent with platform)
    → Stays visible for 2 seconds
    → Auto-dismisses (fades out)
    → No user action required
```

---

## 6. Copy Direction

### 6.1 Tone

Friendly, curious, a little musical. The app has a personality — it cares about music and is genuinely interested in what a song is doing. It is not a clinical tool. It is also not breathlessly excited. Think: a knowledgeable friend who loves music, not a product landing page.

### 6.2 Voice rules

| Do say | Do not say |
|---|---|
| "We read the energy" | "Our algorithm analyzed" |
| "Here's what we heard" | "Processing complete" |
| "Reading the texture…" | "Uploading audio…" |
| "Found the mood" | "AI detected" |
| "Your song" | "The uploaded file" |
| "Reflective" | "Calm & Melancholic (Category 4)" |
| "Confident match" | "High confidence score: 0.87" |

### 6.3 Mood label copy

Short labels are the primary display. Quadrant names are secondary, supporting context.

| Short label | Quadrant name (secondary) | Descriptor example tags |
|---|---|---|
| Upbeat | Happy & Energetic | upbeat · danceable · bright |
| Serene | Happy & Calm | peaceful · warm · flowing |
| Charged | Intense & Dark | intense · driving · tense |
| Reflective | Calm & Melancholic | melancholic · quiet · introspective |

The confidence ring label copy (confirmed): "Strong match" for ≥75%, "Good match" for 50–74%, "Possible match" for <50%.

### 6.4 Error message copy direction

Errors should be specific and helpful, not alarming. One sentence for the problem, one for the fix.

- File too large: "This file is a little too big (X MB). We can read files up to 15 MB — try a shorter track or a lower-bitrate export."
- Wrong format: "We can't read this file type. Try uploading an MP3, M4A, FLAC, WAV, or OGG file."
- Analysis failed (generic): "Something went wrong on our end. It's not your file — give it another try."
- No internet: "You're offline right now. Analysis needs a connection — come back when you've got one."
- Rate limit: "You've done a lot of listening today. Try again in a little while." Rate limiting is not yet implemented. When added, if the API returns a Retry-After value, update this copy to show the specific time.
- Timeout: "This one's taking a while — give it another try."

---

## 7. Error & Edge Cases

### 7.1 File too large (>15 MB)

**Where it appears:** Upload Screen, immediately after file selection (before the user taps Analyze).

**Trigger:** File size detected by the app client-side — no need to wait for network.

**UI treatment:**

- Upload zone card border turns error-red.
- Error message appears inside or directly below the card: "This file is too large. Max size is 15 MB."
- Analyze button remains disabled.
- "Change file" link is relabeled "Choose a different file."
- No modal dialog — inline error only.

### 7.2 Unsupported format

**Where:** Upload Screen, immediately after file selection.

**Trigger:** File extension not in the accepted list (client-side check).

**UI treatment:** Same as file too large — error state in the upload zone card. Message: "We can't read this file type. Supported: MP3, M4A, FLAC, WAV, OGG."

### 7.3 Analysis failure (server / network error)

**Where:** Analysis Loading State.

**Trigger:** Network error, server 5xx, or backend returns an error response.

**UI treatment:**

- Animation stops.
- Screen shifts to error state (replaces cycling message + animation):

```
│   [Soft warning icon]           │
│                                 │
│   "Something went wrong."       │
│                                 │
│   "It's not your file — try    │
│    again and it should work."   │
│                                 │
│   [Try again]     [Cancel]      │
```

- "Try again" → retries analysis with the same file (no re-pick, no re-consent).
- "Cancel" → returns to Upload Screen (file preserved in selection state).

### 7.4 Timeout (>15 seconds)

**Where:** Analysis Loading State.

**Trigger:** Analysis has been running for 15+ seconds with no response.

**UI treatment:** Same error state template as 7.3, but with copy: "This one's taking a while. Give it another try — it usually only takes a few seconds."

### 7.5 No internet connection

**Where:** Two points.

1. On the Landing Screen (detected before navigating to Upload): small inline banner below the CTA.
2. On the Loading State (connection lost mid-analysis): same error state as 7.3, with copy: "Looks like you went offline. Check your connection and try again."

[ASSUME] The app does not need a persistent offline mode or offline state. The only meaningful offline message is "come back when you have a connection."

### 7.6 Rate limit (10 uploads per hour)

**Where:** Analysis Loading State, or immediately after tapping "Analyze song" (if the limit can be detected before submission).

**UI treatment:**

If detected before submission (client-side rate limit tracking):

- Analyze button is disabled.
- Below the button: "You've analyzed a lot of songs today. Try again soon."

If returned as a server error during analysis:

- Loading State shifts to error state with copy: "You've done a lot of listening today. Try again in a little while."
- Single "OK" button returns to Upload Screen. No "Try again" — the user genuinely cannot retry yet.

Note: Rate limiting is not yet implemented. When added, if the API returns a Retry-After value, update this copy to show the specific time.

### 7.7 Jamendo API errors (Catalog feature)

**Catalog search — no results:**
UI treatment: empty state within the results area (§9.2). Not a full-screen error.

**Catalog search — API unavailable (5xx or network):**
The search field remains active. Below the results area: "Couldn't reach the catalog right now. Check your connection or try again." A "Try again" text link re-triggers the last search.

**Track analysis — fetch failure (Jamendo audio unavailable):**
Detected during the Loading State when the backend cannot stream the track. Same error state as §7.3, with copy: "We couldn't fetch that track from Jamendo. Try a different track or upload your own file."

**Track analysis — Jamendo track too long:**
[ASSUME] If a track exceeds the backend's analysis limit (e.g. > 10 minutes), fail gracefully. Copy: "This track is too long to analyze. Try a shorter one." — shown on the Loading State error state.

---

## 8. Accessibility Notes

### 8.1 Color and contrast

- All four mood color palettes must pass WCAG AA contrast ratio (4.5:1 for body text, 3:1 for large/display text) against both their own backgrounds and the app's default light/dark backgrounds.
- Mood information is never conveyed by color alone. Every mood is identified by: color + short text label + icon/illustration. A user who cannot perceive color differences can still identify the mood from text and iconography.
- The confidence ring uses color to indicate confidence level ([ASSUME] color shifts per threshold in Section 5.4). The ring must also include a text label ("Strong match," "Good match") so color is not the only signal.

### 8.2 Screen reader support

- **Loading State:** On screen entry, announce: "Analyzing your song. Please wait." (single announcement). Cycling messages should each be announced once as they change — use the platform's live region / semantic announcement API. Do not suppress them.
- **Results Screen:** On entry, announce the primary result: "Result: [Mood label]. [Confidence]% match." Subsequent elements (descriptor tags, reasoning, audio details) are reachable by sequential focus traversal.
- **Confidence ring:** Label as "Confidence: [X]% — [Strong/Good/Possible] match." The visual animation does not need to be narrated — only the final value.
- **Collapsible audio details:** The header row should be labeled as a button: "Audio details, collapsed" / "Audio details, expanded." Toggle state changes must be announced.
- **Mood descriptor tags:** Each tag should be readable as individual elements, not a merged string. e.g. "Tag: upbeat," "Tag: danceable."

### 8.3 File picker

- The OS file picker (system UI) is natively accessible on both iOS and Android. No custom replacement needed.
- The upload zone card (before file selection) must have a clear accessibility label: "Select audio file. Accepted formats: MP3, M4A, FLAC, WAV, OGG. Max 15 MB."
- After file selection, the card's accessibility label updates to: "Selected: [filename], [size] MB. Tap to change file."

### 8.4 Touch targets

- All interactive elements must have a minimum touch target of 44×44pt (iOS HIG) / 48×48dp (Material).
- The "Cancel" button on the Loading State and the "Change file" link on Upload Screen are the smallest interactive elements — ensure they meet this minimum.
- The sign-up CTA strip button ("Sign up") must be at least 44pt tall despite the strip's compact design.

### 8.5 Animations and motion

- All animations described in this spec should be suppressible when the user has enabled "Reduce Motion" in system settings.
- In reduced-motion mode:
  - The confidence ring appears immediately at its final value (no count-up animation).
  - Results screen elements appear immediately (no stagger).
  - The loading state uses the cycling text messages but replaces the waveform animation with a simple static icon.
  - The collapsible section expands without an animated height change.

---

## 9. Catalog Feature — Jamendo Integration

### 9.1 Overview

The Jamendo integration adds a second path to mood analysis: instead of uploading a file from the device, users can search the Jamendo free music catalog and analyze any track directly. The analysis pipeline is identical — the same Loading State, Results Screen, and mood identity system apply. The difference is the source of the audio.

Entry point: a dedicated **"Browse the catalog"** button/card on the Home screen — both Guest (§3.1) and Authenticated (§4.1). The Upload Screen is unaffected; it remains file-upload only.

Both routes are available to guests (no account required) and authenticated users.

### 9.2 Catalog Search Screen

**Purpose:** Let the user search or browse Jamendo's free music catalog and select a track to analyze. Should feel like a lightweight music discovery experience, not a database query form.

**Layout — default / empty state:**

```
┌─────────────────────────────────┐
│  ←  Back       Browse Catalog   │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │  🔍  Search tracks…         ││  ← Search field. Autofocused on entry.
│  └─────────────────────────────┘│
│                                 │
│  Filter by mood:                │
│  [ All ][ Upbeat ][ Serene ]   │  ← Horizontal chip row. Scrollable.
│  [ Charged ][ Reflective ]     │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  "Search for a track or pick    │
│   a mood to explore."           │  ← Empty / pre-search prompt. Muted.
│                                 │
└─────────────────────────────────┘
```

**Layout — search results:**

```
┌─────────────────────────────────┐
│  ←  Back       Browse Catalog   │
├─────────────────────────────────┤
│  ┌─────────────────────────────┐│
│  │  🔍  ambient piano          ││
│  └─────────────────────────────┘│
│                                 │
│  [ All ][ Upbeat ][ Serene ]…  │
│                                 │
│  ┌─────────────────────────────┐│
│  │ [Album art 48×48]           ││  ← Track result card (see §9.3)
│  │ Still Waters                ││
│  │ Artist Name · 3:42          ││
│  │ [tag] [tag]    [Analyze →]  ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ [Album art]                 ││
│  │ Morning Light               ││
│  │ Another Artist · 4:15       ││
│  │ [tag] [tag]    [Analyze →]  ││
│  └─────────────────────────────┘│
│   …                             │
│                                 │
└─────────────────────────────────┘
```

**Search behavior:**

- Search triggers on: "Search" keyboard tap or debounced input (300ms after last keystroke). [ASSUME] Debounced live search — no need to tap a button.
- Query maps to Jamendo API `namesearch` param; mood chip selection maps to `tags` param.
- Mood chips and search field can be combined (e.g. search "piano" + filter "Serene").
- Default limit: 20 results. No pagination in MVP — show top 20 matches.
- Results appear in a scrollable list below the filter row.

**Loading state (during search):**

- A subtle shimmer/skeleton loader replaces the results list while the API call is in-flight.
- Do not show a full-screen spinner — the search field and filter chips remain interactive.

**Empty results state:**

```text
│   "No tracks found for          │
│    '[query]'."                  │
│                                 │
│   "Try different keywords or    │
│    clear the mood filter."      │
```

**Key UI elements:**

- **Search field:** Full-width, rounded. Placeholder: "Search tracks…" Autofocused when the screen opens. Clear (×) button appears when text is present.
- **Mood chips:** Horizontal scrollable chip row. Default = "All." Tapping a chip filters results to that mood tag. Chips use the same mood accent colors as the rest of the app.
- **Track result card:** See §9.3.

**Interactions:**

- Tap "Analyze →" on any track card → navigate to Catalog Track Confirm sheet (§9.4).
- Back → return to previous screen (Landing / Home).

### 9.3 Track Result Card (component)

Each result in the catalog search list is a card with:

- **Album art:** 48×48px thumbnail, rounded corners. Loaded from the Jamendo `image` URL. Placeholder: a generic music note icon in the app's muted accent color while loading.
- **Track name:** 1 line, truncated with ellipsis at ~28 characters.
- **Artist name + duration:** Single line, secondary text weight. Format: "Artist Name · 3:42"
- **Tag pills:** 1–2 small pill tags from Jamendo `musicinfo` (e.g. "ambient," "piano"). Muted background, small text. Max 2 shown — overflow truncated silently.
- **"Analyze →" button:** Small filled pill button, right-aligned. Tapping it triggers the analysis confirmation flow.

The card should be compact — aim for ~72–80px row height. This is a scanning-friendly list, not a detail view.

### 9.4 Catalog Track Confirm (bottom sheet)

**Purpose:** A brief confirmation before the app kicks off analysis. No consent copy needed (no user file is being uploaded — this is licensed Jamendo content). The sheet is lightweight: just "here's what you picked, go?"

**Presentation:** Bottom sheet. Slides up over the Catalog Search Screen. ~35% of screen height.

**Layout:**

```text
┌─────────────────────────────────┐
│         ▬▬▬ (drag handle)       │
│                                 │
│  [Album art 64×64]              │
│  Track Name                     │  ← Display name, 1 line
│  Artist Name · 3:42             │  ← Subtitle, muted
│                                 │
│  "We'll analyze the mood of     │
│   this track from Jamendo's     │
│   free music library."          │  ← Short explanation. 2 lines max.
│                                 │
│  ┌───────────────────────────┐  │
│  │  Analyze this track       │  │  ← Primary CTA. Filled.
│  └───────────────────────────┘  │
│                                 │
│           Cancel                │  ← Text link.
│                                 │
└─────────────────────────────────┘
```

**Interactions:**

- Tap "Analyze this track" → dismiss sheet, navigate to Analysis Loading State.
- Tap "Cancel" or drag down → dismiss, return to Catalog Search Screen with results preserved.

**Note:** No consent copy about file ownership is needed here — Jamendo tracks are licensed for free use. The confirmation is just UX friction management (prevent accidental taps), not a legal acknowledgement.

### 9.5 Loading State — Catalog variation

The Analysis Loading State (§3.4) is reused as-is, with one copy change: Phase 1 message changes from "Uploading your track…" to "Fetching the track…"

This is because the backend streams the audio from Jamendo (not from the user's device), so "uploading" is misleading. All other phases and timings remain the same.

**Timing note:** Because the backend must first download the full MP3 from Jamendo before running librosa analysis, total analysis time may be slightly longer than local-file uploads — especially for longer tracks. The existing duration estimate buckets (§3.2) do not apply here (duration is known from Jamendo metadata but the additional fetch step adds variable latency). [ASSUME] Display a fixed estimate: "Analysis takes up to 45 seconds" regardless of track duration, until backend timing data is available to calibrate this.

**Client timeout: 35 seconds** — same threshold as the upload flow (§3.4, §7.4). If analysis has not returned within 35 seconds, the Loading State shifts to the timeout error state with copy: "This one's taking a while — give it another try." This will be tested and calibrated once real Jamendo fetch + analysis times are measured. The backend may need a server-side timeout higher than 35s to avoid races; that is a backend concern, not a UX one.

### 9.6 Results Screen — Catalog

No changes to the Results Screen. The `AudioAnalysisResponse` shape is identical whether the source was a user upload or a Jamendo track. The results screen has no knowledge of source.

**Required addition — Jamendo attribution strip:**

Jamendo's API Terms of Use require three things for every track displayed:

1. The **artist** credited as creator
2. **Jamendo** credited as provider
3. A **direct link to the specific track's page** on Jamendo (not just jamendo.com)

Add an attribution row at the bottom of the scrollable content, below "Analyze another song":

```text
│  ─────────────────────────────  │
│  [Artist Name] on Jamendo  ↗    │  ← Tappable. Links to the track's Jamendo page.
│  Via Jamendo Free Music         │  ← Small secondary line. Muted.
```

Design notes:

- Two-line treatment: artist name + track name as the tappable link (opens the track's Jamendo URL in the system browser), "Via Jamendo Free Music" as non-tappable supporting label.
- Caption text size. Muted color — should not compete with mood content above it.
- The track's Jamendo URL is returned by the API alongside other track metadata — pass it through from the catalog response to the results screen. [ASSUME] The backend includes the Jamendo track permalink in the analysis response when the source is a catalog track.
- This strip appears **only** on catalog-sourced results, not on user-uploaded file results.

**`audiodownload_allowed` constraint:**

The Jamendo tracks endpoint returns an `audiodownload_allowed` boolean per track. If `false`, the track's full MP3 cannot be downloaded — meaning analysis is not possible. Tracks with `audiodownload_allowed: false` must be filtered out of search results (backend responsibility) or handled as a graceful error (§7.7). Do not surface these tracks to the user as selectable. See §7.7 for the error case if a non-downloadable track is somehow reached.

---

## Appendix A: Screen Inventory

| Screen | Guest | Authenticated |
|---|---|---|
| Landing / Home (Guest) | Yes | No |
| Home (Authenticated) | No | Yes |
| Upload Screen | Yes | Yes |
| Consent Modal | Yes | Yes |
| Analysis Loading State | Yes | Yes |
| Results Screen (Guest) | Yes | No |
| Results Screen (Authenticated) | No | Yes |
| Sign In / Sign Up Screen | Yes | Yes |
| History Screen | No | Yes |
| Catalog Search Screen | Yes | Yes |
| Catalog Track Confirm (bottom sheet) | Yes | Yes |

---

## Appendix B: Resolved Questions

1. [RESOLVED] Are the short mood labels approved? — Approved as "Upbeat / Serene / Charged / Reflective."
2. [RESOLVED] Is email verification on sign-up required? — Required. Email verification interstitial screen added (§3.7).
3. [RESOLVED] Is a "Forgot password" flow in scope? — In scope. Forgot Password screen added (§3.8).
4. [RESOLVED] Are audio stat interpretations computed by the app or provided by the backend? — Backend returns human-readable strings directly; no client-side bucketing needed.
5. [RESOLVED] Does the rate-limit API response include a reset timestamp? — Reset time is unknown to the client. Rate limiting is not yet implemented; copy uses "try again soon."
6. [RESOLVED] Should optional metadata fields be collapsed or visible by default? — Hidden by default behind an "Add song details ▾" expand toggle.
7. [RESOLVED] Is the mood filter on History Screen in MVP scope? — In scope for MVP. History is capped at 50 analyses.
8. [RESOLVED] Are the confidence label thresholds approved? — Approved: ≥75% Strong match, 50–74% Good match, <50% Possible match.
9. ~~[VERIFY] What is the preferred entry point for the catalog feature?~~ **Resolved:** Dedicated "Browse the catalog" button/card on both Guest Home (§3.1) and Authenticated Home (§4.1). Upload Screen is unaffected.
10. ~~[VERIFY] Is Jamendo attribution required?~~ **Resolved:** Yes — required by Jamendo API ToS. Three obligations per track: (1) artist credited as creator, (2) Jamendo credited as provider, (3) direct backlink to the specific track's Jamendo page. Attribution strip spec updated in §9.6. Also: `audiodownload_allowed` must be checked per track — non-downloadable tracks must be filtered from catalog results.
11. ~~[VERIFY] Expected backend timeout for Jamendo track analysis?~~ **Resolved:** 35-second client timeout confirmed — same as upload flow. Will be tested and calibrated against real fetch + analysis times. See §9.5.
12. ~~[VERIFY] Should catalog tracks be saved to authenticated history?~~ **Resolved:** Yes. Represented as "Track Name · Artist Name" (from Jamendo metadata) in place of a filename. History item display updated in §4.1 and §4.3.
