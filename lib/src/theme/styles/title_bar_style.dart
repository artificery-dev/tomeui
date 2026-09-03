import 'package:tomeui/tomeui.dart';

/// The resolved values a [TitleBar] paints. The choosing happened in
/// [TitleBarResolver], at `theme.widgets.titleBar`.
///
/// `package:window_manager` exports a `TitleBarStyle` too — an enum for the
/// *native* bar, which an app hides in order to draw this one. An app that
/// imports both hides one of the names; nothing in Tome touches the plugin
/// (that lives behind [WindowShell], in `package:tomeui_desktop`).
@immutable
class TitleBarStyle {
  const TitleBarStyle({
    required this.surface,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.gap = 8,
    required this.titleStyle,
    required this.subtitleStyle,
    this.controlSize = 32,
    this.controlIconSize = 14,
    this.glyphStroke = 1,
    required this.controlRing,
    this.controlHover,
    this.controlPressed,
    this.closeHover,
    this.closePressed,
  });

  /// The band itself — a bar wears the chrome color, not the page's.
  final SurfaceStyle surface;

  final double height;
  final EdgeInsetsGeometry padding;

  /// Between the bar's own slots.
  final double gap;

  final TextStyle titleStyle;

  /// The quieter line under the title, for the document's context.
  final TextStyle subtitleStyle;

  /// A window button's box, and the glyph inside it — smaller than a
  /// control, since these belong to the window rather than to the page.
  final double controlSize;
  final double controlIconSize;

  /// How heavy the painted window shapes are drawn — a hairline, the way
  /// every desktop draws them. Ignored where the theme names a glyph
  /// instead ([Icons.windowMinimize]).
  final double glyphStroke;

  final Color controlRing;
  final Color? controlHover;
  final Color? controlPressed;

  /// Closing is the one window button that answers in a color: red under
  /// the pointer, the way every desktop draws it.
  final Color? closeHover;
  final Color? closePressed;

  TitleBarStyle copyWith({
    SurfaceStyle? surface,
    double? height,
    EdgeInsetsGeometry? padding,
    double? gap,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    double? controlSize,
    double? controlIconSize,
    double? glyphStroke,
    Color? controlRing,
    Color? controlHover,
    Color? controlPressed,
    Color? closeHover,
    Color? closePressed,
  }) => TitleBarStyle(
    surface: surface ?? this.surface,
    height: height ?? this.height,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    titleStyle: titleStyle ?? this.titleStyle,
    subtitleStyle: subtitleStyle ?? this.subtitleStyle,
    controlSize: controlSize ?? this.controlSize,
    controlIconSize: controlIconSize ?? this.controlIconSize,
    glyphStroke: glyphStroke ?? this.glyphStroke,
    controlRing: controlRing ?? this.controlRing,
    controlHover: controlHover ?? this.controlHover,
    controlPressed: controlPressed ?? this.controlPressed,
    closeHover: closeHover ?? this.closeHover,
    closePressed: closePressed ?? this.closePressed,
  );

  @override
  bool operator ==(Object other) =>
      other is TitleBarStyle &&
      other.surface == surface &&
      other.height == height &&
      other.padding == padding &&
      other.gap == gap &&
      other.titleStyle == titleStyle &&
      other.subtitleStyle == subtitleStyle &&
      other.controlSize == controlSize &&
      other.controlIconSize == controlIconSize &&
      other.glyphStroke == glyphStroke &&
      other.controlRing == controlRing &&
      other.controlHover == controlHover &&
      other.controlPressed == controlPressed &&
      other.closeHover == closeHover &&
      other.closePressed == closePressed;

  @override
  int get hashCode => Object.hash(
    surface,
    height,
    padding,
    gap,
    titleStyle,
    subtitleStyle,
    controlSize,
    controlIconSize,
    glyphStroke,
    controlRing,
    controlHover,
    controlPressed,
    closeHover,
    closePressed,
  );
}
