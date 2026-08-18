import 'package:flutter/widgets.dart';

/// The opacity steps.
///
/// Two families in one scale. The emphasis steps ([secondary], [tertiary],
/// [disabled]) grade text and icons against their surface; the overlay steps
/// ([hover] through [scrim]) are laid *over* a surface in its own foreground
/// colour to show interaction state, so the same numbers work on any palette.
@immutable
class Opacities {
  const Opacities({
    this.secondary = 0.72,
    this.tertiary = 0.55,
    this.disabled = 0.38,
    this.hover = 0.10,
    this.pressed = 0.16,
    this.focus = 0.12,
    this.dragged = 0.20,
    this.divider = 0.12,
    this.scrim = 0.5,
  });

  // Emphasis, applied to a foreground colour.
  final double secondary;
  final double tertiary;
  final double disabled;

  // Interaction overlays, foreground over surface.
  final double hover;
  final double pressed;
  final double focus;
  final double dragged;

  /// A divider drawn in the foreground colour rather than a dedicated hue.
  final double divider;

  /// The veil behind a dialog or sheet.
  final double scrim;

  Opacities copyWith({
    double? secondary,
    double? tertiary,
    double? disabled,
    double? hover,
    double? pressed,
    double? focus,
    double? dragged,
    double? divider,
    double? scrim,
  }) => Opacities(
    secondary: secondary ?? this.secondary,
    tertiary: tertiary ?? this.tertiary,
    disabled: disabled ?? this.disabled,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    focus: focus ?? this.focus,
    dragged: dragged ?? this.dragged,
    divider: divider ?? this.divider,
    scrim: scrim ?? this.scrim,
  );

  @override
  bool operator ==(Object other) =>
      other is Opacities &&
      other.secondary == secondary &&
      other.tertiary == tertiary &&
      other.disabled == disabled &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.focus == focus &&
      other.dragged == dragged &&
      other.divider == divider &&
      other.scrim == scrim;

  @override
  int get hashCode => Object.hash(
    secondary,
    tertiary,
    disabled,
    hover,
    pressed,
    focus,
    dragged,
    divider,
    scrim,
  );
}
