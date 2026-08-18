import 'package:tomeui/tomeui.dart';

/// The resolved values a [Checkbox] actually paints: the box in both of its
/// states, and the interaction dressing around it. Colours, not choices —
/// the choosing happened in [CheckboxResolver], at `theme.widgets.checkbox`.
///
/// Construct one directly (or [copyWith] a resolved one) for custom
/// everything, via `Checkbox.custom`.
@immutable
class CheckboxStyle {
  const CheckboxStyle({
    required this.checked,
    required this.unchecked,
    this.size = 20,
    this.gap = 8,
    required this.ring,
    this.hover,
    this.pressed,
    this.disabledOpacity = 0.38,
    this.lift = 0.05,
  });

  /// The box when the value is true: the swatch at full voice, the check
  /// glyph in its contrast colour.
  final SurfaceStyle checked;

  /// The box when the value is false: an empty outline, waiting.
  final SurfaceStyle unchecked;

  /// The box's edge length. The touch target stays larger than the drawing.
  final double size;

  /// The space between the control and its label.
  final double gap;

  /// The focus ring — the swatch at full voice.
  final Color ring;

  /// Washed over the box while the pointer rests here.
  final Color? hover;

  /// Washed over the box while pressed.
  final Color? pressed;

  final double disabledOpacity;

  /// How far the box rises toward the pointer — proportionally more than a
  /// button's, because the box is small.
  final double lift;

  CheckboxStyle copyWith({
    SurfaceStyle? checked,
    SurfaceStyle? unchecked,
    double? size,
    double? gap,
    Color? ring,
    Color? hover,
    Color? pressed,
    double? disabledOpacity,
    double? lift,
  }) => CheckboxStyle(
    checked: checked ?? this.checked,
    unchecked: unchecked ?? this.unchecked,
    size: size ?? this.size,
    gap: gap ?? this.gap,
    ring: ring ?? this.ring,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    lift: lift ?? this.lift,
  );

  @override
  bool operator ==(Object other) =>
      other is CheckboxStyle &&
      other.checked == checked &&
      other.unchecked == unchecked &&
      other.size == size &&
      other.gap == gap &&
      other.ring == ring &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.disabledOpacity == disabledOpacity &&
      other.lift == lift;

  @override
  int get hashCode => Object.hash(
    checked,
    unchecked,
    size,
    gap,
    ring,
    hover,
    pressed,
    disabledOpacity,
    lift,
  );
}
