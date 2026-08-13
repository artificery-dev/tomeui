import 'package:flutter/widgets.dart';

/// The corner radii.
///
/// One scale for the whole system: controls and chips take [small], cards and
/// fields [medium], sheets and dialogs [large]. [full] is the stadium shape —
/// pills, avatars, track-and-thumb controls. A sharper or rounder theme swaps
/// the scale by constructing its own.
@immutable
class Radii {
  const Radii({
    this.none = BorderRadius.zero,
    this.small = const BorderRadius.all(Radius.circular(6)),
    this.medium = const BorderRadius.all(Radius.circular(10)),
    this.large = const BorderRadius.all(Radius.circular(14)),
    this.extraLarge = const BorderRadius.all(Radius.circular(20)),
    this.full = const BorderRadius.all(Radius.circular(999)),
  });

  final BorderRadius none;
  final BorderRadius small;
  final BorderRadius medium;
  final BorderRadius large;
  final BorderRadius extraLarge;

  /// Large enough to be a stadium at any sane size without the layout jumps
  /// a computed half-height radius can cause.
  final BorderRadius full;

  Radii copyWith({
    BorderRadius? none,
    BorderRadius? small,
    BorderRadius? medium,
    BorderRadius? large,
    BorderRadius? extraLarge,
    BorderRadius? full,
  }) => Radii(
    none: none ?? this.none,
    small: small ?? this.small,
    medium: medium ?? this.medium,
    large: large ?? this.large,
    extraLarge: extraLarge ?? this.extraLarge,
    full: full ?? this.full,
  );

  @override
  bool operator ==(Object other) =>
      other is Radii &&
      other.none == none &&
      other.small == small &&
      other.medium == medium &&
      other.large == large &&
      other.extraLarge == extraLarge &&
      other.full == full;

  @override
  int get hashCode =>
      Object.hash(none, small, medium, large, extraLarge, full);
}
