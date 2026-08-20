import 'package:tomeui/tomeui.dart';

/// The resolved values a [MenuBar] strip paints — the panels it opens are
/// dressed by [MenuStyle]. The choosing happened in [MenuBarResolver], at
/// `theme.widgets.menuBar`.
@immutable
class MenuBarStyle {
  const MenuBarStyle({
    required this.menu,
    required this.textStyle,
    this.height = 28,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.gap = 2,
    this.radius = const BorderRadius.all(Radius.circular(6)),
    required this.ring,
    this.open,
    this.hover,
    this.pressed,
  });

  /// The panels this bar drops.
  final MenuStyle menu;

  final TextStyle textStyle;

  final double height;

  /// Inside one trigger, around its word.
  final EdgeInsetsGeometry padding;

  /// Between triggers.
  final double gap;

  final BorderRadius radius;

  final Color ring;

  /// Behind the trigger whose menu is showing — it stays lit while you
  /// read the panel it opened.
  final Color? open;

  final Color? hover;
  final Color? pressed;

  MenuBarStyle copyWith({
    MenuStyle? menu,
    TextStyle? textStyle,
    double? height,
    EdgeInsetsGeometry? padding,
    double? gap,
    BorderRadius? radius,
    Color? ring,
    Color? open,
    Color? hover,
    Color? pressed,
  }) => MenuBarStyle(
    menu: menu ?? this.menu,
    textStyle: textStyle ?? this.textStyle,
    height: height ?? this.height,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    radius: radius ?? this.radius,
    ring: ring ?? this.ring,
    open: open ?? this.open,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
  );

  @override
  bool operator ==(Object other) =>
      other is MenuBarStyle &&
      other.menu == menu &&
      other.textStyle == textStyle &&
      other.height == height &&
      other.padding == padding &&
      other.gap == gap &&
      other.radius == radius &&
      other.ring == ring &&
      other.open == open &&
      other.hover == hover &&
      other.pressed == pressed;

  @override
  int get hashCode => Object.hash(
    menu,
    textStyle,
    height,
    padding,
    gap,
    radius,
    ring,
    open,
    hover,
    pressed,
  );
}
