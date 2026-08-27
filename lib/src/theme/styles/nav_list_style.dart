import 'package:tomeui/tomeui.dart';

/// How large a [NavList] sits: its icons, its type, and the room around
/// them, scaled together. [medium] is the default.
enum NavListSize {
  /// 16px icons.
  small,

  /// 20px icons.
  medium,

  /// 24px icons.
  large,
}

/// The resolved values a [NavList] paints. The choosing happened in
/// [NavListResolver], at `theme.widgets.navList`.
@immutable
class NavListStyle {
  const NavListStyle({
    required this.selected,
    required this.selectedStyle,
    required this.textStyle,
    required this.headingStyle,
    required this.separator,
    this.rowHeight = 32,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.gap = 8,
    this.indent = 20,
    this.iconSize = 16,
    this.radius = const BorderRadius.all(Radius.circular(6)),
    this.headingPadding = const EdgeInsets.fromLTRB(8, 12, 8, 4),
    required this.ring,
    this.highlight,
    this.hover,
    this.pressed,
    this.disabledOpacity = 0.38,
  });

  /// Behind the row you're on.
  final SurfaceStyle selected;

  final TextStyle selectedStyle;
  final TextStyle textStyle;

  /// A [NavHeading]'s small print.
  final TextStyle headingStyle;

  /// A [NavSeparator]'s rule.
  final Color separator;

  final double rowHeight;

  /// Inside a row, around its contents.
  final EdgeInsetsGeometry padding;

  /// Between a row's glyph and its words.
  final double gap;

  /// How far a group's destinations sit in from the group itself.
  final double indent;

  final double iconSize;
  final BorderRadius radius;

  /// Around a heading, which needs more air above it than below.
  final EdgeInsetsGeometry headingPadding;

  final Color ring;

  /// Behind the row the keyboard is on, which is not the row you're on.
  final Color? highlight;

  final Color? hover;
  final Color? pressed;
  final double disabledOpacity;

  NavListStyle copyWith({
    SurfaceStyle? selected,
    TextStyle? selectedStyle,
    TextStyle? textStyle,
    TextStyle? headingStyle,
    Color? separator,
    double? rowHeight,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? indent,
    double? iconSize,
    BorderRadius? radius,
    EdgeInsetsGeometry? headingPadding,
    Color? ring,
    Color? highlight,
    Color? hover,
    Color? pressed,
    double? disabledOpacity,
  }) => NavListStyle(
    selected: selected ?? this.selected,
    selectedStyle: selectedStyle ?? this.selectedStyle,
    textStyle: textStyle ?? this.textStyle,
    headingStyle: headingStyle ?? this.headingStyle,
    separator: separator ?? this.separator,
    rowHeight: rowHeight ?? this.rowHeight,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    indent: indent ?? this.indent,
    iconSize: iconSize ?? this.iconSize,
    radius: radius ?? this.radius,
    headingPadding: headingPadding ?? this.headingPadding,
    ring: ring ?? this.ring,
    highlight: highlight ?? this.highlight,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is NavListStyle &&
      other.selected == selected &&
      other.selectedStyle == selectedStyle &&
      other.textStyle == textStyle &&
      other.headingStyle == headingStyle &&
      other.separator == separator &&
      other.rowHeight == rowHeight &&
      other.padding == padding &&
      other.gap == gap &&
      other.indent == indent &&
      other.iconSize == iconSize &&
      other.radius == radius &&
      other.headingPadding == headingPadding &&
      other.ring == ring &&
      other.highlight == highlight &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hash(
    selected,
    selectedStyle,
    textStyle,
    headingStyle,
    separator,
    rowHeight,
    padding,
    gap,
    indent,
    iconSize,
    radius,
    headingPadding,
    ring,
    Object.hash(highlight, hover, pressed, disabledOpacity),
  );
}
