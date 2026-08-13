import 'package:flutter/widgets.dart';

/// The spacing scale, on a 4px base by default.
///
/// Named the Tailwind way — `x4` is four units, not four pixels — so a gap
/// reads as a step on the scale rather than a number someone mixed by hand.
/// The defaults are the system's; a denser or airier theme swaps the whole
/// scale by constructing its own.
@immutable
class Space {
  const Space({
    this.x1 = 4,
    this.x2 = 8,
    this.x3 = 12,
    this.x4 = 16,
    this.x5 = 20,
    this.x6 = 24,
    this.x8 = 32,
    this.x10 = 40,
    this.x12 = 48,
    this.x16 = 64,
  });

  final double x1;
  final double x2;
  final double x3;
  final double x4;
  final double x5;
  final double x6;
  final double x8;
  final double x10;
  final double x12;
  final double x16;

  Space copyWith({
    double? x1,
    double? x2,
    double? x3,
    double? x4,
    double? x5,
    double? x6,
    double? x8,
    double? x10,
    double? x12,
    double? x16,
  }) => Space(
    x1: x1 ?? this.x1,
    x2: x2 ?? this.x2,
    x3: x3 ?? this.x3,
    x4: x4 ?? this.x4,
    x5: x5 ?? this.x5,
    x6: x6 ?? this.x6,
    x8: x8 ?? this.x8,
    x10: x10 ?? this.x10,
    x12: x12 ?? this.x12,
    x16: x16 ?? this.x16,
  );

  @override
  bool operator ==(Object other) =>
      other is Space &&
      other.x1 == x1 &&
      other.x2 == x2 &&
      other.x3 == x3 &&
      other.x4 == x4 &&
      other.x5 == x5 &&
      other.x6 == x6 &&
      other.x8 == x8 &&
      other.x10 == x10 &&
      other.x12 == x12 &&
      other.x16 == x16;

  @override
  int get hashCode =>
      Object.hash(x1, x2, x3, x4, x5, x6, x8, x10, x12, x16);
}
