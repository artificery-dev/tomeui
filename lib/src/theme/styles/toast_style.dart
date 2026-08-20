import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';

/// Which corner — or edge — a [Toaster] stacks its toasts in.
enum ToastPosition {
  topLeading,
  topCenter,
  topTrailing,
  bottomLeading,
  bottomCenter,
  bottomTrailing;

  /// Whether this position is along the top, which is also the end a toast
  /// slides in from.
  bool get isTop => index < 3;
}

/// The resolved values a [Toast] paints, and the geometry the [Toaster]
/// stacks them by. The choosing happened in [ToastResolver], at
/// `theme.widgets.toast`.
@immutable
class ToastStyle {
  const ToastStyle({
    required this.surface,
    required this.messageStyle,
    this.padding = const EdgeInsets.all(12),
    this.gap = 12,
    this.iconSize = 18,
    this.width = 360,
    this.stackGap = 8,
    this.margin = const EdgeInsets.all(16),
    this.position = ToastPosition.bottomTrailing,
    this.life = const Duration(seconds: 4),
    this.maxVisible = 3,
    this.shadow = const [],
  });

  /// The toast itself.
  final SurfaceStyle surface;

  final TextStyle messageStyle;

  final EdgeInsetsGeometry padding;

  /// Between the glyph, the words, and the action.
  final double gap;

  final double iconSize;

  /// How wide a toast is. Fixed, so a stack of them is a stack of one
  /// shape rather than a ragged pile.
  final double width;

  /// Between two toasts in the stack.
  final double stackGap;

  /// Between the stack and the corner it sits in.
  final EdgeInsetsGeometry margin;

  /// Where the stack lives.
  final ToastPosition position;

  /// How long a toast stays before it takes itself away. A toast with an
  /// action gets longer, since it's asking to be acted on.
  final Duration life;

  /// How many toasts show at once. Past that they queue: a screen of
  /// toasts is a screen nobody reads.
  final int maxVisible;

  final List<BoxShadow> shadow;

  ToastStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? messageStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    double? width,
    double? stackGap,
    EdgeInsetsGeometry? margin,
    ToastPosition? position,
    Duration? life,
    int? maxVisible,
    List<BoxShadow>? shadow,
  }) => ToastStyle(
    surface: surface ?? this.surface,
    messageStyle: messageStyle ?? this.messageStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    width: width ?? this.width,
    stackGap: stackGap ?? this.stackGap,
    margin: margin ?? this.margin,
    position: position ?? this.position,
    life: life ?? this.life,
    maxVisible: maxVisible ?? this.maxVisible,
    shadow: shadow ?? this.shadow,
  );

  @override
  bool operator ==(Object other) =>
      other is ToastStyle &&
      other.surface == surface &&
      other.messageStyle == messageStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.width == width &&
      other.stackGap == stackGap &&
      other.margin == margin &&
      other.position == position &&
      other.life == life &&
      other.maxVisible == maxVisible &&
      listEquals(other.shadow, shadow);

  @override
  int get hashCode => Object.hash(
    surface,
    messageStyle,
    padding,
    gap,
    iconSize,
    width,
    stackGap,
    margin,
    position,
    life,
    maxVisible,
    Object.hashAll(shadow),
  );
}
