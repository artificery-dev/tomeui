import 'package:tomeui/tomeui.dart';

/// The resolved values an [EmptyState] paints. The choosing happened in
/// [EmptyStateResolver], at `theme.widgets.emptyState`.
@immutable
class EmptyStateStyle {
  const EmptyStateStyle({
    required this.titleStyle,
    required this.messageStyle,
    required this.glyph,
    this.iconSize = 32,
    this.gap = 12,
    this.actionGap = 24,
    this.maxWidth = 320,
    this.padding = const EdgeInsets.all(24),
  });

  final TextStyle titleStyle;
  final TextStyle messageStyle;

  /// The glyph's colour — quiet, because an empty state is not an error.
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
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    Color? glyph,
    double? iconSize,
    double? gap,
    double? actionGap,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
  }) => EmptyStateStyle(
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
