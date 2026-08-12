import 'package:flutter/widgets.dart';

/// The type scale, as swappable tokens.
///
/// Every style carries size, weight, and leading — never a colour and never a
/// family, so the same scale works over any palette and under any font an app
/// ships. The defaults are tuned for a UI face at interface sizes; swap the
/// whole scale by constructing your own, or adjust one style with [copyWith].
@immutable
class TomeTypography {
  const TomeTypography({
    this.display = const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.4,
    ),
    this.headline = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    this.title = const TextStyle(
      fontSize: 16.5,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    this.subtitle = const TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      height: 1.35,
    ),
    this.body = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    this.bodySmall = const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    this.label = const TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.2,
    ),
    this.caption = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.35,
    ),
    this.code = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.45,
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Consolas', 'Roboto Mono'],
    ),
  });

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

  TomeTypography copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? subtitle,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? code,
  }) => TomeTypography(
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
  static const TomeTypography standard = TomeTypography();
}
