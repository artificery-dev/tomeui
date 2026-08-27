import 'package:tomeui/tomeui.dart';

/// The resolvers, one per widget the theme knows how to dress:
///
/// ```dart
/// theme.widgets.surface.resolve(SemanticSwatch.error, SurfaceVariant.soft)
/// ```
///
/// A resolver is where a widget's [WidgetStyles] configuration meets the
/// theme's palette and tokens and becomes concrete paint. Widgets never
/// choose shades themselves — they ask.
///
/// Bound to the theme at access ([Theme.widgets]) rather than stored on it,
/// since the theme is const data and a resolver has to read across it.
class Widgets {
  const Widgets(this._theme);

  final Theme _theme;

  SurfaceResolver get surface => SurfaceResolver(_theme);

  ScaffoldResolver get scaffold => ScaffoldResolver(_theme);

  CardResolver get card => CardResolver(_theme);

  DividerResolver get divider => DividerResolver(_theme);

  TitleBarResolver get titleBar => TitleBarResolver(_theme);

  TabsResolver get tabs => TabsResolver(_theme);

  DockResolver get dock => DockResolver(_theme);

  BreadcrumbsResolver get breadcrumbs => BreadcrumbsResolver(_theme);

  NavListResolver get navList => NavListResolver(_theme);

  MenuBarResolver get menuBar => MenuBarResolver(_theme);

  CommandPaletteResolver get commandPalette => CommandPaletteResolver(_theme);

  DialogResolver get dialog => DialogResolver(_theme);

  SheetResolver get sheet => SheetResolver(_theme);

  ProgressResolver get progress => ProgressResolver(_theme);

  ChipResolver get chip => ChipResolver(_theme);

  BadgeResolver get badge => BadgeResolver(_theme);

  CalloutResolver get callout => CalloutResolver(_theme);

  EmptyStateResolver get emptyState => EmptyStateResolver(_theme);

  SkeletonResolver get skeleton => SkeletonResolver(_theme);

  ToastResolver get toast => ToastResolver(_theme);

  ButtonResolver get button => ButtonResolver(_theme);

  CheckboxResolver get checkbox => CheckboxResolver(_theme);

  RadioResolver get radio => RadioResolver(_theme);

  /// Trailing underscore: `switch` is a keyword.
  SwitchResolver get switch_ => SwitchResolver(_theme);

  SliderResolver get slider => SliderResolver(_theme);

  SegmentedResolver get segmented => SegmentedResolver(_theme);

  PopoverResolver get popover => PopoverResolver(_theme);

  TooltipResolver get tooltip => TooltipResolver(_theme);

  MenuResolver get menu => MenuResolver(_theme);

  SelectResolver get select => SelectResolver(_theme);

  TextFieldResolver get textField => TextFieldResolver(_theme);

  TextResolver get text => TextResolver(_theme);

  LinkResolver get link => LinkResolver(_theme);

  CodeTextResolver get code => CodeTextResolver(_theme);
}

/// Resolves the theme into the [ProgressStyle] a `Progress` draws.
class ProgressResolver {
  const ProgressResolver(this._theme);

  final Theme _theme;

  /// The swatch at full voice on a groove of its own quietest tint: the
  /// same pairing a slider's travelled and untravelled track use, because
  /// they're the same picture — a length, and how much of it has happened.
  ///
  /// [on] is the surface the progress is being drawn on, where it sits in
  /// one — [SurfaceDress] is how a widget finds that out. A voice the
  /// surface is already speaking says nothing: a primary indicator on a
  /// solid primary button *is* the button, so the pair swaps to what the
  /// surface reads in, its own foreground over a groove of the same at the
  /// weight a divider takes.
  ///
  /// The test is [contrastRatio] against [minVoiceContrast] rather than
  /// equality, because a surface is rarely painting exactly what it
  /// resolved: a hover wash lifts a button's fill a little, which is
  /// enough to make two colours unequal and nowhere near enough to make
  /// one visible on the other.
  /// How far the indicator has to stand from what it's drawn on before it
  /// counts as visible. Measured, not chosen at random: every surface a
  /// progress reads against clears 2.3, and every one it drowns in — the
  /// same fill, and that fill under a hover or pressed wash — comes in
  /// under 1.4.
  static const double minVoiceContrast = 2;

  ProgressStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceStyle? on,
  ]) {
    final palette = _theme.palette;
    final surface = SurfaceResolver(_theme);
    final voice =
        surface.resolve(swatch, SurfaceVariant.solid).fill ?? palette.text;
    // The surface it's drawn on, where that surface is already wearing the
    // voice — a fill-less variant has no colour to drown anything in, and
    // so never matches.
    final ground = on?.fill;
    final drowned =
        ground != null && contrastRatio(voice, ground) < minVoiceContrast
        ? on!
        : null;

    return ProgressStyle(
      track: drowned == null
          ? surface.resolve(swatch, SurfaceVariant.subtle).fill ??
                palette.divider
          : drowned.foreground.withValues(alpha: _theme.opacities.divider),
      indicator: drowned?.foreground ?? voice,
      thickness: _theme.space.x1,
      spinnerSize: _theme.sizes.icon,
      spinnerThickness: _theme.strokes.focus,
      radius: _theme.radii.full,
      minWidth: _theme.sizes.contentNarrow / 4,
      period: _theme.motion.repeat,
    );
  }
}

/// Resolves the theme into the [ChipStyle] a `StatusChip` paints.
class ChipResolver {
  const ChipResolver(this._theme);

  final Theme _theme;

  /// A chip says what state a thing is in, so it wears the meaning at its
  /// quietest — a row of solid chips would shout every status at once, and
  /// a row of soft ones would still be a row of colour before it is a row
  /// of words.
  ChipStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.neutral,
    SurfaceVariant variant = SurfaceVariant.subtle,
  ]) {
    final surface = SurfaceResolver(
      _theme,
    ).resolve(swatch, variant).copyWith(radius: _theme.radii.full);

    return ChipStyle(
      surface: surface,
      textStyle: TextResolver(
        _theme,
      ).resolve(TextRole.label, on: surface.foreground),
      height: _theme.sizes.controlCompact * 0.75,
      padding: EdgeInsets.symmetric(horizontal: _theme.space.x2),
      gap: _theme.space.x1,
      iconSize: _theme.sizes.iconSmall * 0.85,
      dotSize: _theme.space.x2 * 0.75,
    );
  }
}

/// Resolves the theme into the [BadgeStyle] a `Badge` paints.
class BadgeResolver {
  const BadgeResolver(this._theme);

  final Theme _theme;

  /// Solid, unlike a chip: a badge is a small thing competing with whatever
  /// it rides on, and a tint would lose.
  BadgeStyle resolve([SemanticSwatch swatch = SemanticSwatch.error]) {
    final surface = SurfaceResolver(
      _theme,
    ).resolve(swatch, SurfaceVariant.solid).copyWith(radius: _theme.radii.full);

    return BadgeStyle(
      surface: surface,
      textStyle: _theme.typography.caption.copyWith(
        color: surface.foreground,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
      size: _theme.space.x4,
      dotSize: _theme.space.x2,
      padding: EdgeInsets.symmetric(horizontal: _theme.space.x1),
      offset: Offset(_theme.space.x1, -_theme.space.x1),
    );
  }
}

/// Resolves the theme into the [CalloutStyle] a `Callout` paints.
class CalloutResolver {
  const CalloutResolver(this._theme);

  final Theme _theme;

  /// A tinted block in the swatch's own voice — the page telling you
  /// something, in the colour of what kind of something it is.
  CalloutStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.info,
    SurfaceVariant variant = SurfaceVariant.soft,
  ]) {
    final surface = SurfaceResolver(
      _theme,
    ).resolve(swatch, variant).copyWith(radius: _theme.radii.medium);
    final text = TextResolver(_theme);

    return CalloutStyle(
      surface: surface,
      // A callout speaks for the whole page or section, so its heading is
      // a heading — the glyph sized to match, and the message below in the
      // page's own body voice.
      titleStyle: text.resolve(TextRole.subtitle, on: surface.foreground),
      messageStyle: text.resolve(TextRole.body, on: surface.foreground),
      padding: EdgeInsets.all(_theme.space.x4),
      gap: _theme.space.x3,
      textGap: _theme.space.x1,
      actionGap: _theme.space.x2,
      iconSize: _theme.sizes.iconLarge,
      dismissIconSize: _theme.sizes.icon,
    );
  }
}

/// Resolves the theme into the [EmptyStateStyle] an `EmptyState` paints.
class EmptyStateResolver {
  const EmptyStateResolver(this._theme);

  final Theme _theme;

  /// What text has to clear to count as readable on its background — the
  /// WCAG figure, since these are words rather than marks.
  static const double _readable = 4.5;

  /// Quiet all through: nothing has gone wrong, there is simply nothing
  /// here yet, and the loudest thing on screen should be whatever you can
  /// do about it.
  EmptyStateStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.neutral,
    SurfaceVariant variant = SurfaceVariant.subtle,
  ]) {
    final palette = _theme.palette;
    final text = TextResolver(_theme);
    final surface = SurfaceResolver(
      _theme,
    ).resolve(swatch, variant).copyWith(radius: _theme.radii.large);

    // The words keep the page's own voice wherever it still reads against
    // the panel — which is most panels, since the quiet variants barely
    // shift the page. Only a fill loud enough to swallow it hands the job
    // to the surface's foreground: a heading is a heading, not a tint of
    // whatever it happens to be sitting on.
    final fill = surface.fill;
    final on = fill == null || contrastRatio(palette.text, fill) >= _readable
        ? palette.text
        : surface.foreground;

    return EmptyStateStyle(
      surface: surface,
      titleStyle: text.resolve(TextRole.title, on: on),
      messageStyle: text.resolve(
        TextRole.body,
        emphasis: TextEmphasis.secondary,
        on: on,
      ),
      glyph: on.withValues(alpha: _theme.opacities.tertiary),
      iconSize: _theme.sizes.iconExtraLarge,
      gap: _theme.space.x3,
      actionGap: _theme.space.x6,
      maxWidth: _theme.sizes.contentNarrow / 2,
      padding: EdgeInsets.all(_theme.space.x6),
    );
  }
}

/// Resolves the theme into the [SkeletonStyle] a `Skeleton` paints.
class SkeletonResolver {
  const SkeletonResolver(this._theme);

  final Theme _theme;

  /// A neutral shape with a light passing over it: the fill is the quietest
  /// surface the palette has, and the sheen is the page's own foreground at
  /// the faintest opacity it uses — bright enough to travel, too faint to
  /// read as content.
  SkeletonStyle resolve() {
    final palette = _theme.palette;

    return SkeletonStyle(
      fill:
          SurfaceResolver(
            _theme,
          ).resolve(SemanticSwatch.neutral, SurfaceVariant.subtle).fill ??
          palette.divider,
      sheen: palette.text.withValues(alpha: _theme.opacities.hover),
      radius: _theme.radii.small,
      lineHeight: _theme.space.x3,
      lineGap: _theme.space.x2,
      lastLineFraction: 0.6,
      period: _theme.motion.repeat,
    );
  }
}

/// Resolves the theme into the [ToastStyle] a `Toast` paints.
class ToastResolver {
  const ToastResolver(this._theme);

  final Theme _theme;

  /// The dialog's surface at toast size, under the same high shadow: a
  /// toast floats over everything, and the swatch it's given colours its
  /// glyph rather than the whole card — a wall of red is an emergency, and
  /// most toasts aren't.
  ToastStyle resolve() {
    final palette = _theme.palette;

    return ToastStyle(
      surface: SurfaceStyle(
        foreground: palette.text,
        fill: palette.surface,
        border: palette.divider,
        radius: _theme.radii.medium,
      ),
      messageStyle: TextResolver(
        _theme,
      ).resolve(TextRole.body, on: palette.text),
      padding: EdgeInsets.all(_theme.space.x3),
      gap: _theme.space.x3,
      iconSize: _theme.sizes.icon,
      width: _theme.sizes.contentNarrow * 0.5625,
      stackGap: _theme.space.x2,
      margin: EdgeInsets.all(_theme.space.x4),
      position: ToastPosition.bottomTrailing,
      life: const Duration(seconds: 4),
      maxVisible: 3,
      shadow: _theme.shadows.high,
    );
  }
}

/// Resolves the theme into the [DialogStyle] a `Dialog` paints.
class DialogResolver {
  const DialogResolver(this._theme);

  final Theme _theme;

  /// A dialog is the surface a card and a menu share, lifted to the top of
  /// the stack: the palette's own [Palette.surface] under the highest
  /// shadow, over a scrim that darkens whatever it interrupted.
  DialogStyle resolve() {
    final palette = _theme.palette;
    final text = TextResolver(_theme);

    return DialogStyle(
      surface: SurfaceStyle(
        foreground: palette.text,
        fill: palette.surface,
        radius: _theme.radii.large,
      ),
      titleStyle: text.resolve(TextRole.title, on: palette.text),
      messageStyle: text.resolve(
        TextRole.body,
        emphasis: TextEmphasis.secondary,
        on: palette.text,
      ),
      width: _theme.sizes.dialog,
      padding: EdgeInsets.all(_theme.space.x6),
      gap: _theme.space.x4,
      actionGap: _theme.space.x2,
      margin: _theme.space.x6,
      // Darkens in both brightnesses: a scrim is a shadow over the page,
      // and a pale one in dark mode would be a light leak instead.
      scrim: palette.neutral.s950.withValues(alpha: _theme.opacities.scrim),
      shadow: _theme.shadows.high,
    );
  }
}

/// Resolves the theme into the [SheetStyle] a `Sheet` paints.
class SheetResolver {
  const SheetResolver(this._theme);

  final Theme _theme;

  /// The dialog's surface, come in from an edge: the same fill and shadow,
  /// with the corners rounded only where the sheet isn't against the
  /// screen. A side sheet is as wide as a sidebar, since that's what it
  /// stands in for when there's no room to dock one.
  SheetStyle resolve() {
    final palette = _theme.palette;
    final dialog = DialogResolver(_theme).resolve();

    return SheetStyle(
      surface: SurfaceStyle(
        foreground: palette.text,
        fill: palette.surface,
        radius: _theme.radii.none,
      ),
      titleStyle: dialog.titleStyle,
      padding: EdgeInsets.all(_theme.space.x6),
      gap: _theme.space.x4,
      radius: _theme.radii.extraLarge.topLeft,
      size: _theme.sizes.dialog * 0.8,
      maxFraction: 0.9,
      grabber: palette.divider,
      grabberSize: Size(_theme.space.x8, _theme.space.x1),
      scrim: dialog.scrim,
      shadow: dialog.shadow,
    );
  }
}

/// Resolves the theme into the [NavListStyle] a `NavList` paints.
class NavListResolver {
  const NavListResolver(this._theme);

  final Theme _theme;

  /// A sidebar list is quiet until it isn't: rows are secondary text on
  /// nothing at all, and the row you're on wears [swatch] softly — the same
  /// treatment a `Dock`'s indicator pill uses, so the rail and the sidebar
  /// agree about what "here" looks like.
  NavListStyle resolve([SemanticSwatch swatch = SemanticSwatch.primary]) {
    final palette = _theme.palette;
    final opacities = _theme.opacities;
    final text = TextResolver(_theme);
    final selected = SurfaceResolver(
      _theme,
    ).resolve(swatch, SurfaceVariant.soft).copyWith(radius: _theme.radii.small);

    return NavListStyle(
      selected: selected,
      selectedStyle: text.resolve(TextRole.label, on: selected.foreground),
      textStyle: text.resolve(
        TextRole.body,
        emphasis: TextEmphasis.secondary,
        on: palette.text,
      ),
      headingStyle: text.resolve(
        TextRole.caption,
        emphasis: TextEmphasis.tertiary,
        on: palette.text,
      ),
      separator: palette.divider,
      rowHeight: _theme.sizes.controlCompact,
      padding: EdgeInsets.symmetric(horizontal: _theme.space.x2),
      gap: _theme.space.x2,
      indent: _theme.space.x5,
      iconSize: _theme.sizes.iconSmall,
      radius: _theme.radii.small,
      headingPadding: EdgeInsets.fromLTRB(
        _theme.space.x2,
        _theme.space.x3,
        _theme.space.x2,
        _theme.space.x1,
      ),
      ring:
          SurfaceResolver(_theme).resolve(swatch, SurfaceVariant.solid).fill ??
          palette.text,
      highlight: palette.text.withValues(alpha: opacities.hover),
      hover: palette.text.withValues(alpha: opacities.hover),
      pressed: palette.text.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [MenuBarStyle] a `MenuBar` paints.
class MenuBarResolver {
  const MenuBarResolver(this._theme);

  final Theme _theme;

  /// The bar is words on the chrome it sits in — no fill of its own, since
  /// it lives in a title bar that already has one — and a trigger holding
  /// an open panel stays lit while you read it.
  MenuBarStyle resolve() {
    final palette = _theme.palette;
    final opacities = _theme.opacities;

    return MenuBarStyle(
      menu: MenuResolver(_theme).resolve(),
      textStyle: TextResolver(_theme).resolve(TextRole.body, on: palette.text),
      height: _theme.sizes.controlCompact,
      padding: EdgeInsets.symmetric(
        horizontal: _theme.space.x2,
        vertical: _theme.space.x1,
      ),
      gap: _theme.space.x1,
      radius: _theme.radii.small,
      ring:
          SurfaceResolver(
            _theme,
          ).resolve(SemanticSwatch.primary, SurfaceVariant.solid).fill ??
          palette.text,
      open: palette.text.withValues(alpha: opacities.pressed),
      hover: palette.text.withValues(alpha: opacities.hover),
      pressed: palette.text.withValues(alpha: opacities.pressed),
    );
  }
}

/// Resolves the theme into the [CommandPaletteStyle] a `CommandPalette`
/// paints.
class CommandPaletteResolver {
  const CommandPaletteResolver(this._theme);

  final Theme _theme;

  /// The palette is a menu with a field on top: the panel is the surface
  /// menus and popovers share, the rows are menu rows, and the field is a
  /// text field with its box taken off — the panel is the box.
  CommandPaletteStyle resolve() {
    final palette = _theme.palette;
    final field = TextFieldResolver(_theme).resolve();

    return CommandPaletteStyle(
      surface: SurfaceStyle(
        foreground: palette.text,
        fill: palette.surface,
        radius: _theme.radii.large,
      ),
      field: field.copyWith(
        surface: SurfaceStyle(
          foreground: palette.text,
          radius: _theme.radii.none,
        ),
      ),
      menu: MenuResolver(_theme).resolve(),
      emptyStyle: TextResolver(_theme).resolve(
        TextRole.body,
        emphasis: TextEmphasis.tertiary,
        on: palette.text,
      ),
      hintStyle: TextResolver(_theme).resolve(
        TextRole.caption,
        emphasis: TextEmphasis.tertiary,
        on: palette.text,
      ),
      width: _theme.sizes.contentNarrow,
      maxHeight: 400,
      padding: EdgeInsets.all(_theme.space.x2),
      topInset: _theme.space.x16 + _theme.space.x8,
      // Darkens in both brightnesses: a scrim is a shadow over the page.
      scrim: palette.neutral.s950.withValues(alpha: _theme.opacities.scrim),
      shadow: _theme.shadows.high,
    );
  }
}

/// Resolves the theme into the [TitleBarStyle] a `TitleBar` paints.
class TitleBarResolver {
  const TitleBarResolver(this._theme);

  final Theme _theme;

  /// A title bar is the scaffold's chrome by another name: the same fill
  /// the bars and sidebars wear, so a bar built by hand and a bar the
  /// shell drew are the one surface.
  ///
  /// The window buttons take a wash of the foreground, except closing —
  /// which answers in [SemanticSwatch.error], the way every desktop draws
  /// the one button that throws work away.
  TitleBarStyle resolve() {
    final palette = _theme.palette;
    final opacities = _theme.opacities;
    final text = TextResolver(_theme);
    final close = SurfaceResolver(
      _theme,
    ).resolve(SemanticSwatch.error, SurfaceVariant.solid).fill;

    return TitleBarStyle(
      surface: SurfaceStyle(
        foreground: palette.text,
        fill: palette.surface,
        radius: _theme.radii.none,
      ),
      height: _theme.sizes.control + _theme.space.x2,
      padding: EdgeInsets.symmetric(horizontal: _theme.space.x2),
      gap: _theme.space.x2,
      titleStyle: text.resolve(TextRole.label, on: palette.text),
      subtitleStyle: text.resolve(
        TextRole.caption,
        emphasis: TextEmphasis.secondary,
        on: palette.text,
      ),
      controlSize: _theme.sizes.controlCompact,
      controlIconSize: _theme.sizes.iconSmall * 0.8,
      glyphStroke: _theme.strokes.hairline,
      controlRing:
          SurfaceResolver(
            _theme,
          ).resolve(SemanticSwatch.primary, SurfaceVariant.solid).fill ??
          palette.text,
      controlHover: palette.text.withValues(alpha: opacities.hover),
      controlPressed: palette.text.withValues(alpha: opacities.pressed),
      closeHover: close,
      closePressed: close,
    );
  }
}

/// Resolves the theme into the [TabsStyle] a `Tabs` strip paints.
class TabsResolver {
  const TabsResolver(this._theme);

  final Theme _theme;

  /// Every tab is a surface: the quietest one there is for the ways to a
  /// page, and the swatch at full voice for the page you're on. The pairing
  /// a `SegmentedControl` uses, for the same reason — the chosen one is an
  /// answer, and the rest are offers.
  TabsStyle resolve([SemanticSwatch swatch = SemanticSwatch.primary]) {
    final palette = _theme.palette;
    final opacities = _theme.opacities;
    final text = TextResolver(_theme);
    final surfaces = SurfaceResolver(_theme);
    // Rounded where it meets the air, square where it meets the pane it
    // opens onto — which is what makes a tab read as a tab rather than as
    // a button that happens to be selected.
    final radius = BorderRadius.only(
      topLeft: _theme.radii.medium.topLeft,
      topRight: _theme.radii.medium.topRight,
    );
    final selected = surfaces
        .resolve(swatch, SurfaceVariant.solid)
        .copyWith(radius: radius);
    final unselected = surfaces
        .resolve(SemanticSwatch.neutral, SurfaceVariant.subtle)
        .copyWith(radius: radius);
    final voice = selected.fill ?? palette.text;

    return TabsStyle(
      selectedStyle: text.resolve(TextRole.label, on: selected.foreground),
      unselectedStyle: text.resolve(
        TextRole.label,
        emphasis: TextEmphasis.secondary,
        on: palette.text,
      ),
      selected: selected,
      unselected: unselected,
      tabGap: 0,
      closeSize: _theme.sizes.iconLarge,
      closeIconSize: _theme.sizes.iconSmall * 0.85,
      height: _theme.sizes.control,
      padding: EdgeInsets.symmetric(horizontal: _theme.space.x3),
      gap: _theme.space.x2,
      iconSize: _theme.sizes.iconSmall,
      radius: radius,
      ring: voice,
      hover: palette.text.withValues(alpha: opacities.hover),
      pressed: palette.text.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [DockStyle] a `Dock` paints.
class DockResolver {
  const DockResolver(this._theme);

  final Theme _theme;

  /// The dock is chrome — the scaffold's own fill — and the chosen
  /// destination wears the swatch as a soft pill behind its icon, with the
  /// label beneath in the page's full voice. That way the answer reads at a
  /// glance without the dock turning into a row of buttons.
  DockStyle resolve([SemanticSwatch swatch = SemanticSwatch.primary]) {
    final palette = _theme.palette;
    final opacities = _theme.opacities;
    final text = TextResolver(_theme);
    final indicator = SurfaceResolver(
      _theme,
    ).resolve(swatch, SurfaceVariant.soft).copyWith(radius: _theme.radii.full);

    return DockStyle(
      surface: SurfaceStyle(
        foreground: palette.text,
        fill: palette.surface,
        radius: _theme.radii.none,
      ),
      indicator: indicator,
      selectedStyle: text.resolve(TextRole.caption, on: palette.text),
      unselectedStyle: text.resolve(
        TextRole.caption,
        emphasis: TextEmphasis.secondary,
        on: palette.text,
      ),
      itemExtent: 80,
      thickness: _theme.sizes.touchTarget + _theme.space.x4,
      padding: EdgeInsets.all(_theme.space.x2),
      gap: _theme.space.x1,
      iconSize: _theme.sizes.icon,
      indicatorPadding: EdgeInsets.symmetric(
        horizontal: _theme.space.x4,
        vertical: _theme.space.x1,
      ),
      ring:
          SurfaceResolver(_theme).resolve(swatch, SurfaceVariant.solid).fill ??
          palette.text,
      hover: palette.text.withValues(alpha: opacities.hover),
      pressed: palette.text.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [BreadcrumbsStyle] a `Breadcrumbs` trail
/// paints.
class BreadcrumbsResolver {
  const BreadcrumbsResolver(this._theme);

  final Theme _theme;

  /// A trail is small print: the way back is secondary, where you are is
  /// the full voice, and the separators speak in the same breath as the
  /// crumbs they part — a chevron at the palette's divider weight is a
  /// line drawn *between* things, and disappears into the page it's on.
  BreadcrumbsStyle resolve() {
    final palette = _theme.palette;
    final opacities = _theme.opacities;
    final text = TextResolver(_theme);
    final behind = text.resolve(
      TextRole.caption,
      emphasis: TextEmphasis.secondary,
      on: palette.text,
    );

    return BreadcrumbsStyle(
      textStyle: behind,
      currentStyle: text.resolve(TextRole.caption, on: palette.text),
      separator: behind.color ?? palette.text,
      separatorSize: _theme.sizes.iconSmall,
      gap: _theme.space.x1,
      iconSize: _theme.sizes.iconSmall,
      padding: EdgeInsets.symmetric(
        horizontal: _theme.space.x2,
        vertical: _theme.space.x1,
      ),
      iconGap: _theme.space.x1,
      radius: _theme.radii.small,
      ring:
          SurfaceResolver(
            _theme,
          ).resolve(SemanticSwatch.primary, SurfaceVariant.solid).fill ??
          palette.text,
      hover: palette.text.withValues(alpha: opacities.hover),
      pressed: palette.text.withValues(alpha: opacities.pressed),
    );
  }
}

/// Resolves the theme into the [CardStyle] a `Card` paints.
class CardResolver {
  const CardResolver(this._theme);

  final Theme _theme;

  /// A card is a [Surface] that holds content rather than acting: it wears
  /// the swatch quietly, and its slots keep [Space.x4] around themselves —
  /// the same step the padding inside a panel uses, so a card in a column
  /// of cards breathes evenly.
  CardStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.neutral,
    SurfaceVariant variant = SurfaceVariant.outline,
  ]) => CardStyle(
    surface: SurfaceResolver(
      _theme,
    ).resolve(swatch, variant).copyWith(radius: _theme.radii.large),
    spacing: _theme.space.x4,
  );
}

/// Resolves the theme into the [DividerStyle] a `Divider` draws.
class DividerResolver {
  const DividerResolver(this._theme);

  final Theme _theme;

  /// The palette's own [Palette.divider] at a [Strokes.hairline] — the same
  /// line the scaffold draws between its regions, so a rule inside a page
  /// and a rule around it are the one weight.
  DividerStyle resolve() => DividerStyle(
    color: _theme.palette.divider,
    thickness: _theme.strokes.hairline,
  );
}

/// Resolves the theme into the [ScaffoldStyle] a `Scaffold` paints.
class ScaffoldResolver {
  const ScaffoldResolver(this._theme);

  final Theme _theme;

  /// The shell's chrome: bars and sidebars on the palette's
  /// [Palette.surface] — the colour cards, fields, and menus share — one
  /// step off the page the body keeps, with a hairline where two regions
  /// meet.
  ///
  /// [ScaffoldStyle.minBodyWidth] is [Breakpoints.compact]: a body squeezed
  /// below the width we call a phone has stopped being a body with a
  /// sidebar beside it. With the default 280pt sidebar that puts one
  /// sidebar inline from 900 and both from 1180 — [Breakpoints.medium] and
  /// very nearly [Breakpoints.expanded], which is what those numbers were
  /// named for.
  ScaffoldStyle resolve() {
    final palette = _theme.palette;
    final chrome = SurfaceStyle(
      foreground: palette.text,
      fill: palette.surface,
      radius: _theme.radii.none,
    );
    return ScaffoldStyle(
      bar: chrome,
      sidebar: chrome,
      divider: palette.divider,
      dividerThickness: _theme.strokes.hairline,
      // Darkens in both brightnesses: a scrim is a shadow over the page,
      // and a pale one in dark mode would be a light leak instead.
      scrim: palette.neutral.s950.withValues(alpha: _theme.opacities.scrim),
      barPadding: EdgeInsets.symmetric(horizontal: _theme.space.x2),
      sidebarWidth: 280,
      drawerWidth: 320,
      minBodyWidth: _theme.breakpoints.compact,
      drawerShadow: _theme.shadows.high,
    );
  }
}

/// Resolves the theme into the [TextFieldStyle] a `TextField` paints.
class TextFieldResolver {
  const TextFieldResolver(this._theme);

  final Theme _theme;

  /// The concrete paint for a field wearing [swatch] in [variant]'s
  /// treatment — [SurfaceVariant.outline] by default, since a field is a
  /// space to fill in rather than a surface to read.
  ///
  /// The swatch dresses the *chrome*: border, caret, ring, selection. What's
  /// typed stays the palette's text colour, because the content of a field
  /// is content — a blue-tinted email address would be a lie about what the
  /// colour means. A field showing an error resolves against
  /// [SemanticSwatch.error] instead, which is how the whole box turns at
  /// once.
  TextFieldStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceVariant variant = SurfaceVariant.outline,
  ]) {
    final palette = _theme.palette;
    final opacities = _theme.opacities;
    final text = TextResolver(_theme);
    final surface = SurfaceResolver(_theme).resolve(swatch, variant);
    final voice =
        SurfaceResolver(_theme).resolve(swatch, SurfaceVariant.solid).fill ??
        surface.foreground;

    return TextFieldStyle(
      surface: surface,
      textStyle: text.resolve(TextRole.body, on: palette.text),
      placeholderStyle: text.resolve(
        TextRole.body,
        emphasis: TextEmphasis.tertiary,
        on: palette.text,
      ),
      labelStyle: text.resolve(TextRole.label, on: palette.text),
      helperStyle: text.resolve(
        TextRole.caption,
        emphasis: TextEmphasis.secondary,
        on: palette.text,
      ),
      errorStyle: text.resolve(TextRole.caption, swatch: SemanticSwatch.error),
      ring: voice,
      cursor: voice,
      // Selected text keeps its own colour, so the wash behind it has to be
      // light enough to read through.
      selection: voice.withValues(alpha: opacities.focus * 2),
      height: _theme.sizes.control,
      padding: EdgeInsets.symmetric(horizontal: _theme.space.x3),
      multilinePadding: EdgeInsets.symmetric(
        horizontal: _theme.space.x3,
        vertical: _theme.space.x2,
      ),
      gap: _theme.space.x2,
      labelGap: _theme.space.x1,
      helperGap: _theme.space.x1,
      iconSize: _theme.sizes.icon,
      // Grips are drawn at the large icon size: they're dragged with a
      // fingertip, not clicked with a cursor.
      handleSize: _theme.sizes.iconLarge,
      hover: surface.foreground.withValues(alpha: opacities.hover),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [TextStyle] a semantic text widget paints.
///
/// The one resolver that may return a style with no colour at all: text
/// without a swatch of its own inherits whatever the enclosing [Surface]
/// speaks, which is how a label reads correctly on a solid button and in a
/// paragraph without either one being told a colour.
class TextResolver {
  const TextResolver(this._theme);

  final Theme _theme;

  /// The type for [role], tinted by [swatch] and graded by [emphasis].
  ///
  /// [on] is the colour the text would otherwise inherit — the enclosing
  /// surface's foreground. It exists so emphasis grades against *that*
  /// rather than against the page's text colour, which is the difference
  /// between a secondary caption on a solid primary button reading as dimmed
  /// white and reading as dimmed black.
  TextStyle resolve(
    TextRole role, {
    SemanticSwatch? swatch,
    TextEmphasis emphasis = TextEmphasis.full,
    Color? on,
  }) {
    final type = _theme.typography;
    final base = switch (role) {
      TextRole.display => type.display,
      TextRole.headline => type.headline,
      TextRole.title => type.title,
      TextRole.subtitle => type.subtitle,
      TextRole.body => type.body,
      TextRole.bodySmall => type.bodySmall,
      TextRole.label => type.label,
      TextRole.caption => type.caption,
      TextRole.code => type.code,
      // A kicker is the label style, standing further apart and a shade
      // firmer — the shape small uppercase text needs to stay readable.
      TextRole.kicker => type.label.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing:
            (type.label.letterSpacing ?? 0) + _theme.styles.text.kickerTracking,
      ),
    };
    final colour = tint(swatch: swatch, emphasis: emphasis, on: on);
    return colour == null ? base : base.copyWith(color: colour);
  }

  /// The colour text wears, or null for "inherit what the surface says".
  ///
  /// A swatch tints; emphasis then grades whatever came out — the tint, or
  /// [on], or the palette's text colour when there is neither.
  Color? tint({
    SemanticSwatch? swatch,
    TextEmphasis emphasis = TextEmphasis.full,
    Color? on,
  }) {
    final palette = _theme.palette;
    var colour = swatch != null
        ? _theme.styles.text.tinted.on(palette.of(swatch), palette.brightness)
        : on;
    if (emphasis == TextEmphasis.full) return colour;

    final opacities = _theme.opacities;
    final step = switch (emphasis) {
      TextEmphasis.full => 1.0,
      TextEmphasis.secondary => opacities.secondary,
      TextEmphasis.tertiary => opacities.tertiary,
      TextEmphasis.disabled => opacities.disabled,
    };
    colour ??= palette.text;
    // Scales the alpha already there rather than replacing it, so grading
    // an already-translucent foreground keeps getting quieter.
    return colour.withValues(alpha: colour.a * step);
  }
}

/// Resolves the theme into the [LinkStyle] a `Link` paints.
class LinkResolver {
  const LinkResolver(this._theme);

  final Theme _theme;

  /// A link wears [swatch] at the configured link stop, on [role]'s type —
  /// it lives inside running text, so it takes the size of whatever it sits
  /// in rather than a size of its own. Hovering brightens it a step toward
  /// the swatch's full voice.
  LinkStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    TextRole role = TextRole.body,
  ]) {
    final palette = _theme.palette;
    final styles = _theme.styles.text;
    final worn = palette.of(swatch);
    final base = TextResolver(_theme).resolve(role);
    final rest = styles.link.on(worn, palette.brightness);
    // Under the pointer the link steps along the ramp toward contrast,
    // which is a *deeper* stop in light and a brighter one in dark.
    final lit = styles.linkHover.on(worn, palette.brightness);
    return LinkStyle(
      textStyle: base.copyWith(color: rest),
      hovered: base.copyWith(color: lit),
      ring:
          SurfaceResolver(_theme).resolve(swatch, SurfaceVariant.solid).fill ??
          rest,
      ringRadius: _theme.radii.small,
      underline: styles.underline,
      gap: _theme.space.x1,
      iconSize: _theme.sizes.iconSmall,
      disabledOpacity: _theme.opacities.disabled,
    );
  }
}

/// Resolves the theme into the [CodeTextStyle] a `CodeText` paints.
class CodeTextResolver {
  const CodeTextResolver(this._theme);

  final Theme _theme;

  /// Code sits on a [SurfaceVariant.subtle] chip in [swatch] — neutral by
  /// default, since a path or an identifier is not a status. The copy
  /// button's washes are the chip's own foreground, the way every other
  /// control's are.
  ///
  /// A block gets the same colours on a larger footing: the medium radius
  /// and a hairline, because a block is a card rather than a chip, and a
  /// gutter dimmed to the tertiary step so the numbers stay countable
  /// without competing with the code.
  CodeTextStyle resolve([SemanticSwatch swatch = SemanticSwatch.neutral]) {
    final surface = SurfaceResolver(_theme)
        .resolve(swatch, SurfaceVariant.subtle)
        .copyWith(radius: _theme.radii.small);
    final opacities = _theme.opacities;
    final palette = _theme.palette;
    final text = TextResolver(_theme);
    final mono = text.resolve(TextRole.code);
    return CodeTextStyle(
      surface: surface,
      textStyle: mono,
      ring:
          SurfaceResolver(_theme).resolve(swatch, SurfaceVariant.solid).fill ??
          surface.foreground,
      padding: EdgeInsets.symmetric(
        horizontal: _theme.space.x2,
        vertical: _theme.space.x1,
      ),
      gap: _theme.space.x2,
      iconSize: _theme.sizes.iconSmall,
      hover: surface.foreground.withValues(alpha: opacities.hover),
      pressed: surface.foreground.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
      blockSurface: surface.copyWith(
        border: palette.divider,
        radius: _theme.radii.medium,
      ),
      blockPadding: EdgeInsets.symmetric(
        horizontal: _theme.space.x4,
        vertical: _theme.space.x3,
      ),
      syntax: _syntax(mono),
      gutterStyle: mono.copyWith(
        color: palette.text.withValues(alpha: opacities.tertiary),
      ),
      gutterGap: _theme.space.x4,
      gutterDivider: palette.divider,
      gutterDividerThickness: _theme.strokes.hairline,
      lineHighlight: palette.text.withValues(alpha: opacities.hover),
    );
  }

  /// What each syntax scope wears, in the palette's own voice.
  ///
  /// The mapping is semantic before it is decorative: keywords are the
  /// brand, strings read as something that went right, comments are text
  /// stepped down to tertiary, and a diff's deletions wear the error
  /// swatch — so a theme that swaps its palette gets a coherent code
  /// colouring for free instead of a scheme borrowed from somewhere else.
  ///
  /// Keys are highlight.js v11 scope names. Scopes with no entry keep the
  /// plain monospace, which is what makes an unregistered language degrade
  /// to readable rather than to wrong.
  Map<String, TextStyle> _syntax(TextStyle mono) {
    final text = TextResolver(_theme);
    TextStyle wear(SemanticSwatch swatch) =>
        mono.copyWith(color: text.tint(swatch: swatch));
    TextStyle graded(TextEmphasis emphasis) => mono.copyWith(
      color: text.tint(emphasis: emphasis, on: _theme.palette.text),
    );

    final brand = wear(SemanticSwatch.primary);
    final name = wear(SemanticSwatch.accent);
    final literal = wear(SemanticSwatch.success);
    final detail = wear(SemanticSwatch.info);
    final aside = wear(SemanticSwatch.warning);
    final quiet = graded(TextEmphasis.tertiary);

    return {
      // The language's own words.
      'keyword': brand,
      'built_in': brand,
      'type': brand,
      'literal': brand,
      'operator': graded(TextEmphasis.secondary),
      'punctuation': graded(TextEmphasis.secondary),
      // What the author named.
      'title': name,
      'title.class': name,
      'title.class.inherited': name,
      'title.function': name,
      'title.function.invoke': name,
      'section': name,
      'symbol': name,
      'bullet': name,
      'tag': brand,
      'name': brand,
      'selector-tag': brand,
      // Values.
      'string': literal,
      'regexp': literal,
      'char.escape': literal,
      'subst': mono,
      'addition': literal,
      'number': detail,
      'variable': detail,
      'variable.language': detail,
      'variable.constant': detail,
      'template-variable': detail,
      'params': detail,
      'attr': detail,
      'attribute': detail,
      'property': detail,
      'selector-attr': detail,
      'selector-class': detail,
      'selector-id': detail,
      'selector-pseudo': detail,
      'link': detail.copyWith(decoration: TextDecoration.underline),
      // Beside the code rather than in it.
      'comment': quiet,
      'quote': quiet,
      'meta': aside,
      'meta.prompt': aside,
      'meta keyword': aside,
      'meta string': literal,
      'doctag': aside,
      'deletion': wear(SemanticSwatch.error),
      // Markup, where the scope is a shape rather than a colour.
      'strong': mono.copyWith(fontWeight: FontWeight.w700),
      'emphasis': mono.copyWith(fontStyle: FontStyle.italic),
      'formula': quiet,
      'code': mono,
    };
  }
}

/// Resolves the theme into the [SelectStyle] a `Select` paints.
class SelectResolver {
  const SelectResolver(this._theme);

  final Theme _theme;

  /// The trigger is a button wearing [variant] — [SurfaceVariant.outline]
  /// by default, since a select is a field to fill in rather than an action
  /// to take. The list's rows highlight in the neutral foreground and mark
  /// the current answer in the swatch.
  SelectStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceVariant variant = SurfaceVariant.outline,
  ]) {
    final palette = _theme.palette;
    final opacities = _theme.opacities;
    return SelectStyle(
      trigger: ButtonResolver(_theme).resolve(swatch, variant),
      placeholder: _theme.typography.body.copyWith(
        color: palette.text.withValues(alpha: opacities.tertiary),
      ),
      optionPadding: EdgeInsets.symmetric(
        horizontal: _theme.space.x2,
        vertical: _theme.space.x2,
      ),
      optionGap: _theme.space.x2,
      optionRadius: _theme.radii.small,
      highlight: palette.text.withValues(alpha: opacities.hover),
      selected:
          SurfaceResolver(_theme).resolve(swatch, SurfaceVariant.soft).fill ??
          palette.text.withValues(alpha: opacities.focus),
      maxListHeight: _theme.sizes.dialog / 2,
    );
  }
}

/// Resolves the theme into the [MenuStyle] a `Menu` paints.
class MenuResolver {
  const MenuResolver(this._theme);

  final Theme _theme;

  /// A menu is a popover with rows in it: the panel comes straight from
  /// [PopoverResolver], and the rest is what a row needs. The highlight is
  /// the neutral hover wash rather than the brand — the keyboard's place in
  /// a list is a fact about the list, not an emphasis.
  MenuStyle resolve() {
    final palette = _theme.palette;
    final opacities = _theme.opacities;
    final space = _theme.space;
    return MenuStyle(
      // Rows set the width; the panel's own reading-column cap would only
      // fight them.
      popover: PopoverResolver(
        _theme,
      ).resolve().copyWith(maxWidth: double.infinity),
      highlight: palette.text.withValues(alpha: opacities.hover),
      separator: palette.divider,
      itemPadding: EdgeInsets.symmetric(
        horizontal: space.x2,
        vertical: space.x2,
      ),
      itemGap: space.x2,
      itemRadius: _theme.radii.small,
      trailingStyle: TextResolver(_theme).resolve(
        TextRole.caption,
        emphasis: TextEmphasis.tertiary,
        on: palette.text,
      ),
      sectionStyle: TextResolver(_theme).resolve(
        TextRole.kicker,
        emphasis: TextEmphasis.tertiary,
        on: palette.text,
      ),
      sectionPadding: EdgeInsets.symmetric(
        horizontal: space.x2,
        vertical: space.x1,
      ),
      separatorThickness: _theme.strokes.hairline,
      separatorMargin: EdgeInsets.symmetric(vertical: space.x1),
      iconSize: _theme.sizes.icon,
      minWidth: _theme.sizes.dialog / 3,
      maxHeight: _theme.sizes.dialog / 2,
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [PopoverStyle] a `Popover` paints.
class PopoverResolver {
  const PopoverResolver(this._theme);

  final Theme _theme;

  /// The floating panel: the palette's [Palette.surface] — the colour
  /// cards, fields, and menus share — over a hairline, at the elevation
  /// things floating over content sit at.
  PopoverStyle resolve() {
    final palette = _theme.palette;
    return PopoverStyle(
      surface: SurfaceStyle(
        foreground: palette.text,
        fill: palette.surface,
        border: palette.divider,
        radius: _theme.radii.large,
      ),
      padding: EdgeInsets.all(_theme.space.x2),
      gap: _theme.space.x2,
      margin: _theme.space.x2,
      maxWidth: _theme.sizes.dialog / 2,
      shadow: _theme.shadows.medium,
    );
  }
}

/// Resolves the theme into the [TooltipStyle] a `Tooltip` paints.
class TooltipResolver {
  const TooltipResolver(this._theme);

  final Theme _theme;

  /// A tooltip inverts the page — the text colour becomes the fill and the
  /// background becomes the ink — so it reads as an annotation over the
  /// interface rather than another piece of it, and stays legible in both
  /// brightnesses without a palette of its own.
  TooltipStyle resolve() {
    final palette = _theme.palette;
    return TooltipStyle(
      popover: PopoverResolver(_theme).resolve().copyWith(
        surface: SurfaceStyle(
          foreground: palette.background,
          fill: palette.text,
          radius: _theme.radii.small,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: _theme.space.x2,
          vertical: _theme.space.x1,
        ),
        maxWidth: _theme.sizes.contentNarrow / 2,
        shadow: _theme.shadows.low,
      ),
      textStyle: _theme.typography.bodySmall,
    );
  }
}

/// Resolves the theme into the [SliderStyle] a `Slider` paints.
class SliderResolver {
  const SliderResolver(this._theme);

  final Theme _theme;

  /// The same dressing rule the switch follows, stretched along a line:
  /// the travelled part of the track wears [swatch] at [variant]'s
  /// treatment, the rest wears a neutral soft fill, and the thumb takes
  /// the active track's foreground so it reads against the swatch it sits
  /// on.
  ///
  /// [SurfaceVariant.solid] is left as solid here where a checkbox rests
  /// as an outline: an empty box shouldn't look filled, but a track always
  /// has a travelled part, however short.
  SliderStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceVariant variant = SurfaceVariant.solid,
  ]) {
    final surfaces = SurfaceResolver(_theme);
    const pill = BorderRadius.all(Radius.circular(999));
    final active = surfaces.resolve(swatch, variant).copyWith(radius: pill);
    final inactive = surfaces
        .resolve(
          SemanticSwatch.neutral,
          variant == SurfaceVariant.solid ? SurfaceVariant.soft : variant,
        )
        .copyWith(radius: pill);
    final opacities = _theme.opacities;
    return SliderStyle(
      active: active,
      inactive: inactive,
      thumb: SurfaceStyle(
        foreground: active.fill ?? active.foreground,
        fill: active.foreground,
        radius: pill,
      ),
      ring:
          surfaces.resolve(swatch, SurfaceVariant.solid).fill ??
          active.foreground,
      trackHeight: _theme.space.x1 + _theme.strokes.hairline,
      thumbSize: _theme.sizes.iconLarge,
      height: _theme.sizes.control,
      minWidth: _theme.sizes.contentNarrow / 4,
      tick: inactive.foreground.withValues(alpha: opacities.tertiary),
      tickSize: _theme.strokes.focus,
      hover: inactive.foreground.withValues(alpha: opacities.hover),
      pressed: inactive.foreground.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [SegmentedControlStyle] a
/// `SegmentedControl` paints.
class SegmentedResolver {
  const SegmentedResolver(this._theme);

  final Theme _theme;

  /// A trough in neutral with one segment's worth of [swatch] sliding
  /// about inside it — the switch's track-and-thumb idea, widened until
  /// the thumb has words on it.
  ///
  /// The chosen segment's words read against the indicator and everyone
  /// else's against the track, so the two get their own styles rather than
  /// one style graded down.
  SegmentedControlStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceVariant variant = SurfaceVariant.solid,
  ]) {
    final surfaces = SurfaceResolver(_theme);
    final palette = _theme.palette;
    final opacities = _theme.opacities;
    final text = TextResolver(_theme);
    final track = surfaces
        .resolve(SemanticSwatch.neutral, SurfaceVariant.soft)
        .copyWith(radius: _theme.radii.medium);
    final indicator = surfaces
        .resolve(swatch, variant)
        .copyWith(radius: _theme.radii.small);
    final body = _theme.typography.body.copyWith(fontWeight: FontWeight.w500);
    return SegmentedControlStyle(
      track: track,
      indicator: indicator,
      selectedStyle: body.copyWith(color: indicator.foreground),
      unselectedStyle: body.copyWith(
        color: text.tint(emphasis: TextEmphasis.secondary, on: palette.text),
      ),
      ring:
          surfaces.resolve(swatch, SurfaceVariant.solid).fill ??
          indicator.foreground,
      height: _theme.sizes.control,
      inset: _theme.strokes.focus,
      segmentPadding: EdgeInsets.symmetric(horizontal: _theme.space.x3),
      gap: _theme.space.x2,
      iconSize: _theme.sizes.icon,
      // The washes are the track's foreground, so they read on the segments
      // that have no indicator under them.
      hover: track.foreground.withValues(alpha: opacities.hover),
      pressed: track.foreground.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [SwitchStyle] a `Switch` paints.
class SwitchResolver {
  const SwitchResolver(this._theme);

  final Theme _theme;

  /// The concrete paint for a switch wearing [swatch] in [variant]'s
  /// treatment.
  ///
  /// On wears the swatch, off wears neutral — but where a checkbox's
  /// [SurfaceVariant.solid] rests as an outline, a switch rests as a
  /// *filled* soft track: an off switch is still a track with a thumb on
  /// it, never an empty box.
  SwitchStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceVariant variant = SurfaceVariant.solid,
  ]) {
    final surfaces = SurfaceResolver(_theme);
    const pill = BorderRadius.all(Radius.circular(999));
    final on = surfaces.resolve(swatch, variant).copyWith(radius: pill);
    final off = surfaces
        .resolve(
          SemanticSwatch.neutral,
          variant == SurfaceVariant.solid ? SurfaceVariant.soft : variant,
        )
        .copyWith(radius: pill);
    final opacities = _theme.opacities;
    return SwitchStyle(
      on: on,
      off: off,
      gap: _theme.space.x2,
      ring:
          surfaces.resolve(swatch, SurfaceVariant.solid).fill ?? on.foreground,
      hover: off.foreground.withValues(alpha: opacities.hover),
      pressed: off.foreground.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [RadioStyle] a `RadioButton` paints.
class RadioResolver {
  const RadioResolver(this._theme);

  final Theme _theme;

  /// The concrete paint for a radio button wearing [swatch] in [variant]'s
  /// treatment.
  ///
  /// The same dressing rule as a checkbox — selected wears the swatch,
  /// unselected wears neutral, and [SurfaceVariant.solid] rests as an
  /// outline — over a circle instead of a box.
  RadioStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceVariant variant = SurfaceVariant.solid,
  ]) {
    final surfaces = SurfaceResolver(_theme);
    const circle = BorderRadius.all(Radius.circular(999));
    final selected = surfaces.resolve(swatch, variant).copyWith(radius: circle);
    final unselected = surfaces
        .resolve(
          SemanticSwatch.neutral,
          variant == SurfaceVariant.solid ? SurfaceVariant.outline : variant,
        )
        .copyWith(radius: circle);
    final opacities = _theme.opacities;
    return RadioStyle(
      selected: selected,
      unselected: unselected,
      gap: _theme.space.x2,
      ring:
          surfaces.resolve(swatch, SurfaceVariant.solid).fill ??
          selected.foreground,
      hover: unselected.foreground.withValues(alpha: opacities.hover),
      pressed: unselected.foreground.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [CheckboxStyle] a `Checkbox` paints.
class CheckboxResolver {
  const CheckboxResolver(this._theme);

  final Theme _theme;

  /// The concrete paint for a checkbox wearing [swatch].
  ///
  /// Checked is the swatch's solid dress; unchecked is a neutral outline —
  /// an empty box shouldn't campaign for attention. Both wear the small
  /// radius: this is a control, not a card. The washes are the unchecked
  /// foreground at the theme's [Opacities], so they read in both states.
  ///
  /// [variant] dresses both states: checked wears [swatch], unchecked wears
  /// neutral. The one exception is [SurfaceVariant.solid], which rests as
  /// an outline — an empty box shouldn't look filled.
  CheckboxStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceVariant variant = SurfaceVariant.solid,
  ]) {
    final surfaces = SurfaceResolver(_theme);
    final radius = _theme.radii.small;
    final checked = surfaces.resolve(swatch, variant).copyWith(radius: radius);
    final unchecked = surfaces
        .resolve(
          SemanticSwatch.neutral,
          variant == SurfaceVariant.solid ? SurfaceVariant.outline : variant,
        )
        .copyWith(radius: radius);
    final opacities = _theme.opacities;
    return CheckboxStyle(
      checked: checked,
      unchecked: unchecked,
      gap: _theme.space.x2,
      // The swatch at full voice, whatever the variant wears.
      ring:
          surfaces.resolve(swatch, SurfaceVariant.solid).fill ??
          checked.foreground,
      hover: unchecked.foreground.withValues(alpha: opacities.hover),
      pressed: unchecked.foreground.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves the theme into the [ButtonStyle] a `Button` paints: the surface
/// dress for the swatch and variant, control geometry from the tokens, and
/// the state colours interaction wears.
class ButtonResolver {
  const ButtonResolver(this._theme);

  final Theme _theme;

  SurfaceStyle _surface(SemanticSwatch swatch, SurfaceVariant variant) =>
      SurfaceResolver(_theme).resolve(swatch, variant);

  /// The concrete paint for a button wearing [swatch] in [variant]'s
  /// treatment.
  ///
  /// The hover and pressed washes are the surface's foreground at the
  /// theme's [Opacities] — which is what lets a ghost button be felt before
  /// it is seen. The focus ring is the swatch at full voice: the solid
  /// variant's fill.
  ButtonStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceVariant variant = SurfaceVariant.solid,
  ]) {
    final surface = _surface(swatch, variant);
    final opacities = _theme.opacities;
    return ButtonStyle(
      surface: surface,
      height: _theme.sizes.control,
      padding: EdgeInsets.symmetric(horizontal: _theme.space.x4),
      gap: _theme.space.x2,
      textStyle: _theme.typography.body.copyWith(fontWeight: FontWeight.w500),
      ring: _surface(swatch, SurfaceVariant.solid).fill ?? surface.foreground,
      hover: surface.foreground.withValues(alpha: opacities.hover),
      pressed: surface.foreground.withValues(alpha: opacities.pressed),
      disabledOpacity: opacities.disabled,
    );
  }
}

/// Resolves [SurfaceStyles] into the [SurfaceStyle] a `Surface` paints.
class SurfaceResolver {
  const SurfaceResolver(this._theme);

  final Theme _theme;

  /// The concrete paint for a surface wearing [swatch] in [variant]'s
  /// treatment. The semantic name becomes a real [Swatch] through the
  /// palette ([Palette.of]) — widgets never hold colours, only meanings.
  ///
  /// Roles resolve through the variant's [SurfaceShades]; a mapping with no
  /// foreground gets what reads: the contrast pick over the fill when there
  /// is one, the palette's text colour when there isn't.
  SurfaceStyle resolve([
    SemanticSwatch swatch = SemanticSwatch.primary,
    SurfaceVariant variant = SurfaceVariant.solid,
  ]) {
    final palette = _theme.palette;
    final worn = palette.of(swatch);
    final brightness = palette.brightness;
    final shades = _theme.styles.surface.of(variant, swatch);

    final fill = shades.fill;
    var foreground = shades.foreground?.on(worn, brightness);
    foreground ??= fill != null
        ? (fill.swatch ?? worn).contrastFor(fill.stopFor(brightness))
        : palette.text;

    return SurfaceStyle(
      foreground: foreground,
      fill: fill?.on(worn, brightness),
      border: shades.border?.on(worn, brightness),
      dashed: shades.dashed,
      striped: shades.striped,
      radius: _theme.radii.medium,
    );
  }
}
