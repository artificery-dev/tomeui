/// The width breakpoints.
///
/// Widths, not devices: a desktop window dragged narrow *is* the compact
/// layout. Every widget that adapts reads the same three numbers, so the
/// shell and the screens inside it never disagree about which layout they
/// are in.
abstract final class Breakpoints {
  /// Below this the window is a phone, whatever the hardware says.
  static const double compact = 620;

  /// Room for two panes or a navigation rail.
  static const double medium = 900;

  /// Room for everything at once.
  static const double expanded = 1240;
}
