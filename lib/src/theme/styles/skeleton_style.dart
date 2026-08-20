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
    required this.period,
  });

  /// The resting colour of a shape that isn't there yet.
  final Color fill;

  /// The light that travels across it. Brighter than [fill] and partly
  /// transparent, so the sweep reads as a highlight rather than a second
  /// shape sliding past.
  final Color sheen;

  final BorderRadius radius;

  /// One line of stand-in text, and the space under it.
  final double lineHeight;
  final double lineGap;

  /// How much of the width the last line of a paragraph takes, since real
  /// paragraphs don't end flush.
  final double lastLineFraction;

  /// One pass of the sheen across the shape.
  final Duration period;

  SkeletonStyle copyWith({
    Color? fill,
    Color? sheen,
    BorderRadius? radius,
    double? lineHeight,
    double? lineGap,
    double? lastLineFraction,
    Duration? period,
  }) => SkeletonStyle(
    fill: fill ?? this.fill,
    sheen: sheen ?? this.sheen,
    radius: radius ?? this.radius,
    lineHeight: lineHeight ?? this.lineHeight,
    lineGap: lineGap ?? this.lineGap,
    lastLineFraction: lastLineFraction ?? this.lastLineFraction,
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
      other.period == period;

  @override
  int get hashCode => Object.hash(
    fill,
    sheen,
    radius,
    lineHeight,
    lineGap,
    lastLineFraction,
    period,
  );
}
