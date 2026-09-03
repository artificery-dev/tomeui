import 'package:tomeui/tomeui.dart';

/// The resolved values an [EmptyState] paints. The choosing happened in
/// [EmptyStateResolver], at `theme.widgets.emptyState`.
@immutable
class EmptyStateStyle {
  const EmptyStateStyle({
    required this.surface,
    required this.titleStyle,
    required this.messageStyle,
    required this.glyph,
    this.iconSize = 32,
    this.gap = 12,
    this.actionGap = 24,
    this.maxWidth = 320,
    this.padding = const EdgeInsets.all(24),
  });

  /// The panel the words sit on — [SurfaceVariant.ghost] by default, which
  /// is no panel at all: an empty state is usually the slot's own emptiness
  /// rather than a thing placed in it.
  final SurfaceStyle surface;

  final TextStyle titleStyle;
  final TextStyle messageStyle;

  /// The glyph's color — quiet, because an empty state is not an error.
  final Color glyph;

  final double iconSize;

  /// Between the glyph, the title, and the message.
  final double gap;

  /// Between the words and whatever you can do about them.
  final double actionGap;

  /// The widest the words wrap to. An empty state is read at a glance and
  /// a full-width line of it isn't.
  final double maxWidth;

  final EdgeInsetsGeometry padding;

  EmptyStateStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    Color? glyph,
    double? iconSize,
    double? gap,
    double? actionGap,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
  }) => EmptyStateStyle(
    surface: surface ?? this.surface,
    titleStyle: titleStyle ?? this.titleStyle,
    messageStyle: messageStyle ?? this.messageStyle,
    glyph: glyph ?? this.glyph,
    iconSize: iconSize ?? this.iconSize,
    gap: gap ?? this.gap,
    actionGap: actionGap ?? this.actionGap,
    maxWidth: maxWidth ?? this.maxWidth,
    padding: padding ?? this.padding,
  );

  @override
  bool operator ==(Object other) =>
      other is EmptyStateStyle &&
      other.surface == surface &&
      other.titleStyle == titleStyle &&
      other.messageStyle == messageStyle &&
      other.glyph == glyph &&
      other.iconSize == iconSize &&
      other.gap == gap &&
      other.actionGap == actionGap &&
      other.maxWidth == maxWidth &&
      other.padding == padding;

  @override
  int get hashCode => Object.hash(
    surface,
    titleStyle,
    messageStyle,
    glyph,
    iconSize,
    gap,
    actionGap,
    maxWidth,
    padding,
  );
}
