import 'package:tomeui/tomeui.dart';

/// Puts the page's dressing back on content that has left the page.
///
/// A popover's panel, a dialog, a sheet: all of them hang off the
/// [Overlay] or the [Navigator] rather than off the subtree that summoned
/// them, so none of that subtree's theme, text style, or icon look reaches
/// them. Without this, a panel's words fall back to the framework's debug
/// style, and a theme installed part-way down the tree — a section with a
/// palette of its own, or a catalog previewing one — is lost the moment
/// something floats.
///
/// The theme to dress with is the one that was in scope where the thing
/// was summoned from, captured at that moment. Set, not merged: there is
/// nothing sane underneath to merge with.
///
/// Toolkit-internal: used by the overlays, not exported by the barrel.
Widget dressForOverlay({
  required Theme theme,
  required Widget child,
  Color? foreground,
}) {
  final ink = foreground ?? theme.palette.text;
  return ThemeProvider(
    theme: theme,
    child: DefaultTextStyle(
      style: theme.typography.body.copyWith(color: ink),
      child: IconTheme(
        data: IconThemeData(color: ink, size: theme.sizes.icon),
        child: child,
      ),
    ),
  );
}
