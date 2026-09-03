import 'package:tomeui/tomeui.dart';

/// The resolved values a [Slider] paints: the track either side of the
/// thumb, the thumb itself, and the geometry it all travels through.
///
/// Colors, not choices — the choosing happened in [SliderResolver], at
/// `theme.widgets.slider`.
@immutable
class SliderStyle {
  const SliderStyle({
    required this.active,
    required this.inactive,
    required this.thumb,
    required this.ring,
    this.trackHeight = 6,
    this.thumbSize = 18,
    this.height = 36,
    this.minWidth = 160,
    this.tick,
    this.tickSize = 3,
    this.hover,
    this.pressed,
    this.disabledOpacity = 0.38,
    this.lift = 0.08,
  });

  /// Behind the thumb: how far along the value has come, in the swatch.
  final SurfaceStyle active;

  /// Ahead of it — filled, never hollow. A track exists at every value,
  /// the way a switch's does in both positions.
  final SurfaceStyle inactive;

  /// The grip. It wears the active track's foreground, so it reads against
  /// the swatch it sits on the same way a switch's thumb does.
  final SurfaceStyle thumb;

  /// The focus ring, and the corners it runs concentric to — the thumb's,
  /// since the thumb is the part the keyboard moves.
  final Color ring;

  final double trackHeight;
  final double thumbSize;

  /// The control's own height. Taller than the track on purpose: what a
  /// slider *responds* to is a band, not a hairline.
  final double height;

  /// The width to take when the slot doesn't say — a slider in an
  /// unbounded row still has to be some length.
  final double minWidth;

  /// The marks a divided slider puts on its track. Null draws none.
  final Color? tick;
  final double tickSize;

  /// The thumb's washes.
  final Color? hover;
  final Color? pressed;

  final double disabledOpacity;

  /// How far the thumb rises toward the pointer.
  final double lift;

  SliderStyle copyWith({
    SurfaceStyle? active,
    SurfaceStyle? inactive,
    SurfaceStyle? thumb,
    Color? ring,
    double? trackHeight,
    double? thumbSize,
    double? height,
    double? minWidth,
    Color? tick,
    double? tickSize,
    Color? hover,
    Color? pressed,
    double? disabledOpacity,
    double? lift,
  }) => SliderStyle(
    active: active ?? this.active,
    inactive: inactive ?? this.inactive,
    thumb: thumb ?? this.thumb,
    ring: ring ?? this.ring,
    trackHeight: trackHeight ?? this.trackHeight,
    thumbSize: thumbSize ?? this.thumbSize,
    height: height ?? this.height,
    minWidth: minWidth ?? this.minWidth,
    tick: tick ?? this.tick,
    tickSize: tickSize ?? this.tickSize,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    lift: lift ?? this.lift,
  );

  @override
  bool operator ==(Object other) =>
      other is SliderStyle &&
      other.active == active &&
      other.inactive == inactive &&
      other.thumb == thumb &&
      other.ring == ring &&
      other.trackHeight == trackHeight &&
      other.thumbSize == thumbSize &&
      other.height == height &&
      other.minWidth == minWidth &&
      other.tick == tick &&
      other.tickSize == tickSize &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.disabledOpacity == disabledOpacity &&
      other.lift == lift;

  @override
  int get hashCode => Object.hash(
    active,
    inactive,
    thumb,
    ring,
    trackHeight,
    thumbSize,
    height,
    minWidth,
    tick,
    tickSize,
    hover,
    pressed,
    disabledOpacity,
    lift,
  );
}
