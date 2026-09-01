/// The desktop window behind Tome UI.
///
/// Tome itself never touches `package:window_manager`; it talks to
/// [WindowShell.instance], which is a [NoWindow] until something better is
/// installed. This package is the something better — one call in `main`
/// puts the real window behind every [TitleBar]:
///
/// ```dart
/// Future<void> main() async {
///   installWindowShell();
///   await TitleBar.claimWindow();
///   runApp(const App());
/// }
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';
// The plugin has a `TitleBarStyle` of its own — an enum for the *native*
// bar, which claim() hides so the app can draw Tome's. Tome's wins here.
import 'package:window_manager/window_manager.dart' hide TitleBarStyle;
import 'package:window_manager/window_manager.dart' as wm show TitleBarStyle;

/// Install the `window_manager`-backed [WindowShell] as the one Tome talks
/// to. Call before [runApp]; idempotent.
void installWindowShell() {
  if (WindowShell.instance is! WindowManagerShell) {
    WindowShell.instance = WindowManagerShell();
  }
}

/// [WindowShell] over `package:window_manager`.
class WindowManagerShell extends WindowShell with WindowListener {
  WindowManagerShell();

  final _listeners = <ValueChanged<bool>>[];
  bool _watching = false;

  /// Whether this build is running on a desktop, where a window is
  /// something a bar can move. Everywhere else [claim] stays a no-op even
  /// with this shell installed, so one `main` serves every platform.
  static bool get _desktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  @override
  Future<void> claim() async {
    if (!_desktop) return;
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    const options = WindowOptions(titleBarStyle: wm.TitleBarStyle.hidden);
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  @override
  Future<void> startDragging() => windowManager.startDragging();

  @override
  Future<bool> isMaximized() => windowManager.isMaximized();

  @override
  Future<void> minimize() => windowManager.minimize();

  @override
  Future<void> maximize() => windowManager.maximize();

  @override
  Future<void> unmaximize() => windowManager.unmaximize();

  @override
  Future<void> close() => windowManager.close();

  @override
  void addMaximizedListener(ValueChanged<bool> listener) {
    _listeners.add(listener);
    if (!_watching) {
      windowManager.addListener(this);
      _watching = true;
    }
  }

  @override
  void removeMaximizedListener(ValueChanged<bool> listener) {
    _listeners.remove(listener);
  }

  @override
  void onWindowMaximize() {
    for (final listener in List.of(_listeners)) {
      listener(true);
    }
  }

  @override
  void onWindowUnmaximize() {
    for (final listener in List.of(_listeners)) {
      listener(false);
    }
  }
}
