import 'package:tomeui/tomeui.dart';

/// The resolved values a [CodeText] paints: the chip it sits in, the
/// monospace it wears, and the dressing of its copy affordance.
///
/// Colours, not choices — the choosing happened in [CodeTextResolver], at
/// `theme.widgets.code`.
@immutable
class CodeTextStyle {
  const CodeTextStyle({
    required this.surface,
    required this.textStyle,
    required this.ring,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.gap = 8,
    this.iconSize = 13,
    this.hover,
    this.pressed,
    this.confirmFor = const Duration(milliseconds: 1400),
    this.disabledOpacity = 0.38,
  });

  /// The chip the code sits on — a quiet neutral, not a card.
  final SurfaceStyle surface;

  final TextStyle textStyle;

  /// The copy button's focus ring.
  final Color ring;

  final EdgeInsetsGeometry padding;

  /// The space between the code and its copy button.
  final double gap;

  final double iconSize;

  /// The copy button's washes.
  final Color? hover;
  final Color? pressed;

  /// How long the copy button holds the confirmation glyph before going
  /// back to offering the copy.
  final Duration confirmFor;

  final double disabledOpacity;

  CodeTextStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? textStyle,
    Color? ring,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    Color? hover,
    Color? pressed,
    Duration? confirmFor,
    double? disabledOpacity,
  }) => CodeTextStyle(
    surface: surface ?? this.surface,
    textStyle: textStyle ?? this.textStyle,
    ring: ring ?? this.ring,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    confirmFor: confirmFor ?? this.confirmFor,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is CodeTextStyle &&
      other.surface == surface &&
      other.textStyle == textStyle &&
      other.ring == ring &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.confirmFor == confirmFor &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hash(
    surface,
    textStyle,
    ring,
    padding,
    gap,
    iconSize,
    hover,
    pressed,
    confirmFor,
    disabledOpacity,
  );
}
