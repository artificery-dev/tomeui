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

  ButtonResolver get button => ButtonResolver(_theme);

  CheckboxResolver get checkbox => CheckboxResolver(_theme);

  RadioResolver get radio => RadioResolver(_theme);

  /// Trailing underscore: `switch` is a keyword.
  SwitchResolver get switch_ => SwitchResolver(_theme);

  PopoverResolver get popover => PopoverResolver(_theme);

  TooltipResolver get tooltip => TooltipResolver(_theme);

  MenuResolver get menu => MenuResolver(_theme);

  SelectResolver get select => SelectResolver(_theme);

  TextFieldResolver get textField => TextFieldResolver(_theme);

  TextResolver get text => TextResolver(_theme);

  LinkResolver get link => LinkResolver(_theme);

  CodeTextResolver get code => CodeTextResolver(_theme);
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
    final shades = _theme.styles.surface.of(variant);

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
