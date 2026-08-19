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
- `widgets.dart` collisions: our `Placeholder` and `RadioGroup` deliberately
  shadow Flutter's (the barrel re-exports widgets.dart hiding each one as
  ours lands); `Banner` stays Flutter's — ours is `Callout`. Flutter's
  `RadioGroup` is the registry `RawRadio` talks to; ours is a plain
  inherited value, and the two have nothing to say to each other.
- Words the toolkit says on its own account — the selection menu's verbs, a
  copy affordance's confirmation — are tokens like any other: they live on
  the theme as `Labels`, beside `Icons`. Defaults are English; an app with
  localizations builds a theme per locale rather than passing strings down
  through every widget. Widget-level overrides (`CodeText.copyLabel`) stay
  as escape hatches, null meaning "ask the theme".
- Styles are the theme→widget bridge: a style class (e.g. `ButtonStyle`)
  holds the resolved values a widget actually paints, and the built-in
  variant + swatch setup is just a mapping that populates those styles —
  semantic color to shade, per brightness (a primary button might wear tone
  500 in light and 400 in dark). `.custom` constructors accept a style
  directly for custom everything.

## foundation — low touch but needed

- [x] `TomeApp` — the application root
- [x] `Scaffold` — page skeleton: bars, sidebars, body
  - Five slots: `toolbars` and `statusbars` are *lists* — a shell's chrome
    stacks, and each entry is a full-width band with a hairline between —
    bracketing a row of `leading`, `body`, `trailing`. The bars span the
    window and the sidebars start beneath them, which is what keeps a
    toggle in a toolbar reachable while the sidebar it works is open.
  - Sidebars adapt on one number, `ScaffoldStyle.minBodyWidth` (the
    breakpoint's `compact`): a sidebar that can't leave a body that wide
    beside it is presented as a drawer over the body instead, behind a
    scrim, with Escape and a tap outside to dismiss. Leading has first
    refusal, so trailing gives up its column first. The mode follows the
    *window*, never what's currently showing.
  - Open/shut is the scaffold's own, handed down as `ScaffoldState`
    through `ScaffoldStateProvider`; `ScaffoldSidebarToggle(side)` is that
    as a button, and draws nothing when the slot it points at is empty.
    Each presentation remembers its own answer — closing a drawer isn't a
    statement about the sidebar that comes back when the window widens.
  - Deferred: safe-area insets. Edge-to-edge drawers and a notch want a
    decision about which regions inset and which bleed, and that's its own
    ruling.
- [x] `Surface` — a themed rectangle everything else sits on
  - Surfaces can take on the appearance of any of our palette colors, defaulting to primary.
  - Variants:
    - [x] Solid
    - [x] Soft
    - [x] Subtle
    - [x] Outline
    - [x] Ghost
    - [x] Placeholder
- [x] `Placeholder` - An instance of the Placeholder surface type that allows for a single centered child widget. Placeholders expand to fill their parent, but don't force it. (ie, they collapse correctly if they're in a Center widget). Should have a padding constructor option. Shadows Flutter's `Placeholder` (see rulings).

## controls — the user changes something here

- [x] `Button` — A clickable surface
  - Composed of a Surface and 3 slots: leading, center, and trailing.
  - Button.custom constructor accepts a single child instead of having slots. That constructor is also where you'd pass a custom ButtonStyle (the data class the theme actually resolves for a button — see the style ruling up top.)
- [x] `TextField`
  - Straight on the widgets layer's `EditableText`, dressed as a `Surface`:
    swatch and variant like every other control, a focus ring in the
    swatch's full voice, hover, and a disabled state.
  - Carries its own words — `label` above, `helper` below, and `error`,
    which replaces the helper *and* turns the box, caret, and ring to the
    error swatch. `leading`/`trailing` hold an icon or a small button.
  - The swatch dresses the chrome; what's typed keeps the page's text
    colour. Uncontrolled unless handed a `controller`.
  - Selection is wired end to end, and both presentations come off one
    list (`textSelectionEntries`, which asks `EditableTextState` what it can
    currently do and the theme's `Labels` what to call it):
    - **Touch** wears `TextSelectionHandles` — a circle with one square
      corner, turned toward the character it holds — and a long press
      raises `TextSelectionMenu` as a bar of words above the selection,
      below it when there's no room, clear of the handles either way.
    - **Desktop** draws no handles and puts the same entries under a
      right-click as a menu, rendered by the very `MenuPanel` a dropdown
      `Menu` uses.
    - The menu never takes the keyboard: focusing itself would collapse the
      selection it's about (`ListWalk.autofocus: false`), so the desktop
      list is walked by pointer, as native ones are.
    - `contextMenuBuilder` is the seam — add entries to the default list,
      reorder them, or replace the thing. What's *in* the default list is
      the editor's business and varies by platform (Android shares, Apple
      looks up); how it's presented is ours.
- [x] `Checkbox`
- [x] `RadioGroup` / `RadioButton` — the group is an inherited value the
  buttons read their selected state from, so they need not be siblings.
  Shadows Flutter's `RadioGroup` (see rulings).
- [x] `Switch` — standalone it's a checkbox in another shape; inside a
  `SwitchGroup` it's a radio button in another shape. One constructor: the
  group above decides which, and `value` takes whatever type the choice is
  made of.
- [x] `Slider` — a value picked off a line
  - The switch's dressing rule stretched along a track: the travelled part
    wears the swatch, the rest a neutral soft fill, and the thumb takes the
    active track's foreground so it reads against what it sits on.
  - `divisions` turns the line into stops — the thumb snaps, the arrows
    step one at a time, and the track shows where they are. Continuous, the
    arrows move a hundredth of the range.
  - A tap anywhere on the band takes the thumb there; a slider you can only
    drag is a slider you have to aim at. `onChangeStart`/`onChangeEnd`
    bracket a drag for callers that commit once rather than every frame.
  - Fills the width it's given — how long a slider is says how finely it
    can be read — and takes `SliderStyle.minWidth` where the slot won't say.
- [x] `SegmentedControl` — one of a few, all of them on screen
  - A `RadioGroup` laid side by side in one trough, with an indicator that
    slides to the answer: the switch's track-and-thumb idea widened until
    the thumb has words on it.
  - Segments are equal width, the widest setting it, so the indicator has
    one distance to travel and the control doesn't reflow as the answer
    changes. That falls out of `IntrinsicWidth` over a row of flexible
    children — a row's intrinsic width with all children flexible is the
    widest child times the count — so nothing is measured by hand.
  - One focus stop for the whole control, the way a radio group is: the
    arrows move the answer, Home and End take the ends, disabled segments
    are stepped over, and the row doesn't wrap — falling off a control you
    can see all of would only surprise.
  - A null value is nothing chosen; the indicator fades in place rather
    than travelling to or from nowhere.
- [x] `Select` — composes overlays' `Popover`
  - Trigger is a `Button` in all but name; the list is a popover that
    matches the trigger's width, walks with the arrow keys, and follows the
    trigger when the page scrolls.

## text — words, dressed by the type scale

- [x] Semantic text — one widget per stop on the scale, all sharing
  `SemanticText`: `DisplayText`, `HeadlineText`, `TitleText`, `SubtitleText`,
  `BodyText` (+ `.small`), `LabelText`, `CaptionText`.
  - Text widgets derive their color from the surrounding surface's foreground
    color: no swatch resolves to a style with *no* colour, so it inherits
    what the surface speaks. A `swatch` tints; a `TextEmphasis` grades
    whatever came out, against that same inherited colour.
  - The roles that structure a page (display, headline, title) announce
    themselves as headings.
- [ ] `TomeText` — our custom rich text renderer from ~/Projects/AI's ui
  library, deferred till later.
- [x] `CodeText` — monospace with the copy affordance, in two shapes
  - **Inline** is the chip: a path, an identifier, a command, with the copy
    button beside it.
  - **Block** (`CodeText.block`) is a listing: a card, a numbered gutter
    (`firstLine` for an excerpt, `highlightLines` to call lines out), and
    syntax colour. Long lines scroll sideways under a gutter that stays
    put, or fold with `wrap: true`.
  - Highlighting is `re_highlight` — a pure-Dart port of highlight.js that
    touches only `flutter/painting` and `flutter/rendering`, so the
    widgets-layer-only rule holds. It brings grammars, not colours: the
    scope→swatch mapping lives in `CodeTextResolver`, so keywords are the
    brand, strings read as something that went right, comments step down to
    tertiary, and a palette swap recolours code with everything else.
  - The source is highlighted whole and *then* split into lines — a block
    comment or a triple-quoted string is one construct, and a tokenizer
    shown one line out of it would call the rest of the file code.
  - `CodeSyntax` registers **every grammar `re_highlight` ships**, community
    set included, so naming a language is all a block has to do and the
    aliases (`js`, `yml`, `sh`) answer too. The set is a couple of MB of
    generated Dart that every app linking Tome carries — bought
    deliberately, for never having to think about it. `register` adds or
    overrides one, `unregister` takes one out; a block naming a language
    nobody knows keeps its card, numbers, and copy button and loses only
    the colour.
- [x] `KickerText` — small spaced uppercase section label. Uppercases at
  paint time, so what a screen reader announces stays as written.
- [x] `Link`
  - Wears the swatch's link stop, steps toward contrast under the pointer
    (deeper in light, brighter in dark), and underlines per `LinkUnderline`
    — on hover by default. Takes a `TextRole` so it matches the words it
    sits among.

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
- [x] `Popover` — the floating surface menus and selects share
  - Controlled (`open` + `onDismiss`), anchored, with flip-and-slide
    placement. `barrier: false` makes it an annotation that never takes
    the pointer, which is what `Tooltip` rides on; `takeFocus: false` hands
    the keyboard to content that walks itself, which is what `Select` does.
  - Follows its anchor through every enclosing scrollable, and gives up
    when the anchor scrolls out of view.
- [x] `Menu` — context and dropdown menus, on `Popover`
  - Entries are a sealed `MenuEntry`: `MenuItem` (leading icon, label,
    trailing shortcut hint, optional swatch for a dangerous row),
    `MenuSeparator`, `MenuSection`. A null `onPressed` disables an item, the
    way it does on a `Button`.
  - `ContextMenu` is the same menu summoned by right-click or long press,
    hung off the *point* rather than the widget — which is what
    `Popover.anchorRect` exists for.
  - The keyboard walk `Select` grew is now shared: `ListWalk` owns the
    highlight, the arrows, Home/End, and Enter/Space, and steps over
    separators, section labels, and disabled rows. `ListWalkRow` is the row
    body both widgets sit in.
  - `MenuPanel` is everything a menu *is* except where it floats, which is
    what lets a `TextField`'s desktop selection menu be the same rows in
    the editor's own overlay rather than a second implementation.
- [x] `Tooltip` — the first thing built on `Popover`
- [ ] `Toaster` - Root level widget that manages the display of actual Toast widgets.