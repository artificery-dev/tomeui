import 'package:tomeui/tomeui.dart';

/// The resolved values a [Tabs] strip paints. The choosing happened in
/// [TabsResolver], at `theme.widgets.tabs`.
@immutable
class TabsStyle {
  const TabsStyle({
    required this.selectedStyle,
    required this.unselectedStyle,
    required this.selected,
    required this.unselected,
    this.tabGap = 0,
    this.closeSize = 18,
    this.closeIconSize = 12,
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
  /// The tab you're on: the swatch at full voice, because it's the page
  /// you're looking at rather than one of the ways to it.
  final SurfaceStyle selected;

  /// The hairline the whole strip sits on, which the indicator interrupts.
  /// The rest: the quietest surface there is, so a strip of them reads as
  /// a row of words on a page rather than a row of buttons.
  final SurfaceStyle unselected;

  /// Between one tab and the next. Nought by default: tabs sit shoulder to
  /// shoulder, and the notch their rounded tops leave is the only daylight
  /// between them.
  final double tabGap;

  /// The box a tab's close button keeps, and the cross inside it.
  final double closeSize;
  final double closeIconSize;

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
    SurfaceStyle? selected,
    SurfaceStyle? unselected,
    double? tabGap,
    double? closeSize,
    double? closeIconSize,
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
    selected: selected ?? this.selected,
    unselected: unselected ?? this.unselected,
    tabGap: tabGap ?? this.tabGap,
    closeSize: closeSize ?? this.closeSize,
    closeIconSize: closeIconSize ?? this.closeIconSize,
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
      other.selected == selected &&
      other.unselected == unselected &&
      other.tabGap == tabGap &&
      other.closeSize == closeSize &&
      other.closeIconSize == closeIconSize &&
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
    selected,
    unselected,
    tabGap,
    closeSize,
    closeIconSize,
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
