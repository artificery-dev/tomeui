import 'package:flutter/widgets.dart';

/// Which width band a layout is in — what [BreakpointBuilder] hands its
/// builder, and what [Breakpoints.at] answers.
///
/// Bands, not devices: they are named for how much room there is, and a
/// desktop window dragged narrow reports [compact] like anything else that
/// narrow.
enum Breakpoint {
  /// Narrower than [Breakpoints.compact]: one column, and chrome that
  /// hides until it's asked for.
  compact,

  /// [Breakpoints.compact] up to [Breakpoints.medium]: room to spread, not
  /// yet room for a second pane.
  medium,

  /// [Breakpoints.medium] up to [Breakpoints.expanded]: two panes, or a
  /// pane and a rail.
  expanded,

  /// [Breakpoints.expanded] and wider: everything at once.
  large;

  /// Whether this band is [other] or roomier — the comparison responsive
  /// code actually wants, since the bands are ordered.
  bool atLeast(Breakpoint other) => index >= other.index;
}

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

  /// The band [width] falls in. The thresholds are the floors of the bands
  /// above them, so a width exactly on one has crossed into the roomier
  /// band.
  Breakpoint at(double width) => width < compact
      ? Breakpoint.compact
      : width < medium
      ? Breakpoint.medium
      : width < expanded
      ? Breakpoint.expanded
      : Breakpoint.large;

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
