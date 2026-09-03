import 'package:flutter/widgets.dart';

/// The type scale, as swappable tokens.
///
/// Every style carries size, weight, and leading — never a color and never a
/// family, so the same scale works over any palette and under any font an app
/// ships. The defaults are tuned for a UI face at interface sizes; swap the
/// whole scale by constructing your own, or adjust one style with [copyWith].
///
/// Leading is distributed evenly above and below the glyphs
/// ([TextLeadingDistribution.even]), so text sits truly centerd inside a
/// padded box — a [Surface] pill, a button — instead of hanging from the
/// font's own ascent.
@immutable
class Typography {
  const Typography({
    this.display = const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.2,
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: -0.4,
    ),
    this.headline = const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.25,
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: -0.2,
    ),
    this.title = const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    this.subtitle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 1.35,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    this.body = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    this.bodySmall = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.45,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    this.label = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.45,
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: 0.2,
    ),
    this.caption = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.35,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    this.code = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      leadingDistribution: TextLeadingDistribution.even,
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Consolas', 'Roboto Mono'],
    ),
  });

  /// The same scale dressed in Recursive, the variable face this package
  /// bundles: one file serves every style, and [code] becomes Recursive
  /// Mono through the MONO axis rather than a second family.
  ///
  /// The wght axis is pinned per style — Recursive's default instance
  /// rests at 300, so a style that only *asked* for w600 without setting
  /// the axis could render light under an engine that doesn't map weight
  /// onto variable axes.
  const Typography.recursive()
    : this(
        display: const TextStyle(
          fontFamily: _recursive,
          fontVariations: [FontVariation('wght', 600)],
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 1.2,
          leadingDistribution: TextLeadingDistribution.even,
          letterSpacing: -0.4,
        ),
        headline: const TextStyle(
          fontFamily: _recursive,
          fontVariations: [FontVariation('wght', 600)],
          fontSize: 26,
          fontWeight: FontWeight.w600,
          height: 1.25,
          leadingDistribution: TextLeadingDistribution.even,
          letterSpacing: -0.2,
        ),
        title: const TextStyle(
          fontFamily: _recursive,
          fontVariations: [FontVariation('wght', 600)],
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.3,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        subtitle: const TextStyle(
          fontFamily: _recursive,
          fontVariations: [FontVariation('wght', 500)],
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.35,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        body: const TextStyle(
          fontFamily: _recursive,
          fontVariations: [FontVariation('wght', 400)],
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        bodySmall: const TextStyle(
          fontFamily: _recursive,
          fontVariations: [FontVariation('wght', 400)],
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.45,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        label: const TextStyle(
          fontFamily: _recursive,
          fontVariations: [FontVariation('wght', 500)],
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.45,
          leadingDistribution: TextLeadingDistribution.even,
          letterSpacing: 0.2,
        ),
        caption: const TextStyle(
          fontFamily: _recursive,
          fontVariations: [FontVariation('wght', 400)],
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.35,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        code: const TextStyle(
          fontFamily: _recursive,
          fontVariations: [
            FontVariation('MONO', 1),
            FontVariation('wght', 400),
          ],
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      );

  /// The bundled family, addressed the way package fonts are.
  static const _recursive = 'packages/tomeui/Recursive';

  /// The one large statement on a screen: an empty-state headline, a number
  /// worth a glance from across the room.
  final TextStyle display;

  /// A screen or section heading.
  final TextStyle headline;

  /// A card or dialog title.
  final TextStyle title;

  /// The line under a title, or a list row's primary line.
  final TextStyle subtitle;

  /// Running text. The default for anything unstyled.
  final TextStyle body;

  /// Body, where space is tight: dense lists, table cells.
  final TextStyle bodySmall;

  /// Buttons, chips, tabs — text that names a control.
  final TextStyle label;

  /// Metadata: timestamps, counts, footnotes.
  final TextStyle caption;

  /// Paths, identifiers, and code. The only style that names a family,
  /// because monospace *is* the token; override it to ship your own face.
  final TextStyle code;

  Typography copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? subtitle,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? code,
  }) => Typography(
    display: display ?? this.display,
    headline: headline ?? this.headline,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    body: body ?? this.body,
    bodySmall: bodySmall ?? this.bodySmall,
    label: label ?? this.label,
    caption: caption ?? this.caption,
    code: code ?? this.code,
  );

  /// The default scale.
  static const Typography standard = Typography();
}
