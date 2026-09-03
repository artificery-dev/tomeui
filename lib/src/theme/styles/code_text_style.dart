import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';

/// The resolved values a [CodeText] paints: the chip it sits in, the
/// monospace it wears, the dressing of its copy affordance, and — for the
/// block shape — the card, the gutter, and the color every syntax scope
/// speaks in.
///
/// Colors, not choices — the choosing happened in [CodeTextResolver], at
/// `theme.widgets.code`.
@immutable
class CodeTextStyle {
  const CodeTextStyle({
    required this.surface,
    required this.textStyle,
    required this.ring,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.gap = 8,
    this.iconSize = 13,
    this.hover,
    this.pressed,
    this.confirmFor = const Duration(milliseconds: 1400),
    this.disabledOpacity = 0.38,
    this.blockSurface,
    this.blockPadding = const EdgeInsets.all(16),
    this.syntax = const {},
    this.gutterStyle = const TextStyle(),
    this.gutterGap = 16,
    this.gutterDivider = const Color(0x00000000),
    this.gutterDividerThickness = 1,
    this.lineHighlight = const Color(0x00000000),
  });

  /// The chip the code sits on — a quiet neutral, not a card.
  final SurfaceStyle surface;

  final TextStyle textStyle;

  /// The copy button's focus ring.
  final Color ring;

  final EdgeInsetsGeometry padding;

  /// The space between the code and its copy button.
  final double gap;

  final double iconSize;

  /// The copy button's washes.
  final Color? hover;
  final Color? pressed;

  /// How long the copy button holds the confirmation glyph before going
  /// back to offering the copy.
  final Duration confirmFor;

  final double disabledOpacity;

  /// The card a block sits on, where the inline shape gets [surface]'s
  /// chip. Null falls back to [surface] — a theme that only wants one
  /// treatment says so by leaving this alone.
  final SurfaceStyle? blockSurface;

  final EdgeInsetsGeometry blockPadding;

  /// What each syntax scope wears, keyed by highlight.js scope name
  /// (`keyword`, `string`, `title.function`). A scope with no entry keeps
  /// [textStyle], so a partial map is a legal map and an unhighlighted
  /// block is just an empty one.
  final Map<String, TextStyle> syntax;

  /// The line numbers, and the hairline that separates them from the code.
  final TextStyle gutterStyle;
  final double gutterGap;
  final Color gutterDivider;
  final double gutterDividerThickness;

  /// The wash behind a called-out line.
  final Color lineHighlight;

  /// The card a block actually paints — [blockSurface] if the theme set
  /// one, the chip otherwise.
  SurfaceStyle get block => blockSurface ?? surface;

  CodeTextStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? textStyle,
    Color? ring,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    Color? hover,
    Color? pressed,
    Duration? confirmFor,
    double? disabledOpacity,
    SurfaceStyle? blockSurface,
    EdgeInsetsGeometry? blockPadding,
    Map<String, TextStyle>? syntax,
    TextStyle? gutterStyle,
    double? gutterGap,
    Color? gutterDivider,
    double? gutterDividerThickness,
    Color? lineHighlight,
  }) => CodeTextStyle(
    surface: surface ?? this.surface,
    textStyle: textStyle ?? this.textStyle,
    ring: ring ?? this.ring,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    confirmFor: confirmFor ?? this.confirmFor,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    blockSurface: blockSurface ?? this.blockSurface,
    blockPadding: blockPadding ?? this.blockPadding,
    syntax: syntax ?? this.syntax,
    gutterStyle: gutterStyle ?? this.gutterStyle,
    gutterGap: gutterGap ?? this.gutterGap,
    gutterDivider: gutterDivider ?? this.gutterDivider,
    gutterDividerThickness:
        gutterDividerThickness ?? this.gutterDividerThickness,
    lineHighlight: lineHighlight ?? this.lineHighlight,
  );

  @override
  bool operator ==(Object other) =>
      other is CodeTextStyle &&
      other.surface == surface &&
      other.textStyle == textStyle &&
      other.ring == ring &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.confirmFor == confirmFor &&
      other.disabledOpacity == disabledOpacity &&
      other.blockSurface == blockSurface &&
      other.blockPadding == blockPadding &&
      mapEquals(other.syntax, syntax) &&
      other.gutterStyle == gutterStyle &&
      other.gutterGap == gutterGap &&
      other.gutterDivider == gutterDivider &&
      other.gutterDividerThickness == gutterDividerThickness &&
      other.lineHighlight == lineHighlight;

  @override
  int get hashCode => Object.hash(
    surface,
    textStyle,
    ring,
    padding,
    gap,
    iconSize,
    hover,
    pressed,
    confirmFor,
    disabledOpacity,
    blockSurface,
    blockPadding,
    Object.hashAllUnordered(syntax.keys),
    gutterStyle,
    gutterGap,
    gutterDivider,
    gutterDividerThickness,
    lineHighlight,
  );
}
