import 'package:tomeui/tomeui.dart';

/// The resolved values a [Skeleton] paints. The choosing happened in
/// [SkeletonResolver], at `theme.widgets.skeleton`.
@immutable
class SkeletonStyle {
  const SkeletonStyle({
    required this.fill,
    required this.sheen,
    this.radius = const BorderRadius.all(Radius.circular(6)),
    this.lineHeight = 12,
    this.lineGap = 8,
    this.lastLineFraction = 0.6,
    this.sheenWidth = 0.6,
    this.sheenPass = 0.55,
    required this.period,
  });

  /// The resting color of a shape that isn't there yet.
  final Color fill;

  /// The light that travels across it — a bright color at a low alpha,
  /// which the widget blends *onto* [fill] rather than interpolating
  /// towards. A gradient that runs from an opaque color to a translucent
  /// one is brightest halfway between the two, so a sweep painted that way
  /// arrives as two bright shoulders around a dark core.
  final Color sheen;

  final BorderRadius radius;

  /// One line of stand-in text, and the space under it.
  final double lineHeight;
  final double lineGap;

  /// How much of the width the last line of a paragraph takes, since real
  /// paragraphs don't end flush.
  final double lastLineFraction;

  /// How much of the shape the light covers at once, as a fraction of its
  /// width. Wide enough to read as a sweep, narrow enough to be a light.
  final double sheenWidth;

  /// The share of [period] the light spends crossing. The rest of it the
  /// shape sits at rest — a sheen that never leaves reads as a pattern
  /// rather than a passing light.
  final double sheenPass;

  /// One pass of the sheen across the shape, and the beat after it.
  final Duration period;

  SkeletonStyle copyWith({
    Color? fill,
    Color? sheen,
    BorderRadius? radius,
    double? lineHeight,
    double? lineGap,
    double? lastLineFraction,
    double? sheenWidth,
    double? sheenPass,
    Duration? period,
  }) => SkeletonStyle(
    fill: fill ?? this.fill,
    sheen: sheen ?? this.sheen,
    radius: radius ?? this.radius,
    lineHeight: lineHeight ?? this.lineHeight,
    lineGap: lineGap ?? this.lineGap,
    lastLineFraction: lastLineFraction ?? this.lastLineFraction,
    sheenWidth: sheenWidth ?? this.sheenWidth,
    sheenPass: sheenPass ?? this.sheenPass,
    period: period ?? this.period,
  );

  @override
  bool operator ==(Object other) =>
      other is SkeletonStyle &&
      other.fill == fill &&
      other.sheen == sheen &&
      other.radius == radius &&
      other.lineHeight == lineHeight &&
      other.lineGap == lineGap &&
      other.lastLineFraction == lastLineFraction &&
      other.sheenWidth == sheenWidth &&
      other.sheenPass == sheenPass &&
      other.period == period;

  @override
  int get hashCode => Object.hash(
    fill,
    sheen,
    radius,
    lineHeight,
    lineGap,
    lastLineFraction,
    sheenWidth,
    sheenPass,
    period,
  );
}
