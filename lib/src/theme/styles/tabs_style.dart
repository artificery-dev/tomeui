import 'package:tomeui/tomeui.dart';

/// The resolved values a [Tabs] strip paints. The choosing happened in
/// [TabsResolver], at `theme.widgets.tabs`.
@immutable
class TabsStyle {
  const TabsStyle({
    required this.selectedStyle,
    required this.unselectedStyle,
    required this.indicator,
    this.indicatorThickness = 2,
    required this.rule,
    this.ruleThickness = 1,
    this.height = 40,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.gap = 8,
    this.iconSize = 16,
    this.radius = const BorderRadius.only(
      topLeft: Radius.circular(6),
      topRight: Radius.circular(6),
    ),
    required this.ring,
    this.hover,
    this.pressed,
    this.disabledOpacity = 0.38,
  });

  final TextStyle selectedStyle;
  final TextStyle unselectedStyle;

  /// The line under the chosen tab.
  final Color indicator;
  final double indicatorThickness;

  /// The hairline the whole strip sits on, which the indicator interrupts.
  final Color rule;
  final double ruleThickness;

  final double height;

  /// Inside one tab, around its label.
  final EdgeInsetsGeometry padding;

  /// Between a tab's icon and its label.
  final double gap;

  final double iconSize;

  /// A tab's own corners — rounded at the top, square where it meets the
  /// rule.
  final BorderRadius radius;

  final Color ring;
  final Color? hover;
  final Color? pressed;
  final double disabledOpacity;

  TabsStyle copyWith({
    TextStyle? selectedStyle,
    TextStyle? unselectedStyle,
    Color? indicator,
    double? indicatorThickness,
    Color? rule,
    double? ruleThickness,
    double? height,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    BorderRadius? radius,
    Color? ring,
    Color? hover,
    Color? pressed,
    double? disabledOpacity,
  }) => TabsStyle(
    selectedStyle: selectedStyle ?? this.selectedStyle,
    unselectedStyle: unselectedStyle ?? this.unselectedStyle,
    indicator: indicator ?? this.indicator,
    indicatorThickness: indicatorThickness ?? this.indicatorThickness,
    rule: rule ?? this.rule,
    ruleThickness: ruleThickness ?? this.ruleThickness,
    height: height ?? this.height,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    radius: radius ?? this.radius,
    ring: ring ?? this.ring,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is TabsStyle &&
      other.selectedStyle == selectedStyle &&
      other.unselectedStyle == unselectedStyle &&
      other.indicator == indicator &&
      other.indicatorThickness == indicatorThickness &&
      other.rule == rule &&
      other.ruleThickness == ruleThickness &&
      other.height == height &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.radius == radius &&
      other.ring == ring &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hash(
    selectedStyle,
    unselectedStyle,
    indicator,
    indicatorThickness,
    rule,
    ruleThickness,
    height,
    padding,
    gap,
    iconSize,
    radius,
    ring,
    hover,
    pressed,
    disabledOpacity,
  );
}
