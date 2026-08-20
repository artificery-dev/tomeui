import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';

/// The resolved values a [CommandPalette] paints. The choosing happened in
/// [CommandPaletteResolver], at `theme.widgets.commandPalette`.
@immutable
class CommandPaletteStyle {
  const CommandPaletteStyle({
    required this.surface,
    required this.field,
    required this.menu,
    required this.emptyStyle,
    required this.hintStyle,
    this.width = 560,
    this.maxHeight = 400,
    this.padding = const EdgeInsets.all(8),
    this.topInset = 96,
    required this.scrim,
    this.shadow = const [],
  });

  /// The panel itself.
  final SurfaceStyle surface;

  /// The field across its top.
  final TextFieldStyle field;

  /// The rows below it, which are menu rows by another name.
  final MenuStyle menu;

  /// What "nothing matches" is said in.
  final TextStyle emptyStyle;

  /// A command's shortcut hint, at the trailing end of its row.
  final TextStyle hintStyle;

  final double width;

  /// The tallest the list of commands grows before it scrolls.
  final double maxHeight;

  /// Around the rows, inside the panel.
  final EdgeInsetsGeometry padding;

  /// How far down the window the panel sits. A palette belongs near the
  /// top — it's a thing you summon and dismiss, not a page.
  final double topInset;

  /// Over the page behind.
  final Color scrim;

  final List<BoxShadow> shadow;

  CommandPaletteStyle copyWith({
    SurfaceStyle? surface,
    TextFieldStyle? field,
    MenuStyle? menu,
    TextStyle? emptyStyle,
    TextStyle? hintStyle,
    double? width,
    double? maxHeight,
    EdgeInsetsGeometry? padding,
    double? topInset,
    Color? scrim,
    List<BoxShadow>? shadow,
  }) => CommandPaletteStyle(
    surface: surface ?? this.surface,
    field: field ?? this.field,
    menu: menu ?? this.menu,
    emptyStyle: emptyStyle ?? this.emptyStyle,
    hintStyle: hintStyle ?? this.hintStyle,
    width: width ?? this.width,
    maxHeight: maxHeight ?? this.maxHeight,
    padding: padding ?? this.padding,
    topInset: topInset ?? this.topInset,
    scrim: scrim ?? this.scrim,
    shadow: shadow ?? this.shadow,
  );

  @override
  bool operator ==(Object other) =>
      other is CommandPaletteStyle &&
      other.surface == surface &&
      other.field == field &&
      other.menu == menu &&
      other.emptyStyle == emptyStyle &&
      other.hintStyle == hintStyle &&
      other.width == width &&
      other.maxHeight == maxHeight &&
      other.padding == padding &&
      other.topInset == topInset &&
      other.scrim == scrim &&
      listEquals(other.shadow, shadow);

  @override
  int get hashCode => Object.hash(
    surface,
    field,
    menu,
    emptyStyle,
    hintStyle,
    width,
    maxHeight,
    padding,
    topInset,
    scrim,
    Object.hashAll(shadow),
  );
}
