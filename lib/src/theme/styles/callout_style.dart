import 'package:tomeui/tomeui.dart';

/// The resolved values a [Callout] paints. The choosing happened in
/// [CalloutResolver], at `theme.widgets.callout`.
@immutable
class CalloutStyle {
  const CalloutStyle({
    required this.surface,
    required this.titleStyle,
    required this.messageStyle,
    this.padding = const EdgeInsets.all(16),
    this.gap = 12,
    this.textGap = 4,
    this.actionGap = 8,
    this.iconSize = 20,
    this.dismissIconSize = 16,
  });

  /// The block itself, tinted in the swatch it was given.
  final SurfaceStyle surface;

  final TextStyle titleStyle;
  final TextStyle messageStyle;

  final EdgeInsetsGeometry padding;

  /// Between the glyph, the words, and whatever trails them.
  final double gap;

  /// Between the title and its message.
  final double textGap;

  /// Between the actions in the row that finishes the block.
  final double actionGap;

  /// The leading glyph, sized to the title it sits beside.
  final double iconSize;

  /// The close glyph, which is smaller: putting a notice away is the
  /// quietest thing on it.
  final double dismissIconSize;

  CalloutStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? textGap,
    double? actionGap,
    double? iconSize,
    double? dismissIconSize,
  }) => CalloutStyle(
    surface: surface ?? this.surface,
    titleStyle: titleStyle ?? this.titleStyle,
    messageStyle: messageStyle ?? this.messageStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    textGap: textGap ?? this.textGap,
    actionGap: actionGap ?? this.actionGap,
    iconSize: iconSize ?? this.iconSize,
    dismissIconSize: dismissIconSize ?? this.dismissIconSize,
  );

  @override
  bool operator ==(Object other) =>
      other is CalloutStyle &&
      other.surface == surface &&
      other.titleStyle == titleStyle &&
      other.messageStyle == messageStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.textGap == textGap &&
      other.actionGap == actionGap &&
      other.iconSize == iconSize &&
      other.dismissIconSize == dismissIconSize;

  @override
  int get hashCode => Object.hash(
    surface,
    titleStyle,
    messageStyle,
    padding,
    gap,
    textGap,
    actionGap,
    iconSize,
    dismissIconSize,
  );
}
