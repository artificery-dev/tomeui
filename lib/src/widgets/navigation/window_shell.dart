import 'package:tomeui/tomeui.dart';

/// The window behind the app, as [TitleBar] needs it: something to drag,
/// to maximise, to close — and nothing more.
///
/// Tome draws window chrome but doesn't own a window; that belongs to
/// whatever the app runs in. This seam keeps the two apart. The toolkit
/// talks only to [WindowShell.instance], and by default that is a
/// [NoWindow]: every question answers "no", every action does nothing, and
/// a [TitleBar] is simply a bar — which is the right amount of window on a
/// phone, in a test, or on a device whose "window" is the screen itself.
///
/// A desktop app installs a real shell before [runApp] — the
/// `window_manager`-backed one lives in `package:tomeui_desktop`, so the
/// plugin rides along only where a desktop does:
///
/// ```dart
/// Future<void> main() async {
///   installWindowShell();          // from package:tomeui_desktop
///   await TitleBar.claimWindow();
///   runApp(const App());
/// }
/// ```
abstract class WindowShell {
  const WindowShell();

  /// The shell the toolkit talks to. [NoWindow] until an app installs one.
  static WindowShell instance = const NoWindow();

  /// Claim the window for the app's own chrome: hide the native title bar
  /// and show the window once the first frame is ready, so it never
  /// flashes native chrome on the way up.
  Future<void> claim();

  /// Begin moving the window under the pointer.
  Future<void> startDragging();

  Future<bool> isMaximized();

  Future<void> minimize();

  Future<void> maximize();

  Future<void> unmaximize();

  Future<void> close();

  /// Hear the window cross into or out of maximised, for the button that
  /// swaps its glyph. The callback carries the new state.
  void addMaximizedListener(ValueChanged<bool> listener);

  void removeMaximizedListener(ValueChanged<bool> listener);
}

/// The absence of a window, worn where none exists.
///
/// Nothing here throws: a bar whose drag goes nowhere is still a bar, and
/// the widgets above this seam never need to ask whether the window is
/// real before speaking to it.
class NoWindow extends WindowShell {
  const NoWindow();

  @override
  Future<void> claim() async {}

  @override
  Future<void> startDragging() async {}

  @override
  Future<bool> isMaximized() async => false;

  @override
  Future<void> minimize() async {}

  @override
  Future<void> maximize() async {}

  @override
  Future<void> unmaximize() async {}

  @override
  Future<void> close() async {}

  @override
  void addMaximizedListener(ValueChanged<bool> listener) {}

  @override
  void removeMaximizedListener(ValueChanged<bool> listener) {}
}
