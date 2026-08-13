import 'package:flutter/widgets.dart';

/// The width breakpoints.
///
/// Widths, not devices: a desktop window dragged narrow *is* the compact
/// layout. Every widget that adapts reads the same three numbers, so the
/// shell and the screens inside it never disagree about which layout they
/// are in.
@immutable
class Breakpoints {
  const Breakpoints({
    this.compact = 620,
    this.medium = 900,
    this.expanded = 1240,
  });

  /// Below this the window is a phone, whatever the hardware says.
  final double compact;

  /// Room for two panes or a navigation rail.
  final double medium;

  /// Room for everything at once.
  final double expanded;

  Breakpoints copyWith({double? compact, double? medium, double? expanded}) =>
      Breakpoints(
        compact: compact ?? this.compact,
        medium: medium ?? this.medium,
        expanded: expanded ?? this.expanded,
      );

  @override
  bool operator ==(Object other) =>
      other is Breakpoints &&
      other.compact == compact &&
      other.medium == medium &&
      other.expanded == expanded;

  @override
  int get hashCode => Object.hash(compact, medium, expanded);
}
