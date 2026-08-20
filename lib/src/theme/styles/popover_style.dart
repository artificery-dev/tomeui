import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';

/// Which side of its anchor a [Popover] prefers. Preference, not promise:
/// a popover with no room on its chosen side flips to the opposite one.
enum PopoverSide { top, bottom, left, right }

/// How a [Popover] lines up along its anchor's edge — leading, centred, or
/// trailing. It slides off this to stay on screen.
enum PopoverAlign { start, center, end }

/// What a [Popover] puts between its panel and the page underneath.
enum PopoverBarrier {
  /// Nothing, and the panel takes no pointer either: an annotation over a
  /// page that carries on as though it weren't there. What a tooltip wants.
  none,

  /// The page is sealed off. A tap outside dismisses instead of landing,
  /// and the panel holds the keyboard, which is what puts Escape within
  /// reach. What a menu or a select wants.
  blocking,

  /// A tap outside dismisses *and* lands, and the page still answers the
  /// pointer's hovering. What a menu bar wants: clicking the next word
  /// should open its menu rather than merely closing this one, and running
  /// the pointer along the bar should walk the menus.
  through,
}

/// The resolved values a [Popover] actually paints, plus the geometry it
/// places itself by. The choosing happened in [PopoverResolver], at
/// `theme.widgets.popover`.
@immutable
class PopoverStyle {
  const PopoverStyle({
    required this.surface,
    this.padding = const EdgeInsets.all(8),
    this.gap = 8,
    this.margin = 8,
    this.maxWidth = 320,
    this.shadow = const [],
  });

  /// The floating panel itself: fill, border, corners, and the foreground
  /// its contents speak.
  final SurfaceStyle surface;

  /// Inside the panel, around its content.
  final EdgeInsetsGeometry padding;

  /// The daylight between the panel and its anchor.
  final double gap;

  /// How close the panel may come to the screen's edge before it slides
  /// back inward.
  final double margin;

  /// The widest the panel grows before its content wraps.
  final double maxWidth;

  /// The elevation it floats at.
  final List<BoxShadow> shadow;

  PopoverStyle copyWith({
    SurfaceStyle? surface,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? margin,
    double? maxWidth,
    List<BoxShadow>? shadow,
  }) => PopoverStyle(
    surface: surface ?? this.surface,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    margin: margin ?? this.margin,
    maxWidth: maxWidth ?? this.maxWidth,
    shadow: shadow ?? this.shadow,
  );

  @override
  bool operator ==(Object other) =>
      other is PopoverStyle &&
      other.surface == surface &&
      other.padding == padding &&
      other.gap == gap &&
      other.margin == margin &&
      other.maxWidth == maxWidth &&
      listEquals(other.shadow, shadow);

  @override
  int get hashCode => Object.hash(
    surface,
    padding,
    gap,
    margin,
    maxWidth,
    Object.hashAll(shadow),
  );
}

/// The resolved values a [Tooltip] paints. A tooltip is a [Popover] that
/// speaks quietly and briefly, so it carries a popover's geometry plus the
/// waiting it does before appearing.
@immutable
class TooltipStyle {
  const TooltipStyle({
    required this.popover,
    required this.textStyle,
    this.wait = const Duration(milliseconds: 500),
  });

  /// The panel, its padding, and where it sits.
  final PopoverStyle popover;

  /// What the message wears.
  final TextStyle textStyle;

  /// How long the pointer must rest before the tooltip speaks. Nothing to
  /// say to a pointer just passing through.
  final Duration wait;

  TooltipStyle copyWith({
    PopoverStyle? popover,
    TextStyle? textStyle,
    Duration? wait,
  }) => TooltipStyle(
    popover: popover ?? this.popover,
    textStyle: textStyle ?? this.textStyle,
    wait: wait ?? this.wait,
  );

  @override
  bool operator ==(Object other) =>
      other is TooltipStyle &&
      other.popover == popover &&
      other.textStyle == textStyle &&
      other.wait == wait;

  @override
  int get hashCode => Object.hash(popover, textStyle, wait);
}
