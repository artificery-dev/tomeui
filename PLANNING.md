# Widget plan

Categories map to directories under `lib/src/widgets/`, one file per widget,
exported through the category barrel. Sorted by what a widget is _for_, not
what it's made of.

Gray-zone rulings, decided once:

- Overlay-mechanics widgets sort by mechanics: `Tooltip` lives in overlays,
  `Toast` in feedback. Whichever way, stay consistent.
- `Select` splits: the floating surface is overlays' `Popover`; the trigger in
  controls composes it.
- No data-display category (tables, avatars, tags) yet — those prove they're
  toolkit material before getting a home.
- `widgets.dart` collisions: our `Placeholder` deliberately shadows Flutter's
  (the barrel re-exports widgets.dart with `hide Placeholder` once ours
  exists); `Banner` stays Flutter's — ours is `Callout`.
- Styles are the theme→widget bridge: a style class (e.g. `ButtonStyle`)
  holds the resolved values a widget actually paints, and the built-in
  variant + swatch setup is just a mapping that populates those styles —
  semantic color to shade, per brightness (a primary button might wear tone
  500 in light and 400 in dark). `.custom` constructors accept a style
  directly for custom everything.

## foundation — low touch but needed

- [x] `TomeApp` — the application root
- [ ] `Scaffold` — page skeleton: bars, body, insets
- [ ] `Surface` — a themed rectangle everything else sits on
  - Surfaces can take on the appearance of any of our palette colors, defaulting to primary.
  - Variants:
    - [ ] Solid
    - [ ] Soft
    - [ ] Subtle
    - [ ] Outline
    - [ ] Ghost
    - [ ] Placeholder
- [ ] `Placeholder` - An instance of the Placeholder surface type that allows for a single centered child widget. Placeholders expand to fill their parent, but don't force it. (ie, they collapse correctly if they're in a Center widget). Should have a padding constructor option. Shadows Flutter's `Placeholder` (see rulings).

## controls — the user changes something here

- [ ] `Button` — A clickable surface
  - Composed of a Surface and 3 slots: leading, center, and trailing.
  - Button.custom constructor accepts a single child instead of having slots. That constructor is also where you'd pass a custom ButtonStyle (the data class the theme actually resolves for a button — see the style ruling up top.)
- [ ] `TextField`
- [ ] `Checkbox`
- [ ] `Switch`
- [ ] `Slider`
- [ ] `SegmentedControl`
- [ ] `Select` — composes overlays' `Popover`

## text — words, dressed by the type scale

- [ ] Semantic text — `HeadlineText`, `BodyText`, `CaptionText`, `TomeText` (our custom rich text renderer from ~/Projects/AI's ui library, deferred till later).
  - Text widgets derive their color from the surrounding surface's foreground color.
- [ ] `CodeText` — monospace with the copy affordance
- [ ] `KickerText` — small spaced uppercase section label
- [ ] `Link`

## layout — arranging what's already built

- [ ] `Card`
  - Cards have A few slots: Header, Content, Footer in a vertical stack, then bookending that stack is Leading and Trailing. Each slot is spaced apart from the others using the Card's spacing property (the same term Row and Column use, for unity). Each slot takes one nullable spacing override: null inherits the card's spacing, a value is its own — including zero for full bleed header/footer/leading/trailing images/videos, etc.
- [ ] `Divider` — including the fading treatment
- [ ] `Spacing` — spacing tokens as widgets (Flutter's own term: the
      `spacing` parameter on Row/Column). Earns its keep in ListView, Stack,
      and slivers, where no spacing parameter exists.
- [ ] `Inset` — the padding widget that only speaks the Space scale, so
      off-scale padding is unrepresentable rather than merely discouraged:
      `Inset.all(Space.x4)` vs `Padding(padding: EdgeInsets.all(16))`.
- [ ] `BreakpointBuilder` — responsive switching
- [ ] `ContainerSizeBuilder` - Respond to how much space you have available.
- [ ] `ButtonGroup` — a row of buttons that reads as one control
  - Allows making buttons where the exterior corners are rounded but interior corners are square.

## navigation — getting elsewhere, visibly (machinery stays in `routing/`)

- [ ] `TitleBar` — the AppBar stand-in, also acts as the window control container on desktop. (using package:window_manager — dependency added)
- [ ] `Tabs` - Scrollable in-page tabs: switching views, not places.
- [ ] `Dock` — app navigation docked to an edge, one widget for both axes:
      vertical it's the rail, horizontal it's the phone's bottom bar. No
      overflow scrolling; overflow goes to a popover menu.
- [ ] `Breadcrumbs` - Allows customizing the sperator, and allows each item to have an optional icon.

## feedback — the system talks back

- [ ] `Progress` — bar and spinner
- [ ] `StatusChip`
- [ ] `Badge`
- [ ] `Toast`
- [ ] `Callout`
- [ ] `EmptyState`
- [ ] `Skeleton` — loading placeholder

## overlays — above the page, summoned and dismissed

- [ ] `Dialog` — plus the `showDialog` stand-in
- [ ] `Sheet`
- [ ] `Popover` — the floating surface menus and selects share
- [ ] `Menu` — context and dropdown menus, on `Popover`
- [ ] `Tooltip`
- [ ] `Toaster` - Root level widget that manages the display of actual Toast widgets.