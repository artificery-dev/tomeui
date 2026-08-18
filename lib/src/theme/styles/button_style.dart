import 'package:tomeui/tomeui.dart';

/// The resolved values a [Button] actually paints — its [Surface] dress
/// plus the geometry and state colours a control needs. Colours, not
/// choices — the choosing happened in [ButtonResolver], at
/// `theme.widgets.button`.
///
/// Construct one directly (or [copyWith] a resolved one) for custom
/// everything, via `Button.custom`.
@immutable
class ButtonStyle {
  const ButtonStyle({
    required this.surface,
    this.height = 36,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.gap = 8,
    this.textStyle = const TextStyle(fontWeight: FontWeight.w500),
    required this.ring,
    this.hover,
    this.pressed,
    this.disabledOpacity = 0.38,
    this.lift = 0.02,
  });

  /// The box the button is: fill, border, foreground, corners.
  final SurfaceStyle surface;

  final double height;
  final EdgeInsetsGeometry padding;

  /// Breathing room between the slots.
  final double gap;

  /// What the label wears, over the surface's foreground colour.
  final TextStyle textStyle;

  /// The focus ring — the swatch at full voice.
  final Color ring;

  /// Washed over the fill while the pointer rests here.
  final Color? hover;

  /// Washed over the fill while pressed.
  final Color? pressed;

  final double disabledOpacity;

  /// How far the button rises toward the pointer: hover scales to
  /// `1 + lift`, pressing sinks to `1 - lift`. Zero stills it.
  final double lift;

  ButtonStyle copyWith({
    SurfaceStyle? surface,
    double? height,
    EdgeInsetsGeometry? padding,
    double? gap,
    TextStyle? textStyle,
    Color? ring,
    Color? hover,
    Color? pressed,
    double? disabledOpacity,
    double? lift,
  }) => ButtonStyle(
    surface: surface ?? this.surface,
    height: height ?? this.height,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    textStyle: textStyle ?? this.textStyle,
    ring: ring ?? this.ring,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    lift: lift ?? this.lift,
  );

  @override
  bool operator ==(Object other) =>
      other is ButtonStyle &&
      other.surface == surface &&
      other.height == height &&
      other.padding == padding &&
      other.gap == gap &&
      other.textStyle == textStyle &&
      other.ring == ring &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.disabledOpacity == disabledOpacity &&
      other.lift == lift;

  @override
  int get hashCode => Object.hash(
    surface,
    height,
    padding,
    gap,
    textStyle,
    ring,
    hover,
    pressed,
    disabledOpacity,
    lift,
  );
}
