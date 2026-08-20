import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';

/// The resolved values a [Dialog] paints. The choosing happened in
/// [DialogResolver], at `theme.widgets.dialog`.
@immutable
class DialogStyle {
  const DialogStyle({
    required this.surface,
    required this.titleStyle,
    required this.messageStyle,
    this.width = 520,
    this.padding = const EdgeInsets.all(24),
    this.gap = 16,
    this.actionGap = 8,
    this.margin = 24,
    required this.scrim,
    this.shadow = const [],
  });

  /// The panel itself.
  final SurfaceStyle surface;

  final TextStyle titleStyle;

  /// The line under the title: what the dialog is actually asking.
  final TextStyle messageStyle;

  final double width;
  final EdgeInsetsGeometry padding;

  /// Between the title, the content, and the actions.
  final double gap;

  /// Between the actions themselves.
  final double actionGap;

  /// How close the panel may come to the screen's edge.
  final double margin;

  /// Over the page behind.
  final Color scrim;

  final List<BoxShadow> shadow;

  DialogStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    double? width,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? actionGap,
    double? margin,
    Color? scrim,
    List<BoxShadow>? shadow,
  }) => DialogStyle(
    surface: surface ?? this.surface,
    titleStyle: titleStyle ?? this.titleStyle,
    messageStyle: messageStyle ?? this.messageStyle,
    width: width ?? this.width,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    actionGap: actionGap ?? this.actionGap,
    margin: margin ?? this.margin,
    scrim: scrim ?? this.scrim,
    shadow: shadow ?? this.shadow,
  );

  @override
  bool operator ==(Object other) =>
      other is DialogStyle &&
      other.surface == surface &&
      other.titleStyle == titleStyle &&
      other.messageStyle == messageStyle &&
      other.width == width &&
      other.padding == padding &&
      other.gap == gap &&
      other.actionGap == actionGap &&
      other.margin == margin &&
      other.scrim == scrim &&
      listEquals(other.shadow, shadow);

  @override
  int get hashCode => Object.hash(
    surface,
    titleStyle,
    messageStyle,
    width,
    padding,
    gap,
    actionGap,
    margin,
    scrim,
    Object.hashAll(shadow),
  );
}
