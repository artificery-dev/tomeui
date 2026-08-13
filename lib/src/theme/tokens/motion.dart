import 'package:flutter/widgets.dart';

/// The motion tokens: how long, and along what curve.
///
/// Durations pair with distances — a hover tint takes [instant], a chip or
/// switch [fast], a panel or dialog [standard], a full-screen change [slow].
/// The curves follow the enter/exit rule: things arriving decelerate into
/// place, things leaving accelerate away, and things *moving* do both.
@immutable
class Motion {
  const Motion({
    this.instant = const Duration(milliseconds: 80),
    this.fast = const Duration(milliseconds: 140),
    this.standard = const Duration(milliseconds: 240),
    this.slow = const Duration(milliseconds: 400),
    this.enter = Curves.easeOutCubic,
    this.exit = Curves.easeInCubic,
    this.move = Curves.easeInOutCubic,
  });

  final Duration instant;
  final Duration fast;
  final Duration standard;
  final Duration slow;

  /// Arriving: start quick, settle gently.
  final Curve enter;

  /// Leaving: gather speed and go. Slightly shorter-feeling than [enter] on
  /// the same duration, which is what an exit should be.
  final Curve exit;

  /// Moving from one place on screen to another.
  final Curve move;

  Motion copyWith({
    Duration? instant,
    Duration? fast,
    Duration? standard,
    Duration? slow,
    Curve? enter,
    Curve? exit,
    Curve? move,
  }) => Motion(
    instant: instant ?? this.instant,
    fast: fast ?? this.fast,
    standard: standard ?? this.standard,
    slow: slow ?? this.slow,
    enter: enter ?? this.enter,
    exit: exit ?? this.exit,
    move: move ?? this.move,
  );

  @override
  bool operator ==(Object other) =>
      other is Motion &&
      other.instant == instant &&
      other.fast == fast &&
      other.standard == standard &&
      other.slow == slow &&
      other.enter == enter &&
      other.exit == exit &&
      other.move == move;

  @override
  int get hashCode =>
      Object.hash(instant, fast, standard, slow, enter, exit, move);
}
