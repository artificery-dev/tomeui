import 'package:tomeui/tomeui.dart';

/// The resolved values a [Badge] paints. The choosing happened in
/// [BadgeResolver], at `theme.widgets.badge`.
@immutable
class BadgeStyle {
  const BadgeStyle({
    required this.surface,
    required this.textStyle,
    this.size = 16,
    this.dotSize = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
    this.offset = const Offset(4, -4),
  });

  /// The badge itself — a stadium, so a two-digit count stretches it
  /// rather than crowding.
  final SurfaceStyle surface;

  final TextStyle textStyle;

  /// The height of a badge with something written on it, and its width
  /// when that something is one character.
  final double size;

  /// A badge with nothing written on it at all: something happened, and
  /// the count isn't the point.
  final double dotSize;

  final EdgeInsetsGeometry padding;

  /// How far past the corner of what it's riding on the badge sits —
  /// out and up, so it clears the thing without leaving it.
  final Offset offset;

  BadgeStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? textStyle,
    double? size,
    double? dotSize,
    EdgeInsetsGeometry? padding,
    Offset? offset,
  }) => BadgeStyle(
    surface: surface ?? this.surface,
    textStyle: textStyle ?? this.textStyle,
    size: size ?? this.size,
    dotSize: dotSize ?? this.dotSize,
    padding: padding ?? this.padding,
    offset: offset ?? this.offset,
  );

  @override
  bool operator ==(Object other) =>
      other is BadgeStyle &&
      other.surface == surface &&
      other.textStyle == textStyle &&
      other.size == size &&
      other.dotSize == dotSize &&
      other.padding == padding &&
      other.offset == offset;

  @override
  int get hashCode =>
      Object.hash(surface, textStyle, size, dotSize, padding, offset);
}
