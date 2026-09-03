import 'package:tomeui/tomeui.dart';

/// The resolved values a [StatusChip] paints. The choosing happened in
/// [ChipResolver], at `theme.widgets.chip`.
@immutable
class ChipStyle {
  const ChipStyle({
    required this.surface,
    required this.textStyle,
    this.height = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.gap = 4,
    this.iconSize = 12,
    this.dotSize = 6,
  });

  /// The pill itself.
  final SurfaceStyle surface;

  final TextStyle textStyle;

  final double height;
  final EdgeInsetsGeometry padding;

  /// Between the mark and the words.
  final double gap;

  final double iconSize;

  /// A plain round mark, for a chip whose meaning is the color rather
  /// than a glyph.
  final double dotSize;

  ChipStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? textStyle,
    double? height,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    double? dotSize,
  }) => ChipStyle(
    surface: surface ?? this.surface,
    textStyle: textStyle ?? this.textStyle,
    height: height ?? this.height,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    dotSize: dotSize ?? this.dotSize,
  );

  @override
  bool operator ==(Object other) =>
      other is ChipStyle &&
      other.surface == surface &&
      other.textStyle == textStyle &&
      other.height == height &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.dotSize == dotSize;

  @override
  int get hashCode =>
      Object.hash(surface, textStyle, height, padding, gap, iconSize, dotSize);
}
