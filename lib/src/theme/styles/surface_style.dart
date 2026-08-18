import 'package:tomeui/tomeui.dart';

/// How a [Surface] wears its swatch.
enum SurfaceVariant {
  /// A strong fill in the swatch itself — the call to action.
  solid,

  /// A tinted fill with a deep foreground — selected rows, quiet emphasis.
  soft,

  /// The faintest fill — hover washes, zebra stripes, resting chrome.
  subtle,

  /// No fill, a hairline in the swatch — secondary actions, quiet edges.
  outline,

  /// Foreground only — the surface is felt, not seen, until interaction
  /// dresses it.
  ghost,

  /// A dashed hairline over a diagonally striped wash — something that
  /// belongs here but isn't here yet: drop targets, empty slots.
  placeholder,
}

/// The resolved values a [Surface] actually paints. Colours, not choices —
/// the choosing happened in [SurfaceResolver], at `theme.widgets.surface`.
///
/// Construct one directly (or [copyWith] a resolved one) for custom
/// everything, via `Surface.custom`.
@immutable
class SurfaceStyle {
  const SurfaceStyle({
    required this.foreground,
    this.fill,
    this.border,
    this.dashed = false,
    this.striped = false,
    // Mirrors the default Radii().medium — a resolved style gets the
    // theme's actual radii; this default serves hand-built styles.
    this.radius = const BorderRadius.all(Radius.circular(10)),
  });

  /// What text and icons inside the surface wear. Always present: even a
  /// [SurfaceVariant.ghost] has a voice.
  final Color foreground;

  /// The background, when the variant has one.
  final Color? fill;

  /// The edge, when the variant has one — drawn at [Strokes.hairline].
  final Color? border;

  /// Dash the [border] instead of drawing it solid.
  final bool dashed;

  /// Paint the [fill] as diagonal stripes instead of a solid wash.
  final bool striped;

  final BorderRadius radius;

  SurfaceStyle copyWith({
    Color? foreground,
    Color? fill,
    Color? border,
    bool? dashed,
    bool? striped,
    BorderRadius? radius,
  }) => SurfaceStyle(
    foreground: foreground ?? this.foreground,
    fill: fill ?? this.fill,
    border: border ?? this.border,
    dashed: dashed ?? this.dashed,
    striped: striped ?? this.striped,
    radius: radius ?? this.radius,
  );

  @override
  bool operator ==(Object other) =>
      other is SurfaceStyle &&
      other.foreground == foreground &&
      other.fill == fill &&
      other.border == border &&
      other.dashed == dashed &&
      other.striped == striped &&
      other.radius == radius;

  @override
  int get hashCode =>
      Object.hash(foreground, fill, border, dashed, striped, radius);
}

/// The tone mapping for one variant: which shade each role wears.
///
/// A null [foreground] means "pick what reads": the contrast colour over
/// [fill] when there is one, the palette's text colour when there isn't.
@immutable
class SurfaceShades {
  const SurfaceShades({
    this.fill,
    this.foreground,
    this.border,
    this.dashed = false,
    this.striped = false,
  });

  final Shade? fill;
  final Shade? foreground;
  final Shade? border;
  final bool dashed;
  final bool striped;

  SurfaceShades copyWith({
    Shade? fill,
    Shade? foreground,
    Shade? border,
    bool? dashed,
    bool? striped,
  }) => SurfaceShades(
    fill: fill ?? this.fill,
    foreground: foreground ?? this.foreground,
    border: border ?? this.border,
    dashed: dashed ?? this.dashed,
    striped: striped ?? this.striped,
  );

  @override
  bool operator ==(Object other) =>
      other is SurfaceShades &&
      other.fill == fill &&
      other.foreground == foreground &&
      other.border == border &&
      other.dashed == dashed &&
      other.striped == striped;

  @override
  int get hashCode => Object.hash(fill, foreground, border, dashed, striped);
}

/// The theme's tone mapping, variant by variant.
///
/// The defaults are the system's taste — solid wears the swatch at 500 in
/// light and 400 in dark, the quieter variants sink the fill toward the
/// page's end of the ramp and pull the foreground toward the readable
/// middle. A theme built from two swatches never touches this; a theme with
/// opinions replaces exactly the mappings it has opinions about.
@immutable
class SurfaceStyles {
  const SurfaceStyles({
    this.solid = const SurfaceShades(fill: Shade(light: 500, dark: 400)),
    this.soft = const SurfaceShades(
      fill: Shade(light: 100, dark: 900),
      foreground: Shade(light: 700, dark: 300),
    ),
    this.subtle = const SurfaceShades(
      fill: Shade(light: 50, dark: 950),
      foreground: Shade(light: 600, dark: 400),
    ),
    this.outline = const SurfaceShades(
      border: Shade(light: 400, dark: 600),
      foreground: Shade(light: 700, dark: 300),
    ),
    this.ghost = const SurfaceShades(foreground: Shade(light: 700, dark: 300)),
    this.placeholder = const SurfaceShades(
      fill: Shade(light: 200, dark: 800),
      border: Shade(light: 300, dark: 700),
      foreground: Shade(light: 600, dark: 400),
      dashed: true,
      striped: true,
    ),
  });

  final SurfaceShades solid;
  final SurfaceShades soft;
  final SurfaceShades subtle;
  final SurfaceShades outline;
  final SurfaceShades ghost;
  final SurfaceShades placeholder;

  SurfaceShades of(SurfaceVariant variant) => switch (variant) {
    SurfaceVariant.solid => solid,
    SurfaceVariant.soft => soft,
    SurfaceVariant.subtle => subtle,
    SurfaceVariant.outline => outline,
    SurfaceVariant.ghost => ghost,
    SurfaceVariant.placeholder => placeholder,
  };

  SurfaceStyles copyWith({
    SurfaceShades? solid,
    SurfaceShades? soft,
    SurfaceShades? subtle,
    SurfaceShades? outline,
    SurfaceShades? ghost,
    SurfaceShades? placeholder,
  }) => SurfaceStyles(
    solid: solid ?? this.solid,
    soft: soft ?? this.soft,
    subtle: subtle ?? this.subtle,
    outline: outline ?? this.outline,
    ghost: ghost ?? this.ghost,
    placeholder: placeholder ?? this.placeholder,
  );

  @override
  bool operator ==(Object other) =>
      other is SurfaceStyles &&
      other.solid == solid &&
      other.soft == soft &&
      other.subtle == subtle &&
      other.outline == outline &&
      other.ghost == ghost &&
      other.placeholder == placeholder;

  @override
  int get hashCode =>
      Object.hash(solid, soft, subtle, outline, ghost, placeholder);
}
