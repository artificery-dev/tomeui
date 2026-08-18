import 'package:tomeui/tomeui.dart';

/// The resolved values a [TextField] paints: the box the text sits in, the
/// type of everything around it, and the colours editing needs — the caret,
/// the selection, the ring.
///
/// Colours, not choices — the choosing happened in [TextFieldResolver], at
/// `theme.widgets.textField`.
@immutable
class TextFieldStyle {
  const TextFieldStyle({
    required this.surface,
    required this.textStyle,
    required this.placeholderStyle,
    required this.labelStyle,
    required this.helperStyle,
    required this.errorStyle,
    required this.ring,
    required this.cursor,
    required this.selection,
    this.height = 36,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.multilinePadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.gap = 8,
    this.labelGap = 4,
    this.helperGap = 4,
    this.iconSize = 16,
    this.handleSize = 20,
    this.hover,
    this.disabledOpacity = 0.38,
  });

  /// The box: fill, border, corners, and the colour its icons wear.
  final SurfaceStyle surface;

  /// What's typed. Carries the page's text colour rather than the surface's
  /// tinted foreground — a field's *content* is content, not chrome.
  final TextStyle textStyle;

  /// What stands in for content that isn't there yet.
  final TextStyle placeholderStyle;

  /// The words above the box, and the words below it.
  final TextStyle labelStyle;
  final TextStyle helperStyle;

  /// What's wrong, in the error swatch — the box wears it too.
  final TextStyle errorStyle;

  final Color ring;

  /// The caret.
  final Color cursor;

  /// Behind selected text.
  final Color selection;

  /// A single-line field's height. Past one line the box grows instead.
  final double height;

  final EdgeInsetsGeometry padding;

  /// Multi-line fields pad top and bottom too: text that wraps needs room
  /// above and below, where a single line is centred in its height.
  final EdgeInsetsGeometry multilinePadding;

  /// Between the box's slots.
  final double gap;

  final double labelGap;
  final double helperGap;
  final double iconSize;

  /// How big the selection grips are on a touch screen — and so how much of
  /// them there is to grab.
  final double handleSize;

  /// Washed over the fill while the pointer rests here.
  final Color? hover;

  final double disabledOpacity;

  TextFieldStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? textStyle,
    TextStyle? placeholderStyle,
    TextStyle? labelStyle,
    TextStyle? helperStyle,
    TextStyle? errorStyle,
    Color? ring,
    Color? cursor,
    Color? selection,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? multilinePadding,
    double? gap,
    double? labelGap,
    double? helperGap,
    double? iconSize,
    double? handleSize,
    Color? hover,
    double? disabledOpacity,
  }) => TextFieldStyle(
    surface: surface ?? this.surface,
    textStyle: textStyle ?? this.textStyle,
    placeholderStyle: placeholderStyle ?? this.placeholderStyle,
    labelStyle: labelStyle ?? this.labelStyle,
    helperStyle: helperStyle ?? this.helperStyle,
    errorStyle: errorStyle ?? this.errorStyle,
    ring: ring ?? this.ring,
    cursor: cursor ?? this.cursor,
    selection: selection ?? this.selection,
    height: height ?? this.height,
    padding: padding ?? this.padding,
    multilinePadding: multilinePadding ?? this.multilinePadding,
    gap: gap ?? this.gap,
    labelGap: labelGap ?? this.labelGap,
    helperGap: helperGap ?? this.helperGap,
    iconSize: iconSize ?? this.iconSize,
    handleSize: handleSize ?? this.handleSize,
    hover: hover ?? this.hover,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is TextFieldStyle &&
      other.surface == surface &&
      other.textStyle == textStyle &&
      other.placeholderStyle == placeholderStyle &&
      other.labelStyle == labelStyle &&
      other.helperStyle == helperStyle &&
      other.errorStyle == errorStyle &&
      other.ring == ring &&
      other.cursor == cursor &&
      other.selection == selection &&
      other.height == height &&
      other.padding == padding &&
      other.multilinePadding == multilinePadding &&
      other.gap == gap &&
      other.labelGap == labelGap &&
      other.helperGap == helperGap &&
      other.iconSize == iconSize &&
      other.handleSize == handleSize &&
      other.hover == hover &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hashAll([
    surface,
    textStyle,
    placeholderStyle,
    labelStyle,
    helperStyle,
    errorStyle,
    ring,
    cursor,
    selection,
    height,
    padding,
    multilinePadding,
    gap,
    labelGap,
    helperGap,
    iconSize,
    handleSize,
    hover,
    disabledOpacity,
  ]);
}
