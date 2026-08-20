import 'package:tomeui/tomeui.dart';

/// The resolved values a [Breadcrumbs] trail paints. The choosing happened
/// in [BreadcrumbsResolver], at `theme.widgets.breadcrumbs`.
@immutable
class BreadcrumbsStyle {
  const BreadcrumbsStyle({
    required this.textStyle,
    required this.currentStyle,
    required this.separator,
    this.separatorSize = 14,
    this.gap = 4,
    this.iconSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.iconGap = 4,
    this.radius = const BorderRadius.all(Radius.circular(6)),
    required this.ring,
    this.hover,
    this.pressed,
  });

  /// What a crumb behind you wears — quiet, because it's a way back rather
  /// than where you are.
  final TextStyle textStyle;

  /// The last crumb: where you are, and not a button.
  final TextStyle currentStyle;

  final Color separator;
  final double separatorSize;

  /// Either side of a separator.
  final double gap;

  final double iconSize;

  /// Around a crumb's own words, which is the area that lights up.
  final EdgeInsetsGeometry padding;

  /// Between a crumb's icon and its label.
  final double iconGap;

  final BorderRadius radius;

  final Color ring;
  final Color? hover;
  final Color? pressed;

  BreadcrumbsStyle copyWith({
    TextStyle? textStyle,
    TextStyle? currentStyle,
    Color? separator,
    double? separatorSize,
    double? gap,
    double? iconSize,
    EdgeInsetsGeometry? padding,
    double? iconGap,
    BorderRadius? radius,
    Color? ring,
    Color? hover,
    Color? pressed,
  }) => BreadcrumbsStyle(
    textStyle: textStyle ?? this.textStyle,
    currentStyle: currentStyle ?? this.currentStyle,
    separator: separator ?? this.separator,
    separatorSize: separatorSize ?? this.separatorSize,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    padding: padding ?? this.padding,
    iconGap: iconGap ?? this.iconGap,
    radius: radius ?? this.radius,
    ring: ring ?? this.ring,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
  );

  @override
  bool operator ==(Object other) =>
      other is BreadcrumbsStyle &&
      other.textStyle == textStyle &&
      other.currentStyle == currentStyle &&
      other.separator == separator &&
      other.separatorSize == separatorSize &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.padding == padding &&
      other.iconGap == iconGap &&
      other.radius == radius &&
      other.ring == ring &&
      other.hover == hover &&
      other.pressed == pressed;

  @override
  int get hashCode => Object.hash(
    textStyle,
    currentStyle,
    separator,
    separatorSize,
    gap,
    iconSize,
    padding,
    iconGap,
    radius,
    ring,
    hover,
    pressed,
  );
}
