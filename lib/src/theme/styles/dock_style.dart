import 'package:tomeui/tomeui.dart';

/// The resolved values a [Dock] paints and measures by. The choosing
/// happened in [DockResolver], at `theme.widgets.dock`.
@immutable
class DockStyle {
  const DockStyle({
    required this.surface,
    required this.indicator,
    required this.selectedStyle,
    required this.unselectedStyle,
    this.itemExtent = 80,
    this.thickness = 64,
    this.padding = const EdgeInsets.all(8),
    this.gap = 4,
    this.iconSize = 20,
    this.indicatorPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 4,
    ),
    required this.ring,
    this.hover,
    this.pressed,
    this.disabledOpacity = 0.38,
  });

  /// The band the destinations sit on.
  final SurfaceStyle surface;

  /// The pill behind the chosen destination's icon.
  final SurfaceStyle indicator;

  final TextStyle selectedStyle;
  final TextStyle unselectedStyle;

  /// How much of the run one destination takes — the measurement the dock
  /// counts with, since what doesn't fit goes to the overflow menu rather
  /// than off the end.
  final double itemExtent;

  /// Across the run: a bottom bar's height, a rail's width.
  final double thickness;

  final EdgeInsetsGeometry padding;

  /// Between a destination's icon and its label.
  final double gap;

  final double iconSize;

  /// Around the icon, inside the indicator pill.
  final EdgeInsetsGeometry indicatorPadding;

  final Color ring;
  final Color? hover;
  final Color? pressed;
  final double disabledOpacity;

  DockStyle copyWith({
    SurfaceStyle? surface,
    SurfaceStyle? indicator,
    TextStyle? selectedStyle,
    TextStyle? unselectedStyle,
    double? itemExtent,
    double? thickness,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    EdgeInsetsGeometry? indicatorPadding,
    Color? ring,
    Color? hover,
    Color? pressed,
    double? disabledOpacity,
  }) => DockStyle(
    surface: surface ?? this.surface,
    indicator: indicator ?? this.indicator,
    selectedStyle: selectedStyle ?? this.selectedStyle,
    unselectedStyle: unselectedStyle ?? this.unselectedStyle,
    itemExtent: itemExtent ?? this.itemExtent,
    thickness: thickness ?? this.thickness,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    indicatorPadding: indicatorPadding ?? this.indicatorPadding,
    ring: ring ?? this.ring,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is DockStyle &&
      other.surface == surface &&
      other.indicator == indicator &&
      other.selectedStyle == selectedStyle &&
      other.unselectedStyle == unselectedStyle &&
      other.itemExtent == itemExtent &&
      other.thickness == thickness &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.indicatorPadding == indicatorPadding &&
      other.ring == ring &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hash(
    surface,
    indicator,
    selectedStyle,
    unselectedStyle,
    itemExtent,
    thickness,
    padding,
    gap,
    iconSize,
    indicatorPadding,
    ring,
    hover,
    pressed,
    disabledOpacity,
  );
}
