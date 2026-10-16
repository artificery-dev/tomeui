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
    this.sidebarMinWidth = 160,
    this.sidebarMaxWidth = 560,
    this.resizeHandleWidth = 6,
    this.resizeHandleColor,
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

  /// How wide a sidebar stands when it's inline beside the body, until the
  /// reader drags it otherwise on a `Scaffold(resizable: true)`.
  final double sidebarWidth;

  /// The narrowest and widest a reader can drag an inline sidebar. The
  /// window has the last word: a sidebar never grows into the
  /// [minBodyWidth] the body is owed.
  final double sidebarMinWidth;
  final double sidebarMaxWidth;

  /// How wide the invisible strip along a resizable sidebar's inner edge
  /// is — the thing the reader grabs.
  final double resizeHandleWidth;

  /// The line that lights the grab strip while the pointer is over it or
  /// dragging it. Null falls back to [divider].
  final Color? resizeHandleColor;

  /// How wide it stands as a drawer, where it's over the body rather than
  /// beside it and can afford to be a little broader.
  final double drawerWidth;

  /// The narrowest body the scaffold will leave beside an inline sidebar.
  /// Below it the sidebar becomes a drawer — this is the number the whole
  /// adaptive behavior turns on.
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
    double? sidebarMinWidth,
    double? sidebarMaxWidth,
    double? resizeHandleWidth,
    Color? resizeHandleColor,
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
    sidebarMinWidth: sidebarMinWidth ?? this.sidebarMinWidth,
    sidebarMaxWidth: sidebarMaxWidth ?? this.sidebarMaxWidth,
    resizeHandleWidth: resizeHandleWidth ?? this.resizeHandleWidth,
    resizeHandleColor: resizeHandleColor ?? this.resizeHandleColor,
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
      other.sidebarMinWidth == sidebarMinWidth &&
      other.sidebarMaxWidth == sidebarMaxWidth &&
      other.resizeHandleWidth == resizeHandleWidth &&
      other.resizeHandleColor == resizeHandleColor &&
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
    sidebarMinWidth,
    sidebarMaxWidth,
    resizeHandleWidth,
    resizeHandleColor,
    drawerWidth,
    minBodyWidth,
    Object.hashAll(drawerShadow),
  );
}
