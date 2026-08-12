import 'package:flutter/widgets.dart';

/// The corner radii.
///
/// One scale for the whole system: controls and chips take [small], cards and
/// fields [medium], sheets and dialogs [large]. [full] is the stadium shape —
/// pills, avatars, track-and-thumb controls.
abstract final class Radii {
  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius small = BorderRadius.all(Radius.circular(6));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(10));
  static const BorderRadius large = BorderRadius.all(Radius.circular(14));
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(20));

  /// Large enough to be a stadium at any sane size without the layout jumps
  /// a computed half-height radius can cause.
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));
}
