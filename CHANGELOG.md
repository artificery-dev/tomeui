# Changelog

## Unreleased

- `Select` fills a stated width: given a tight width, the trigger spreads —
  answer at the start, chevron at the far end — instead of both drifting
  toward the centre. Left loose it hugs its widest option, as before.

- Rename the `Swatch.neutral` colour set to `Swatch.ash`: Tailwind's name
  for the grey collided with the palette's semantic `neutral` role, and
  `Palette(neutral: Swatch.neutral)` read like a tautology.
- `Button` holds its centre in a loose `Flexible`: squeezed for width, the
  label yields (and can ellipsize) instead of overflowing. Fixes `Select`
  overflowing its own trigger in a narrow field.
- `TitleBar.claimWindow()`: one call before `runApp` hides the native title
  bar (holding the window until the first frame), so an app needs no direct
  `window_manager` dependency to let a `TitleBar` be the window's chrome.
- Re-export `LucideIcons` from `tomeui.dart`: apps can reach glyphs beyond
  the semantic [Icons] tokens through the single tomeui import, without a
  direct dependency on `lucide_icons_flutter`.

## 0.1.0

- Initial scaffold: re-exports `flutter/widgets.dart` as the toolkit's base.
