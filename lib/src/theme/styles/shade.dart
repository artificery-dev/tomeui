import 'package:tomeui/tomeui.dart';

/// One color choice in a style: a stop per brightness, on the swatch the
/// surface wears — or on [swatch], when a role should ignore what's worn
/// (a foreground pinned to the neutral ramp, say).
///
/// Stops interpolate the way [Swatch] does, so a `Shade(light: 450, ...)`
/// is legal and lands between the named stops.
@immutable
class Shade {
  const Shade({
    required this.light,
    required this.dark,
    this.swatch,
    this.alpha,
  });

  /// The same stop in both modes.
  const Shade.fixed(num stop, {Swatch? on, this.alpha})
    : light = stop,
      dark = stop,
      swatch = on;

  final num light;
  final num dark;

  /// Overrides the swatch the surface wears. Null wears what's worn.
  final Swatch? swatch;

  /// How much of the stop is laid down, 0 to 1. Null is all of it.
  ///
  /// A wash rather than a slab: a surface named with an alpha lets what is
  /// behind it through, which is what makes a quiet fill quiet on a
  /// wallpaper as well as on a page.
  final double? alpha;

  num stopFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// The color this shade names when the surface wears [worn].
  Color on(Swatch worn, Brightness brightness) {
    final color = (swatch ?? worn)[stopFor(brightness)];
    return alpha == null ? color : color.withValues(alpha: alpha);
  }

  @override
  bool operator ==(Object other) =>
      other is Shade &&
      other.light == light &&
      other.dark == dark &&
      other.swatch == swatch &&
      other.alpha == alpha;

  @override
  int get hashCode => Object.hash(light, dark, swatch, alpha);
}
