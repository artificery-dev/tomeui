import 'package:tomeui/tomeui.dart';

/// The resolved values a [Progress] draws. The choosing happened in
/// [ProgressResolver], at `theme.widgets.progress`.
@immutable
class ProgressStyle {
  const ProgressStyle({
    required this.track,
    required this.indicator,
    this.thickness = 4,
    this.spinnerSize = 20,
    this.spinnerThickness = 2,
    this.radius = const BorderRadius.all(Radius.circular(999)),
    this.minWidth = 120,
    required this.period,
  });

  /// The groove the bar runs in, and the ring a spinner turns against.
  final Color track;

  /// The part that has happened.
  final Color indicator;

  final double thickness;

  final double spinnerSize;
  final double spinnerThickness;

  final BorderRadius radius;

  /// The narrowest a bar goes where its slot won't say how wide it is.
  final double minWidth;

  /// One turn of the spinner, and one sweep of an indeterminate bar.
  final Duration period;

  ProgressStyle copyWith({
    Color? track,
    Color? indicator,
    double? thickness,
    double? spinnerSize,
    double? spinnerThickness,
    BorderRadius? radius,
    double? minWidth,
    Duration? period,
  }) => ProgressStyle(
    track: track ?? this.track,
    indicator: indicator ?? this.indicator,
    thickness: thickness ?? this.thickness,
    spinnerSize: spinnerSize ?? this.spinnerSize,
    spinnerThickness: spinnerThickness ?? this.spinnerThickness,
    radius: radius ?? this.radius,
    minWidth: minWidth ?? this.minWidth,
    period: period ?? this.period,
  );

  @override
  bool operator ==(Object other) =>
      other is ProgressStyle &&
      other.track == track &&
      other.indicator == indicator &&
      other.thickness == thickness &&
      other.spinnerSize == spinnerSize &&
      other.spinnerThickness == spinnerThickness &&
      other.radius == radius &&
      other.minWidth == minWidth &&
      other.period == period;

  @override
  int get hashCode => Object.hash(
    track,
    indicator,
    thickness,
    spinnerSize,
    spinnerThickness,
    radius,
    minWidth,
    period,
  );
}
