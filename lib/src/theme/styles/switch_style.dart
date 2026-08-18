import 'package:tomeui/tomeui.dart';

/// The resolved values a [Switch] actually paints: the track in both of its
/// states, the thumb that rides it, and the interaction dressing around
/// them. Colours, not choices — the choosing happened in [SwitchResolver],
/// at `theme.widgets.switch_`.
///
/// Construct one directly (or [copyWith] a resolved one) for custom
/// everything, via `Switch.custom`.
@immutable
class SwitchStyle {
  const SwitchStyle({
    required this.on,
    required this.off,
    this.width = 40,
    this.height = 24,
    this.thumb = 18,
    this.gap = 8,
    required this.ring,
    this.hover,
    this.pressed,
    this.disabledOpacity = 0.38,
    this.lift = 0.04,
  });

  /// The track when the switch is on: the swatch, at full voice.
  final SurfaceStyle on;

  /// The track when it's off — filled, never hollow. A switch is a physical
  /// thing; its track exists in both positions.
  final SurfaceStyle off;

  final double width;
  final double height;

  /// The thumb's diameter. It wears the track's foreground, so it reads in
  /// both positions.
  final double thumb;

  /// The space between the track and its label.
  final double gap;

  /// The focus ring — the swatch at full voice.
  final Color ring;

  /// Washed over the track while the pointer rests here.
  final Color? hover;

  /// Washed over the track while pressed.
  final Color? pressed;

  final double disabledOpacity;

  /// How far the track rises toward the pointer.
  final double lift;

  /// The room left around the thumb, from the track's height.
  double get inset => (height - thumb) / 2;

  SwitchStyle copyWith({
    SurfaceStyle? on,
    SurfaceStyle? off,
    double? width,
    double? height,
    double? thumb,
    double? gap,
    Color? ring,
    Color? hover,
    Color? pressed,
    double? disabledOpacity,
    double? lift,
  }) => SwitchStyle(
    on: on ?? this.on,
    off: off ?? this.off,
    width: width ?? this.width,
    height: height ?? this.height,
    thumb: thumb ?? this.thumb,
    gap: gap ?? this.gap,
    ring: ring ?? this.ring,
    hover: hover ?? this.hover,
    pressed: pressed ?? this.pressed,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    lift: lift ?? this.lift,
  );

  @override
  bool operator ==(Object other) =>
      other is SwitchStyle &&
      other.on == on &&
      other.off == off &&
      other.width == width &&
      other.height == height &&
      other.thumb == thumb &&
      other.gap == gap &&
      other.ring == ring &&
      other.hover == hover &&
      other.pressed == pressed &&
      other.disabledOpacity == disabledOpacity &&
      other.lift == lift;

  @override
  int get hashCode => Object.hash(
    on,
    off,
    width,
    height,
    thumb,
    gap,
    ring,
    hover,
    pressed,
    disabledOpacity,
    lift,
  );
}
