import 'package:flutter/widgets.dart';

/// The motion tokens: how long, and along what curve.
///
/// Durations pair with distances — a hover tint takes [instant], a chip or
/// switch [fast], a panel or dialog [standard], a full-screen change [slow].
/// The curves follow the enter/exit rule: things arriving decelerate into
/// place, things leaving accelerate away, and things *moving* do both.
abstract final class Motion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 400);

  /// Arriving: start quick, settle gently.
  static const Curve enter = Curves.easeOutCubic;

  /// Leaving: gather speed and go. Slightly shorter-feeling than [enter] on
  /// the same duration, which is what an exit should be.
  static const Curve exit = Curves.easeInCubic;

  /// Moving from one place on screen to another.
  static const Curve move = Curves.easeInOutCubic;
}
