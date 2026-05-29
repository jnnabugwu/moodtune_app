# MoodTune — Notehead logo

Three SVG assets, all built around a single concept: a quarter note whose head is a smiling face. Music + emotion in one shape.

## Files

| File | When to use |
|---|---|
| `moodtune-mark.svg` | App icon, favicon, anywhere you need just the symbol. Uses `currentColor` for the note, so colour it via CSS (`color: …`). Face cut-outs use `#efece6` (cream) so the smile reads on most light backgrounds; for very dark backgrounds, use the dark variant instead. |
| `moodtune-mark-dark.svg` | Reverse / accent variant. Peach `#d99d77` mark on ink `#2d2a26` square. Drop in as-is. |
| `moodtune-lockup.svg` | Primary lockup — mark + wordmark side by side. Uses `currentColor` for both, so it inherits text colour. Wordmark is set in **Inter Tight 700**; load that font in your app for it to render correctly (otherwise falls back to the system sans). |

## Brand colours

```
--ink:   #2d2a26   /* primary, wordmark, default mark colour */
--cream: #efece6   /* background, face features */
--peach: #d99d77   /* accent — used in the dark mark */
```

## Usage examples

```html
<!-- Header lockup, inherits text color -->
<img src="/logo/moodtune-lockup.svg" alt="MoodTune" height="32" />

<!-- Or inline so you can colour it with CSS -->
<span style="color: #2d2a26;">
  <!-- paste contents of moodtune-mark.svg here -->
</span>

<!-- Favicon -->
<link rel="icon" type="image/svg+xml" href="/logo/moodtune-mark.svg" />
```

## Font

The wordmark in `moodtune-lockup.svg` uses Inter Tight (weight 700). Add to your `<head>`:

```html
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter+Tight:wght@700&display=swap" rel="stylesheet">
```

If you can't load the font, either:
1. Outline the wordmark to paths in your design tool (Figma → Outline Stroke / Flatten), or
2. Render the wordmark with HTML text next to an `<img>` of `moodtune-mark.svg` and style it yourself.

## Clear space & sizing

- Minimum size: **24 × 24 px** for the mark, **96 px** wide for the lockup. Below those, the smile loses definition — at favicon sizes consider a simpler solid-head variant.
- Clear space: keep ≥ 50% of the mark's height of empty space on all sides.

## Preview

Open `preview.html` in this folder to see all three assets rendered together.
