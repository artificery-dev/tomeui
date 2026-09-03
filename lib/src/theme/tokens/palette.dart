import 'package:flutter/widgets.dart';

import 'opacities.dart';
import 'swatch.dart';

/// The color tokens: a [Swatch] per [SemanticSwatch] and a [Brightness],
/// with the semantic roles *derived*.
///
/// A rebrand is one line and light/dark is a flip, never a second palette to
/// keep in sync. The role set is deliberately small — the handful an app
/// shell and the first widgets need — and grows as widgets earn new names
/// for it.
@immutable
class Palette {
  const Palette({
    this.brightness = Brightness.dark,
    this.primary = Swatch.sky,
    this.accent = Swatch.blue,
    this.neutral = Swatch.zinc,
    this.info = Swatch.blue,
    this.warning = Swatch.yellow,
    this.success = Swatch.green,
    this.error = Swatch.red,
  });

  final Brightness brightness;

  /// The brand at full voice — primary actions, focus, selection. The
  /// default when a surface doesn't say otherwise.
  final Swatch primary;

  /// The brand's second voice — highlights and flourishes where [primary]
  /// would shout.
  final Swatch accent;

  /// The grays: backgrounds, surfaces, text, dividers.
  final Swatch neutral;

  /// Something worth knowing — notices, hints, the calm end of feedback.
  final Swatch info;

  /// Something worth pausing over — caution, before it becomes [error].
  final Swatch warning;

  /// Something that went right — confirmations, completions, the all-clear.
  final Swatch success;

  /// Something that went wrong — validation faults, failures, destructive
  /// actions.
  final Swatch error;

  /// The real [Swatch] behind a [SemanticSwatch] — how a semantic choice on
  /// a widget becomes color on this palette.
  Swatch of(SemanticSwatch swatch) => switch (swatch) {
    SemanticSwatch.primary => primary,
    SemanticSwatch.accent => accent,
    SemanticSwatch.neutral => neutral,
    SemanticSwatch.info => info,
    SemanticSwatch.warning => warning,
    SemanticSwatch.success => success,
    SemanticSwatch.error => error,
  };

  bool get _dark => brightness == Brightness.dark;

  /// The page itself, behind everything.
  Color get background => _dark ? neutral.s950 : neutral.s50;

  /// Cards, fields, bars — one step off [background].
  Color get surface => _dark ? neutral.s900 : neutral.s0;

  /// Foreground at full emphasis. Step it down with [Opacities], not with
  /// grayer colors, so it stays right on every surface.
  Color get text => _dark ? neutral.s50 : neutral.s950;

  Color get divider => _dark ? neutral.s800 : neutral.s200;

  /// Foreground for content sitting *on* [primary].
  Color get onPrimary => primary.contrastFor(_dark ? 400 : 600);

  Palette copyWith({
    Brightness? brightness,
    Swatch? primary,
    Swatch? accent,
    Swatch? neutral,
    Swatch? info,
    Swatch? warning,
    Swatch? success,
    Swatch? error,
  }) => Palette(
    brightness: brightness ?? this.brightness,
    primary: primary ?? this.primary,
    accent: accent ?? this.accent,
    neutral: neutral ?? this.neutral,
    info: info ?? this.info,
    warning: warning ?? this.warning,
    success: success ?? this.success,
    error: error ?? this.error,
  );

  @override
  bool operator ==(Object other) =>
      other is Palette &&
      other.brightness == brightness &&
      other.primary == primary &&
      other.accent == accent &&
      other.neutral == neutral &&
      other.info == info &&
      other.warning == warning &&
      other.success == success &&
      other.error == error;

  @override
  int get hashCode => Object.hash(
    brightness,
    primary,
    accent,
    neutral,
    info,
    warning,
    success,
    error,
  );
}
