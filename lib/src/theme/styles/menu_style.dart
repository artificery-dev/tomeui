import 'package:tomeui/tomeui.dart';

/// The resolved values a [Menu] paints: the panel it floats in, the shape
/// of a row, and the two quieter voices a menu needs — the shortcut hint
/// and the section label.
///
/// Colors, not choices — the choosing happened in [MenuResolver], at
/// `theme.widgets.menu`.
@immutable
class MenuStyle {
  const MenuStyle({
    required this.popover,
    required this.highlight,
    required this.separator,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    this.itemGap = 8,
    this.itemRadius = const BorderRadius.all(Radius.circular(6)),
    this.trailingStyle = const TextStyle(),
    this.sectionStyle = const TextStyle(),
    this.sectionPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    this.separatorThickness = 1,
    this.separatorMargin = const EdgeInsets.symmetric(vertical: 4),
    this.iconSize = 16,
    this.minWidth = 176,
    this.maxHeight = 260,
    this.disabledOpacity = 0.38,
  });

  /// The floating panel the entries sit in.
  final PopoverStyle popover;

  /// Behind the row the pointer or the keyboard is on.
  final Color highlight;

  /// The hairline between groups of entries.
  final Color separator;

  final EdgeInsetsGeometry itemPadding;

  /// Between an item's icon, its label, and its shortcut hint.
  final double itemGap;

  final BorderRadius itemRadius;

  /// The shortcut hint: present, but never competing with the label.
  final TextStyle trailingStyle;

  /// The label over a group of entries.
  final TextStyle sectionStyle;
  final EdgeInsetsGeometry sectionPadding;

  final double separatorThickness;
  final EdgeInsetsGeometry separatorMargin;

  /// What a leading icon is sized to.
  final double iconSize;

  /// A menu narrower than this reads as a tooltip that someone can click.
  final double minWidth;

  /// Past this the entries scroll.
  final double maxHeight;

  final double disabledOpacity;

  MenuStyle copyWith({
    PopoverStyle? popover,
    Color? highlight,
    Color? separator,
    EdgeInsetsGeometry? itemPadding,
    double? itemGap,
    BorderRadius? itemRadius,
    TextStyle? trailingStyle,
    TextStyle? sectionStyle,
    EdgeInsetsGeometry? sectionPadding,
    double? separatorThickness,
    EdgeInsetsGeometry? separatorMargin,
    double? iconSize,
    double? minWidth,
    double? maxHeight,
    double? disabledOpacity,
  }) => MenuStyle(
    popover: popover ?? this.popover,
    highlight: highlight ?? this.highlight,
    separator: separator ?? this.separator,
    itemPadding: itemPadding ?? this.itemPadding,
    itemGap: itemGap ?? this.itemGap,
    itemRadius: itemRadius ?? this.itemRadius,
    trailingStyle: trailingStyle ?? this.trailingStyle,
    sectionStyle: sectionStyle ?? this.sectionStyle,
    sectionPadding: sectionPadding ?? this.sectionPadding,
    separatorThickness: separatorThickness ?? this.separatorThickness,
    separatorMargin: separatorMargin ?? this.separatorMargin,
    iconSize: iconSize ?? this.iconSize,
    minWidth: minWidth ?? this.minWidth,
    maxHeight: maxHeight ?? this.maxHeight,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is MenuStyle &&
      other.popover == popover &&
      other.highlight == highlight &&
      other.separator == separator &&
      other.itemPadding == itemPadding &&
      other.itemGap == itemGap &&
      other.itemRadius == itemRadius &&
      other.trailingStyle == trailingStyle &&
      other.sectionStyle == sectionStyle &&
      other.sectionPadding == sectionPadding &&
      other.separatorThickness == separatorThickness &&
      other.separatorMargin == separatorMargin &&
      other.iconSize == iconSize &&
      other.minWidth == minWidth &&
      other.maxHeight == maxHeight &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hash(
    popover,
    highlight,
    separator,
    itemPadding,
    itemGap,
    itemRadius,
    trailingStyle,
    sectionStyle,
    sectionPadding,
    separatorThickness,
    separatorMargin,
    iconSize,
    minWidth,
    maxHeight,
    disabledOpacity,
  );
}
