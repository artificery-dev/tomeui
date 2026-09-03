import 'package:tomeui/tomeui.dart';

/// When a [Link] draws its underline.
///
/// [hover] is the default: a link in running text is already findable by
/// color, and a page of permanently underlined links reads as a ransom
/// note. [always] is for links that have to survive a colorblind reader
/// with no context; [never] for links that are obviously links — a
/// breadcrumb, a card that is entirely one target.
enum LinkUnderline { always, hover, never }

/// The resolved values a [Link] paints: the type it wears at rest, the type
/// it wears under the pointer, and the ring it takes when focused.
///
/// Colors, not choices — the choosing happened in [LinkResolver], at
/// `theme.widgets.link`.
@immutable
class LinkStyle {
  const LinkStyle({
    required this.textStyle,
    required this.hovered,
    required this.ring,
    this.ringRadius = const BorderRadius.all(Radius.circular(6)),
    this.underline = LinkUnderline.hover,
    this.gap = 4,
    this.iconSize = 13,
    this.disabledOpacity = 0.38,
  });

  /// The link at rest.
  final TextStyle textStyle;

  /// The link under the pointer, or focused — a step brighter, and where
  /// [LinkUnderline.hover] earns its name.
  final TextStyle hovered;

  /// The focus ring, and the corners it runs concentric to.
  final Color ring;
  final BorderRadius ringRadius;

  final LinkUnderline underline;

  /// The space before the external-link glyph.
  final double gap;

  /// The external-link glyph's size — the small icon, since it rides text.
  final double iconSize;

  final double disabledOpacity;

  LinkStyle copyWith({
    TextStyle? textStyle,
    TextStyle? hovered,
    Color? ring,
    BorderRadius? ringRadius,
    LinkUnderline? underline,
    double? gap,
    double? iconSize,
    double? disabledOpacity,
  }) => LinkStyle(
    textStyle: textStyle ?? this.textStyle,
    hovered: hovered ?? this.hovered,
    ring: ring ?? this.ring,
    ringRadius: ringRadius ?? this.ringRadius,
    underline: underline ?? this.underline,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is LinkStyle &&
      other.textStyle == textStyle &&
      other.hovered == hovered &&
      other.ring == ring &&
      other.ringRadius == ringRadius &&
      other.underline == underline &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hash(
    textStyle,
    hovered,
    ring,
    ringRadius,
    underline,
    gap,
    iconSize,
    disabledOpacity,
  );
}
