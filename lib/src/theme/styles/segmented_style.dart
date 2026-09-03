import 'package:tomeui/tomeui.dart';

/// The resolved values a [SegmentedControl] paints: the track the segments
/// sit in, the indicator that slides between them, and what a segment's
/// words wear on either side of the change.
///
/// Colors, not choices — the choosing happened in [SegmentedResolver], at
/// `theme.widgets.segmented`.
@immutable
class SegmentedControlStyle {
  const SegmentedControlStyle({
    required this.track,
    required this.indicator,
    required this.selectedStyle,
    required this.unselectedStyle,
    required this.ring,
    this.height = 36,
    this.inset = 3,
    this.segmentPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.gap = 8,
    this.iconSize = 16,
    this.hover,
    this.pressed,
    this.disabledOpacity = 0.38,
  });

  /// The trough all the segments share.
  final SurfaceStyle track;

  /// The one segment's worth of dress that slides to the chosen answer.
  final SurfaceStyle indicator;

  /// The chosen segment's words, and everyone else's. Two styles rather
  /// than one plus an emphasis, because the chosen segment is read against
  /// the indicator and the rest against the track.
  final TextStyle selectedStyle;
  final TextStyle unselectedStyle;

  /// The focus ring — the control takes one focus stop, not one per
  /// segment, so the ring goes round the whole track.
  final Color ring;

  final double height;

  /// The track's own margin, which is what the indicator sits inside.
  final double inset;

  final EdgeInsetsGeometry segmentPadding;

  /// Between a segment's leading icon and its label.
  final double gap;

  final double iconSize;

  /// A segment's washes, under the pointer.
  final Color? hover;
  final Color? pressed;

  final double disabledOpacity;

  SegmentedControlStyle copyWith({
    SurfaceStyle? track,
    SurfaceStyle? indicator,
    TextStyle? selectedStyle,
    TextStyle? unselectedStyle,
    Color? ring,
    double? height,
    double? inset,
    EdgeInsetsGeometry? segmentPadding,
    double? gap,
    double? iconSize,
    Color? hover,
    Color? pressed,
    double? disabledOpacity,
  }) => SegmentedControlStyle(
    track: track ?? this.track,
    indicator: indicator ?? this.indicator,
    selectedStyle: selectedStyle ?? this.selectedStyle,
    unselectedStyle: unselectedStyle ?? this.unselectedStyle,
    ring: ring ?? this.ring,
    height: height ?? this.height,
    inset: inset ?? this.inset,
    segmentPadding: segmentPadding ?? this.segmentPadding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is SegmentedControlStyle &&
      other.track == track &&
      other.indicator == indicator &&
      other.selectedStyle == selectedStyle &&
      other.unselectedStyle == unselectedStyle &&
      other.ring == ring &&
      other.height == height &&
      other.inset == inset &&
      other.segmentPadding == segmentPadding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hash(
    track,
    indicator,
    selectedStyle,
    unselectedStyle,
    ring,
    height,
    inset,
    segmentPadding,
    gap,
    iconSize,
    hover,
    pressed,
    disabledOpacity,
  );
}
