## Unreleased

- A `Slider` in a loose slot (a start-aligned column, say) fills the slot. Before, it shrank to the travelled part of its track, so the thumb drew past the end and the rest of the track was missing.
- `NavGroup` takes a `value`: the group is then a place of its own as well as a heading. Pressing the row goes there and shows it selected, the chevron is its own button that folds, and a second press inside the double-tap window folds too. Without a value the row folds as before. The fold key falls back to `value` before the first destination inside. Two new `Labels`, `expand` and `collapse`, name the chevron for screen readers.
- `Scaffold` takes `resizable: true`: each inline sidebar carries a grab strip along its inner edge and drags wider or narrower, between the new `ScaffoldStyle.sidebarMinWidth` and `sidebarMaxWidth` and never into the body's `minBodyWidth`. Widths are the scaffold's own, read through `ScaffoldState.width` and set through `resize`; `onSidebarResized` reports each change and `initialLeadingWidth`/`initialTrailingWidth` hand one back. The drawer decision now counts each side's own width rather than one shared `sidebarWidth`. The strip lights a two-hairline line in `ScaffoldStyle.resizeHandleColor` (the primary swatch by default) while hovered or dragged.
- `NavGroup.entries` can hold further `NavGroup`s, to any depth: each level sits one indent further in and folds on its own, a group holding where you are opens along with every group around it, and the arrow keys walk the nested rows in order.
- `NavGroup` and `NavDestination` take a `leading` widget — an avatar, say — drawn in the icon's square in place of `icon`. `Dock` keeps to `icon`.
- `NavGroup` takes an `id` to remember its fold by, for groups whose contents come and go; without one the fold keys on the first destination inside, nested groups searched too.
- `NavGroup` takes `indent: false` to keep its contents flush with its own row rather than a step in, for sidebars whose groups are sections rather than a tree. Groups inside still step their own contents in; folding, walking, and spacing are unchanged.
- `NavDestination` takes a `menu` of `MenuEntry`s: in a `NavList`, a right-click or long press anywhere on the row opens it at the pointer, without choosing the row. A disabled row or list doesn't answer. `Dock` leaves it out.
- `ContextMenu` takes `enabled`: false ignores the pointer and closes a menu already open, without rebuilding what it wraps.
- A `NavGroup` with `initiallyOpen: false` opens when tapped. Before, the fold fell back to the group's starting state once it was unfolded, so it stayed shut.
- A colorful `Slider`'s thumb is its swatch at full strength, ringed in the page background, instead of the swatch's dark contrast ink, which sank into dark pages.

## 0.3.5

- No library changes; the shared version moves with `tomeui_clickwheel`, whose wheel list can now carry a header that scrolls away with its rows.

# Changelog

## 0.3.4

- An indeterminate `Progress.bar` shuttles its segment between the ends of the track, easing into each turn, instead of parking at one end and jumping back to the other.

## 0.3.3

- The published pubspec no longer names the repository workspace. Pub uploads the file as it is, and a hosted package that declares a workspace broke `dart test` and `dart run` in dependents' workspace members whenever pub rebuilt their package graph.

## 0.3.2

- No library changes; the shared version moves with `tomeui_clickwheel`.

## 0.3.1

- No library changes; the shared version moves with `tomeui_clickwheel`.

## 0.3.0

- Scroll tall dialogs as one card, including their title and actions, while preserving scrim dismissal.

## 0.2.0

- Adopt a shared version and automated releases for all TomeUI libraries.

## 0.1.0

- First pub.dev release, with MIT licensing and complete bundled font notices.
- Keep the skeleton shimmer's base opaque when subtle surfaces are translucent.
- Preserve the text selection menu when a right-click first focuses a field.

- **`tomeui_clickwheel` joins the repository** (in `clickwheel/` beside
  `desktop/`): the click-wheel grammar for devices that are a wheel, five
  buttons, and a small screen. `ClickWheelInput` turns the hardware's keys
  into intents and parses the power button's taps and holds; `WheelList` is
  the wheel-native list, one selection model in a fixed shape for menus and
  a lazy shape for libraries. Its changelog carries the details.
- **Tome no longer depends on `window_manager`.** The window behind
  [TitleBar] now speaks through a seam — `WindowShell`, with a `NoWindow`
  default whose every action is a quiet no-op — and the plugin-backed shell
  moved to a new package, `tomeui_desktop` (in `desktop/` beside this one).
  Embedded targets (flutter-pi and friends) take tomeui alone and never
  ship a desktop plugin.

  **What a desktop app must change:** add `tomeui_desktop` to its
  dependencies and call `installWindowShell()` (from
  `package:tomeui_desktop`) in `main`, *before* `TitleBar.claimWindow()`.
  That's the whole migration — `claimWindow()`, the drag-to-move, the
  double-click maximise, and the window buttons then behave exactly as
  before. An app that skips the install keeps working, but as if off
  desktop: the bar is a bar, the window buttons act on nothing, and
  `claimWindow()` no longer hides the native chrome. Custom shells
  (a test double, another windowing plugin) go the same way: extend
  `WindowShell` and assign `WindowShell.instance`.

- `NavList` stands its rows a small gap apart (`NavListStyle.rowGap`, one
  space step): the rounded selection reads as its own shape rather than a
  band cut out of a solid column. A group's fold carries the gap inside
  itself, so a shut one still takes up nothing at all.
- A closed `Select` shows the chosen option's `leading` beside its label —
  the face at rest matches the face in the list, and the hidden width
  copies measure it too.
- `EmptyState` hugs its words: a card the caller centers in the empty
  room, not a wash over all of it — the inner Center that swallowed every
  slot is gone.
- `NavList` keys a group's fold by its destinations' values instead of the
  `NavGroup` instance: parents rebuild sidebars constantly with fresh entry
  objects, and every fold used to snap back open when they did.
- `Slider` learns an `axis`: `Axis.vertical` stands the line up — the thumb
  travels bottom-to-top, more is up, taps and drags ride the vertical axis,
  and the ticks turn with it.
- Bundle two fonts (licenses alongside): **Recursive**, one variable file
  (MONO, CASL, wght 300-1000, slnt, CRSV) offered to the type scale as
  `Typography.recursive()` — `code` becomes Recursive Mono through the
  MONO axis rather than a second family; and **Symbols Nerd Font Mono**,
  bound glyph-by-glyph as `NerdFontIcons` (10,617 constants, generated by
  `tool/generate_nerd_font_icons.py` from the font's own glyph names).
- `Surface` paints its hairline ring in the foreground instead of laying it
  out: a `Container` folds a decoration border into its padding, so a row
  that gained or lost its ring on hover grew by a hairline and shifted
  every sibling below it. Hover dressing is visual-only now.
- `Select` fills a stated width: given a tight width, the trigger spreads —
  answer at the start, chevron at the far end — instead of both drifting
  toward the center. Left loose it hugs its widest option, as before.

- Rename the `Swatch.neutral` color set to `Swatch.ash`: Tailwind's name
  for the gray collided with the palette's semantic `neutral` role, and
  `Palette(neutral: Swatch.neutral)` read like a tautology.
- `Button` holds its center in a loose `Flexible`: squeezed for width, the
  label yields (and can ellipsize) instead of overflowing. Fixes `Select`
  overflowing its own trigger in a narrow field.
- `TitleBar.claimWindow()`: one call before `runApp` hides the native title
  bar (holding the window until the first frame), so an app needs no direct
  `window_manager` dependency to let a `TitleBar` be the window's chrome.
- Re-export `LucideIcons` from `tomeui.dart`: apps can reach glyphs beyond
  the semantic [Icons] tokens through the single tomeui import, without a
  direct dependency on `lucide_icons_flutter`.

- Initial release of the complete toolkit, built on `flutter/widgets.dart`.
