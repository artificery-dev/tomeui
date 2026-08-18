import 'package:tomeui/tomeui.dart';

/// The resolved values a [RadioButton] actually paints: the circle in both
/// of its states, the dot inside it, and the interaction dressing around
/// it. Colours, not choices — the choosing happened in [RadioResolver], at
/// `theme.widgets.radio`.
///
/// Construct one directly (or [copyWith] a resolved one) for custom
/// everything, via `RadioButton.custom`.
@immutable
class RadioStyle {
  const RadioStyle({
    required this.selected,
    required this.unselected,
    this.size = 20,
    this.gap = 8,
    this.dot = 8,
    required this.ring,
    this.hover,
    this.pressed,
    this.disabledOpacity = 0.38,
    this.lift = 0.05,
  });

  /// The circle when this button is the group's answer.
  final SurfaceStyle selected;

  /// The circle when it isn't — one of the alternatives, waiting.
  final SurfaceStyle unselected;

  /// The circle's diameter.
  final double size;

  /// The dot's diameter, at full selection. It grows in from nothing.
  final double dot;

  /// The space between the control and its label.
  final double gap;

  /// The focus ring — the swatch at full voice.
  final Color ring;

  /// Washed over the circle while the pointer rests here.
  final Color? hover;

  /// Washed over the circle while pressed.
  final Color? pressed;

  final double disabledOpacity;

  /// How far the circle rises toward the pointer.
  final double lift;

  RadioStyle copyWith({
    SurfaceStyle? selected,
    SurfaceStyle? unselected,
    double? size,
    double? gap,
    double? dot,
    Color? ring,
    Color? hover,
    Color? pressed,
    double? disabledOpacity,
    double? lift,
  }) => RadioStyle(
    selected: selected ?? this.selected,
    unselected: unselected ?? this.unselected,
    size: size ?? this.size,
    gap: gap ?? this.gap,
    dot: dot ?? this.dot,
    ring: ring ?? this.ring,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    lift: lift ?? this.lift,
  );

  @override
  bool operator ==(Object other) =>
      other is RadioStyle &&
      other.selected == selected &&
      other.unselected == unselected &&
      other.size == size &&
      other.gap == gap &&
      other.dot == dot &&
      other.ring == ring &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.disabledOpacity == disabledOpacity &&
      other.lift == lift;

  @override
  int get hashCode => Object.hash(
    selected,
    unselected,
    size,
    gap,
    dot,
    ring,
    hover,
    pressed,
    disabledOpacity,
    lift,
  );
}
