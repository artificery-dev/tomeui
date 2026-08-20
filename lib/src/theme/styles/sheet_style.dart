import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';

/// Which edge a [Sheet] comes in from.
enum SheetSide {
  /// Up from the bottom — the phone's answer to a menu, and the one a
  /// finger can throw back down.
  bottom,

  /// In from the reading direction's near edge.
  leading,

  /// In from its far edge — where a desktop puts an inspector it doesn't
  /// have room to dock.
  trailing,
}

/// The resolved values a [Sheet] paints. The choosing happened in
/// [SheetResolver], at `theme.widgets.sheet`.
@immutable
class SheetStyle {
  const SheetStyle({
    required this.surface,
    required this.titleStyle,
    this.padding = const EdgeInsets.all(24),
    this.gap = 16,
    this.radius = const Radius.circular(20),
    this.size = 400,
    this.maxFraction = 0.9,
    required this.grabber,
    this.grabberSize = const Size(36, 4),
    required this.scrim,
    this.shadow = const [],
  });

  /// The panel itself. Its corners are the style's [radius], applied only
  /// to the edges that aren't against the screen.
  final SurfaceStyle surface;

  final TextStyle titleStyle;

  final EdgeInsetsGeometry padding;

  /// Between the grabber, the title, and the content.
  final double gap;

  /// The corners on the sheet's free edges.
  final Radius radius;

  /// How far the sheet comes in: a side sheet's width, and the height a
  /// bottom sheet takes when its content would take more.
  final double size;

  /// The most of the screen a sheet may cover along its own axis — past
  /// that it's a page, and should be pushed as one.
  final double maxFraction;

  /// The bar a bottom sheet is dragged by.
  final Color grabber;
  final Size grabberSize;

  final Color scrim;
  final List<BoxShadow> shadow;

  SheetStyle copyWith({
    SurfaceStyle? surface,
    TextStyle? titleStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    Radius? radius,
    double? size,
    double? maxFraction,
    Color? grabber,
    Size? grabberSize,
    Color? scrim,
    List<BoxShadow>? shadow,
  }) => SheetStyle(
    surface: surface ?? this.surface,
    titleStyle: titleStyle ?? this.titleStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    radius: radius ?? this.radius,
    size: size ?? this.size,
    maxFraction: maxFraction ?? this.maxFraction,
    grabber: grabber ?? this.grabber,
    grabberSize: grabberSize ?? this.grabberSize,
    scrim: scrim ?? this.scrim,
    shadow: shadow ?? this.shadow,
  );

  @override
  bool operator ==(Object other) =>
      other is SheetStyle &&
      other.surface == surface &&
      other.titleStyle == titleStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.radius == radius &&
      other.size == size &&
      other.maxFraction == maxFraction &&
      other.grabber == grabber &&
      other.grabberSize == grabberSize &&
      other.scrim == scrim &&
      listEquals(other.shadow, shadow);

  @override
  int get hashCode => Object.hash(
    surface,
    titleStyle,
    padding,
    gap,
    radius,
    size,
    maxFraction,
    grabber,
    grabberSize,
    scrim,
    Object.hashAll(shadow),
  );
}
