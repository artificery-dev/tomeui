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
