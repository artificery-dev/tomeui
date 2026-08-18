import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';

/// Which edge of a [Scaffold] a sidebar hangs off.
///
/// Leading and trailing rather than left and right: the row they sit in
/// reads in the ambient direction, so in an RTL locale leading is the right
/// edge without anything being told about it.
enum ScaffoldSide { leading, trailing }

/// The resolved values a [Scaffold] paints, plus the widths it decides its
/// layout by. The choosing happened in [ScaffoldResolver], at
/// `theme.widgets.scaffold`.
@immutable
class ScaffoldStyle {
  const ScaffoldStyle({
    required this.bar,
    required this.sidebar,
    required this.divider,
    required this.scrim,
    this.barPadding = EdgeInsets.zero,
    this.sidebarPadding = EdgeInsets.zero,
    this.dividerThickness = 1,
    this.sidebarWidth = 280,
    this.drawerWidth = 320,
    this.minBodyWidth = 620,
    this.drawerShadow = const [],
  });

  /// The dress every toolbar and status bar sits on.
  final SurfaceStyle bar;

  /// The dress a sidebar sits on, inline or as a drawer.
  final SurfaceStyle sidebar;

  /// The hairline between regions: under the toolbars, over the status
  /// bars, and along a sidebar's inner edge. A [dividerThickness] of zero
  /// turns the lot off.
  final Color divider;
  final double dividerThickness;

  /// The wash over the body while a drawer is open.
  final Color scrim;

  /// Side gutters for a bar's contents. Horizontal only by default — how
  /// tall a bar stands is the business of what's in it.
  final EdgeInsetsGeometry barPadding;

  /// Nothing by default: a sidebar usually holds a list that wants to run
  /// edge to edge.
  final EdgeInsetsGeometry sidebarPadding;

  /// How wide a sidebar stands when it's inline beside the body.
  final double sidebarWidth;

  /// How wide it stands as a drawer, where it's over the body rather than
  /// beside it and can afford to be a little broader.
  final double drawerWidth;

  /// The narrowest body the scaffold will leave beside an inline sidebar.
  /// Below it the sidebar becomes a drawer — this is the number the whole
  /// adaptive behaviour turns on.
  final double minBodyWidth;

  /// The elevation a drawer floats at over the body.
  final List<BoxShadow> drawerShadow;

  ScaffoldStyle copyWith({
    SurfaceStyle? bar,
    SurfaceStyle? sidebar,
    Color? divider,
    Color? scrim,
    EdgeInsetsGeometry? barPadding,
    EdgeInsetsGeometry? sidebarPadding,
    double? dividerThickness,
    double? sidebarWidth,
    double? drawerWidth,
    double? minBodyWidth,
    List<BoxShadow>? drawerShadow,
  }) => ScaffoldStyle(
    bar: bar ?? this.bar,
    sidebar: sidebar ?? this.sidebar,
    divider: divider ?? this.divider,
    scrim: scrim ?? this.scrim,
    barPadding: barPadding ?? this.barPadding,
    sidebarPadding: sidebarPadding ?? this.sidebarPadding,
    dividerThickness: dividerThickness ?? this.dividerThickness,
    sidebarWidth: sidebarWidth ?? this.sidebarWidth,
    drawerWidth: drawerWidth ?? this.drawerWidth,
    minBodyWidth: minBodyWidth ?? this.minBodyWidth,
    drawerShadow: drawerShadow ?? this.drawerShadow,
  );

  @override
  bool operator ==(Object other) =>
      other is ScaffoldStyle &&
      other.bar == bar &&
      other.sidebar == sidebar &&
      other.divider == divider &&
      other.scrim == scrim &&
      other.barPadding == barPadding &&
      other.sidebarPadding == sidebarPadding &&
      other.dividerThickness == dividerThickness &&
      other.sidebarWidth == sidebarWidth &&
      other.drawerWidth == drawerWidth &&
      other.minBodyWidth == minBodyWidth &&
      listEquals(other.drawerShadow, drawerShadow);

  @override
  int get hashCode => Object.hash(
    bar,
    sidebar,
    divider,
    scrim,
    barPadding,
    sidebarPadding,
    dividerThickness,
    sidebarWidth,
    drawerWidth,
    minBodyWidth,
    Object.hashAll(drawerShadow),
  );
}
