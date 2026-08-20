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
- Name collisions with a dependency are settled the same way: our
  `TitleBarStyle` is the style `TitleBar` paints, and `window_manager`'s
  same-named enum (which native bar to draw) is hidden at our import. An
  app that wants the plugin's hides one of the two.
- Words the toolkit says on its own account — the selection menu's verbs, a
  copy affordance's confirmation — are tokens like any other: they live on
  the theme as `Labels`, beside `Icons`. Defaults are English; an app with
  localizations builds a theme per locale rather than passing strings down
  through every widget. Widget-level overrides (`CodeText.copyLabel`) stay
  as escape hatches, null meaning "ask the theme".
- What a popover puts between its panel and the page is a `PopoverBarrier`,
  not a bool: `none` for an annotation nobody can click (a tooltip),
  `blocking` for a page sealed off (a menu, a select), `through` for a press
  that dismisses *and* lands (a menu bar, where clicking the next word
  should open it rather than only closing this one).
- A list's length is not a constant expression, so `assert(items.length > 0)`
  in a constructor quietly makes `const Widget(...)` impossible. Those
  asserts live in `build` instead — `SegmentedControl` still has the old
  form, and should move when it's next touched.
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

- [x] `Card`
  - Cards have A few slots: Header, Content, Footer in a vertical stack, then bookending that stack is Leading and Trailing. Each slot is spaced apart from the others using the Card's spacing property (the same term Row and Column use, for unity). Each slot takes one nullable spacing override: null inherits the card's spacing, a value is its own — including zero for full bleed header/footer/leading/trailing images/videos, etc.
  - Spacing *is* the padding: a slot keeps its step between itself and its
    neighbours and between itself and the card's edge, because those are
    one measurement seen from either side. Where two slots meet the roomier
    of the pair wins, so a full-bleed header runs to the corners without
    dragging the content up with it.
  - The contents are clipped to the corners, tightened by the hairline the
    border takes — a slot that runs to the edge has to be cut by it.
- [x] `Divider` — including the fading treatment
  - `fade` swaps the flat line for a gradient that reaches full strength at
    the middle and dissolves at both ends: a separator that divides without
    drawing a box.
- [x] `Spacing` — spacing tokens as widgets (Flutter's own term: the
      `spacing` parameter on Row/Column). Earns its keep in ListView, Stack,
      and slivers, where no spacing parameter exists.
  - Measures along whichever axis it lands on — an enclosing flex's
    direction, or failing that the way the constraints leave room to grow,
    which is what a list hands its children — and takes nothing across it,
    so a gap never widens what it sits in. `axis` says so outright.
- [x] `Inset` — the padding widget that only speaks the Space scale, so
      off-scale padding is unrepresentable rather than merely discouraged:
      `Inset.all(SpaceStep.x4)` vs `Padding(padding: EdgeInsets.all(16))`.
  - The scale as an enum is `SpaceStep`, since `Space` is the token class
    it resolves against. Directional: `start`/`end`, not left/right.
- [x] `BreakpointBuilder` — responsive switching
  - `Breakpoint` is the band — compact, medium, expanded, large — and the
    theme's three thresholds are the floors of the three above compact.
    `atLeast` compares them, since responsive code asks "roomier than", not
    "equal to".
- [x] `ContainerSizeBuilder` - Respond to how much space you have available.
  - The same `Breakpoint` names, asked of the slot rather than the window:
    a card that has to work in a sidebar and in a page body can't ask a
    media query. An unbounded slot reports the roomiest band — nothing is
    squeezing it, so there's nothing to fold up for.
- [x] `ButtonGroup` — a row of buttons that reads as one control
  - Allows making buttons where the exterior corners are rounded but interior corners are square.
  - The group tells each slot which corners are the run's outside through
    `ButtonGroupSlot`, the way `SwitchGroup` tells a switch what it is; the
    button reshapes itself and passes a `solo` slot down, so a button
    nested inside one isn't shaped by a group it doesn't belong to.
  - The run overlaps its children by a hairline, so where two outlined
    buttons meet the edge is drawn once rather than twice.

## navigation — getting elsewhere, visibly (machinery stays in `routing/`)

- [x] `TitleBar` — the AppBar stand-in, also acts as the window control container on desktop. (using package:window_manager — dependency added)
  - Presentational first: leading slots, title over subtitle, actions. The
    window is the *second* job, and it only wakes on a desktop — dragging
    moves the window, a double-click maximises it, and `windowControls`
    draws the buttons. Windows and Linux get them by default; macOS doesn't,
    since the system draws its own over a hidden native bar.
  - `WindowControls` is public in its own right, for a bar built by hand.
    Every window call is guarded: no window to talk to is a bar that simply
    doesn't move, not an exception — which is also what makes it testable.
  - A centred title is centred on the *bar*, over the slots rather than
    between them, so it doesn't shift when a toggle appears beside it.
- [x] `Tabs` - Scrollable in-page tabs: switching views, not places.
  - Text first: the chosen tab is the page's full voice with a line under
    it, the rest step back to secondary. No box, no fill — a tab is a word.
  - The line is drawn in place rather than slid. Tabs are as wide as their
    words, so there is no single distance for an indicator to travel; the
    trick `SegmentedControl` plays with equal widths doesn't transfer.
  - One focus stop, like a radio group: arrows move the choice, Home and
    End take the ends, disabled tabs are stepped over. The strip scrolls
    sideways rather than squeezing, and the chosen tab is brought into view.
- [x] `Dock` — app navigation docked to an edge, one widget for both axes:
      vertical it's the rail, horizontal it's the phone's bottom bar. No
      overflow scrolling; overflow goes to a popover menu.
  - Counting, not measuring: `DockStyle.itemExtent` says what one place
    takes, so the number that fit falls out of the run's length. What's
    left goes behind *More*, which takes a place of its own and wears the
    chosen state when the answer is one of the ones it's holding.
  - Along a bar the places share the width evenly; down a rail they take a
    place apiece and the rail's full width across.
- [x] `Breadcrumbs` - Allows customizing the sperator, and allows each item to have an optional icon.
  - The last crumb is where you are: full voice, no press, whatever it was
    given. The rest are quiet and light up under the pointer.
  - Crumbs shrink before the trail overflows, so a long name ellipsizes
    instead of pushing the trail off the end.
- [x] `NavList` — the sidebar's list of places, which `Scaffold`'s leading
      slot was always waiting for
  - `NavEntry` is the shared vocabulary: `NavDestination` (also what a
    `Dock` takes, so a rail and a sidebar are one list shown two ways),
    `NavGroup` that folds, `NavHeading`, `NavSeparator`.
  - A group holding where you are opens whatever it was told to do: a
    selected row nobody can see is worse than an open group nobody asked
    for.
  - Walked with `ListWalk`, but not autofocused — a sidebar that took the
    keyboard as the page opened would be a nuisance.
- [x] `MenuBar` — the desktop application menu bar, on `Menu`
  - Needs the page to stay reachable while a panel is down, which is what
    `PopoverBarrier.through` was added for.
  - Once a menu is open the bar is awake: the pointer switches menus, the
    arrows walk them, Escape puts it to sleep. It knows a press is its own
    because the pointer hovered its way there — which makes it desktop
    furniture, and says so in its doc.
  - Left/Right are heard by a keyboard handler rather than a `Shortcuts`
    widget: while a panel is open the keyboard is in the overlay, which is
    nowhere near the bar's own subtree.
- [x] `CommandPalette` — everything the app can do, one keystroke away
  - A field over a walked list, on `ListWalk` and the menu's own row
    dressing. What starts with the query leads, what merely contains it
    follows, and keywords find what a name doesn't.
  - `showCommandPalette` puts it over the page on a `CommandPaletteRoute`
    and returns when it closes. The command runs *after* the palette is
    gone, so what it opens isn't opened behind it.
  - It began on a hand-inserted overlay entry, which cost it a focus scope
    (a scope wrapped over an autofocusing field, inside an entry mounting
    that same frame, catches the overlay mid-mount) and made Escape a
    keyboard handler. A `PopupRoute` gives both away for nothing, and it
    moved onto one when `Dialog` proved the shape.
- [x] `BackButton` — the way back, when there is one
  - Draws nothing at all when the nearest navigator has nothing to pop: a
    back button on the first page is a button that lies. Given an
    `onPressed` of its own it shows regardless — the caller has said what
    back means.
  - No forward twin: a `Navigator` keeps what you came from, not where you
    were going.
- [x] `Pagination` — pages of something long
  - Lives here rather than in a data-display category that doesn't exist
    yet; it's a way to somewhere, and it's built out of `Button`s, so it
    brought no style of its own.
  - The ends are always shown and the middle elides, so the run doesn't
    change width as you walk it. A gap of exactly one page is drawn as that
    page — an ellipsis hiding one number is wider than the number.

## feedback — the system talks back

- [x] `Progress` — bar and spinner
  - One widget, two constructors. A null value is work of unknown length:
    the bar sweeps, the spinner turns, and neither pretends to measure
    anything. A value stops the motion — a measured bar that also swept
    would be saying two things at once.
  - In an unbounded row a bar takes `ProgressStyle.minWidth`, the same rule
    `Slider` follows for the same reason.
- [x] `StatusChip`
  - A soft stadium: a row of solid chips would shout every status at once.
    `dot` gives it the swatch at full voice, which is the loudest thing on
    a quiet chip.
  - Not pressable. A chip that did something would be a `Button` shaped
    like a chip, and should say so.
- [x] `Badge`
  - The split with `StatusChip`: a badge is a *mark on* something — a count
    or a dot riding past its corner — and a chip is a *word about*
    something. If it needs a word, it's a chip.
  - Solid where a chip is soft, since a badge is small and competing with
    whatever it rides on. A count of zero draws nothing: a badge saying
    nothing happened shouldn't be there.
- [x] `Toast`
  - Reports what already happened, so it never asks a question — an action
    undoes or opens, and anything more belongs in a `Dialog`.
  - The swatch colours the *glyph*, not the card. A wall of red is an
    emergency and most toasts aren't.
- [x] `Callout`
  - The page speaking for itself, where a chip speaks for one row. Its
    glyph follows the swatch unless told otherwise, which is what makes it
    readable before it's read — `Callout.glyphFor` is that mapping, and
    `Toast` borrows it.
- [x] `EmptyState`
  - Quiet all through: nothing has gone wrong, so the loudest thing on
    screen is the action. Words wrap at a readable measure rather than
    running the width of the slot.
- [x] `Skeleton` — loading placeholder
  - A shimmering surface, not the striped one `Placeholder` wears: a still
    grey box reads as a thing that has loaded and is grey, while a light
    passing over it reads as a thing on its way.
  - The sheen travels from off one edge to off the other, so the shape
    rests between passes — a sheen that never leaves is a pattern, not a
    passing light.
  - Where the reader asked for less motion it holds still and leans on its
    semantics instead. Decoration is the first thing that should stop.

## overlays — above the page, summoned and dismissed

- [x] `Dialog` — plus the `showDialog` stand-in
  - Slots: an optional icon in a swatch, title, message, free content, and
    the actions in a row that finishes on the right, where the eye does.
  - `DialogRoute` is a `PopupRoute`, not a hand-rolled overlay entry —
    that's what buys the things a modal shouldn't reimplement: the keyboard
    trapped inside, the focus handed back on the way out, the system's back
    gesture understood, and a result returned to whoever pushed it.
    `showDialog` is the stand-in for Material's function of the same name,
    and completes with what popped the route or null.
  - The route lives beside the widget it presents rather than in
    `routing/`: a modal route is how a `Dialog` is *shown*, the way a
    popover is how a menu is shown.
  - A route hangs off the navigator, not off the subtree that pushed it, so
    it carries the theme in scope where it was asked for and puts it back
    on the far side — `dressForOverlay`, which `Popover` had been doing
    inline and now shares. Without it a modal wears whatever theme happens
    to be above the navigator, which is the *app's*, not the section's.
- [x] `Sheet`
  - One widget for both jobs: the phone's bottom sheet and the desktop's
    side sheet, told which by `SheetSide`. The corners round only on the
    edges the sheet isn't against.
  - A bottom sheet wears a grabber and can be thrown back down — far enough
    or fast enough, and it goes. A side sheet has nothing to throw it at
    and doesn't pretend otherwise.
  - `SheetRoute` for the same reasons `DialogRoute` is one. It caps itself
    at `SheetStyle.maxFraction` of the screen: past that it's a page, and
    should be pushed as one.
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
- [x] `Toaster` - Root level widget that manages the display of actual Toast widgets.
      Built with feedback's `Toast`, where it belongs — a manager and the
      thing it manages are one piece of work, and it lives in
      `feedback/toast.dart` beside it.
  - Holds the queue: `maxVisible` show at once and the rest wait their
    turn, since a screen of toasts is a screen nobody reads.
  - The pointer resting on a toast stops its clock. A message that vanished
    while it was being read may as well not have been shown.
  - Its toasts are dressed with `dressForOverlay` like any other floating
    thing, so a section's theme reaches them.