import 'package:tomeui/tomeui.dart';

/// One colour choice in a style: a stop per brightness, on the swatch the
/// surface wears — or on [swatch], when a role should ignore what's worn
/// (a foreground pinned to the neutral ramp, say).
///
/// Stops interpolate the way [Swatch] does, so a `Shade(light: 450, ...)`
/// is legal and lands between the named stops.
@immutable
class Shade {
  const Shade({required this.light, required this.dark, this.swatch});

  /// The same stop in both modes.
  const Shade.fixed(num stop, {Swatch? on})
    : light = stop,
      dark = stop,
      swatch = on;

  final num light;
  final num dark;

  /// Overrides the swatch the surface wears. Null wears what's worn.
  final Swatch? swatch;

  num stopFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// The colour this shade names when the surface wears [worn].
  Color on(Swatch worn, Brightness brightness) =>
      (swatch ?? worn)[stopFor(brightness)];

  @override
  bool operator ==(Object other) =>
      other is Shade &&
      other.light == light &&
      other.dark == dark &&
      other.swatch == swatch;

  @override
  int get hashCode => Object.hash(light, dark, swatch);
}
