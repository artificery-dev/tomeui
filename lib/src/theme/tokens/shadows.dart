import 'package:flutter/widgets.dart';

/// The elevation shadows.
///
/// Three levels, each a key light plus an ambient wash, in black at low alpha
/// so they read on any surface and disappear politely on dark ones — a dark
/// theme that wants elevation should say it with surface colour, and a design
/// built on hairline borders can ignore these entirely.
abstract final class Shadows {
  static const List<BoxShadow> none = [];

  /// Resting cards, menus barely off the page.
  static const List<BoxShadow> low = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Popovers, dropdowns, things floating over content.
  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 6)),
  ];

  /// Dialogs and sheets — the topmost layer.
  static const List<BoxShadow> high = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x24000000), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
