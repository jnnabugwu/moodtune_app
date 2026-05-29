# MoodTune — App Icon

The lowercase **“m” monogram** on the MoodTune *sunset* gradient. No dot.

## Files

| File | Use |
|---|---|
| `moodtune-icon.svg` | **Master, full-bleed square.** Use this as the source. iOS/Android mask the corners themselves, so the artwork goes edge to edge. |
| `moodtune-icon-rounded.svg` | Same art with an iOS-style squircle (22.37% corner radius) pre-applied. Handy for web, docs, and previews where nothing else rounds it. |
| `icon-1024.png` … `icon-29.png` | Rasterized exports at the standard Apple sizes (1024 / 180 / 120 / 80 / 60 / 40 / 29). Drop straight into an asset catalog. |
| `preview.html` | Open to see the icon at every size on light + dark. |

## Brand values

```
Gradient (sunset, 150°):
  0%    #e9b489   (warm sand)
  48%   #d4885f   (terracotta)
  100%  #b16a8a   (plum)

Glyph:  #efece6   (cream)   ← the “m”
```

## Type

The glyph is **Inter Tight, weight 700**, lowercase `m`, letter-spacing ≈ -0.13em.
The PNGs already have the type baked in, so they need no font.

The two SVGs reference the font by name (`font-family="Inter Tight"`). If you’ll
edit or re-export the SVG, **outline the glyph to a path first** (in Figma:
select → *Outline stroke* / flatten) so it never depends on the font being
installed. Until then, load Inter Tight where the SVG renders:

```html
<link href="https://fonts.googleapis.com/css2?family=Inter+Tight:wght@700&display=swap" rel="stylesheet">
```

## Notes

- **No dot.** Earlier drafts had a small accent dot — removed for simplicity.
- Minimum size is **29px**; the “m” stays legible because it’s a single bold form.
- For Android adaptive icons, place `moodtune-icon.svg` on the foreground layer
  (the gradient already fills the safe zone) or split the gradient onto the
  background layer and the cream “m” onto the foreground.
