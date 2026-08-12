import 'package:flutter/widgets.dart';

import 'opacities.dart';
import 'swatch.dart';

/// The colour tokens: two [Swatch]es and a [Brightness], with the semantic
/// roles *derived*.
///
/// A rebrand is one line and light/dark is a flip, never a second palette to
/// keep in sync. The role set is deliberately small — the handful an app
/// shell and the first widgets need — and grows as widgets earn new names
/// for it.
@immutable
class Palette {
  const Palette({
    this.brightness = Brightness.dark,
    this.neutral = Swatch.zinc,
    this.accent = Swatch.blue,
  });

  final Brightness brightness;

  /// The greys: backgrounds, surfaces, text, dividers.
  final Swatch neutral;

  /// The brand colour: primary actions, focus, selection.
  final Swatch accent;

  bool get _dark => brightness == Brightness.dark;

  /// The page itself, behind everything.
  Color get background => _dark ? neutral.s950 : neutral.s50;

  /// Cards, fields, bars — one step off [background].
  Color get surface => _dark ? neutral.s900 : neutral.s0;

  /// Foreground at full emphasis. Step it down with [Opacities], not with
  /// greyer colours, so it stays right on every surface.
  Color get text => _dark ? neutral.s50 : neutral.s950;

  Color get divider => _dark ? neutral.s800 : neutral.s200;

  /// The accent, at a stop that reads on [background].
  Color get primary => _dark ? accent.s400 : accent.s600;

  /// Foreground for content sitting *on* [primary].
  Color get onPrimary => accent.contrastFor(_dark ? 400 : 600);

  Palette copyWith({
    Brightness? brightness,
    Swatch? neutral,
    Swatch? accent,
  }) => Palette(
    brightness: brightness ?? this.brightness,
    neutral: neutral ?? this.neutral,
    accent: accent ?? this.accent,
  );

  @override
  bool operator ==(Object other) =>
      other is Palette &&
      other.brightness == brightness &&
      other.neutral == neutral &&
      other.accent == accent;

  @override
  int get hashCode => Object.hash(brightness, neutral, accent);
}
