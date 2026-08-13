import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The elevation shadows.
///
/// Three levels, each a key light plus an ambient wash, in black at low alpha
/// so they read on any surface and disappear politely on dark ones — a dark
/// theme that wants elevation should say it with surface colour, and a design
/// built on hairline borders can pass empty lists and ignore these entirely.
@immutable
class Shadows {
  const Shadows({
    this.low = const [
      BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
    ],
    this.medium = const [
      BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2)),
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 14,
        offset: Offset(0, 6),
      ),
    ],
    this.high = const [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: Color(0x24000000),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
  });

  /// The absence of elevation, for call sites that want to say so.
  static const List<BoxShadow> none = [];

  /// Resting cards, menus barely off the page.
  final List<BoxShadow> low;

  /// Popovers, dropdowns, things floating over content.
  final List<BoxShadow> medium;

  /// Dialogs and sheets — the topmost layer.
  final List<BoxShadow> high;

  Shadows copyWith({
    List<BoxShadow>? low,
    List<BoxShadow>? medium,
    List<BoxShadow>? high,
  }) => Shadows(
    low: low ?? this.low,
    medium: medium ?? this.medium,
    high: high ?? this.high,
  );

  @override
  bool operator ==(Object other) =>
      other is Shadows &&
      listEquals(other.low, low) &&
      listEquals(other.medium, medium) &&
      listEquals(other.high, high);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(low), Object.hashAll(medium), Object.hashAll(high));
}
