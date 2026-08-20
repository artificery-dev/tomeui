import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';
// The plugin has a `TitleBarStyle` of its own — an enum for the *native*
// bar, which an app hides to draw this one. Ours is the style [TitleBar]
// paints, and it wins here.
import 'package:window_manager/window_manager.dart' hide TitleBarStyle;

import '../foundation/interactive.dart';

/// The bar across the top of a window: what the page is, what you can do to
/// it, and — on desktop — the window's own buttons.
///
/// The AppBar stand-in, and a [Scaffold] toolbar like any other:
///
/// ```dart
/// Scaffold(
///   toolbars: [
///     TitleBar(
///       leading: const [ScaffoldSidebarToggle(ScaffoldSide.leading)],
///       title: const Text('Manifest'),
///       subtitle: const Text('Endeavour · outbound'),
///       actions: [Button(onPressed: sign, center: const Text('Sign'))],
///     ),
///   ],
///   body: ...,
/// )
/// ```
///
/// ## The window
///
/// On a desktop the bar doubles as the window's own chrome: dragging it
/// moves the window, double-clicking maximises it, and [windowControls]
/// draws the minimise, maximise, and close buttons at the trailing end.
/// Both default to what the platform expects — on and on for Windows and
/// Linux, drag-only on macOS, where the system draws its own buttons and
/// an app that hides the native bar leaves room for them in [leading].
///
/// Off desktop the bar is a bar: the window machinery is never reached, so
/// this is the same widget on a phone with none of it running.
class TitleBar extends StatelessWidget {
  const TitleBar({
    this.title,
    this.subtitle,
    this.leading = const [],
    this.actions = const [],
    this.centerTitle = false,
    this.windowControls,
    this.dragToMove,
    this.style,
    super.key,
  });

  /// What the page is.
  final Widget? title;

  /// Where the page sits — the document's context, under the title.
  final Widget? subtitle;

  /// Before the title: a sidebar toggle, a way back.
  final List<Widget> leading;

  /// After it, at the trailing end.
  final List<Widget> actions;

  /// Centre the title in the bar rather than letting it follow [leading].
  /// The bar keeps it centred on the *window*, so a title doesn't shift
  /// when a sidebar toggle appears beside it.
  final bool centerTitle;

  /// Draw the window's minimise, maximise, and close buttons. Null takes
  /// the platform's answer: Windows and Linux yes, macOS no, and no
  /// anywhere that isn't a desktop.
  final bool? windowControls;

  /// Dragging the bar moves the window, and a double-click maximises it.
  /// Null means yes on desktop.
  final bool? dragToMove;

  /// The style to paint, bypassing the theme.
  final TitleBarStyle? style;

  /// Whether this build is running on a desktop, where a window is
  /// something a bar can move.
  static bool get _desktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.titleBar.resolve();
    final controls =
        windowControls ??
        (_desktop && defaultTargetPlatform != TargetPlatform.macOS);
    final drag = dragToMove ?? _desktop;

    final words = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (title != null)
          DefaultTextStyle.merge(
            style: style.titleStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            child: title!,
          ),
        if (subtitle != null)
          DefaultTextStyle.merge(
            style: style.subtitleStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            child: subtitle!,
          ),
      ],
    );

    final row = Row(
      children: [
        for (final widget in leading) ...[widget, SizedBox(width: style.gap)],
        if (!centerTitle) Flexible(child: words),
        const Spacer(),
        for (final widget in actions) ...[SizedBox(width: style.gap), widget],
        if (controls) ...[
          SizedBox(width: style.gap),
          WindowControls(style: style),
        ],
      ],
    );

    Widget bar = Surface.custom(
      style: style.surface,
      padding: style.padding,
      child: SizedBox(
        height: style.height,
        child: centerTitle
            // Centred means centred on the *bar*, not on what the slots
            // left over, so a title doesn't shift when a toggle appears
            // beside it. It rides over the row and takes no pointer, which
            // asks that a centred title be short enough not to reach the
            // slots.
            ? Stack(
                alignment: Alignment.center,
                children: [row, IgnorePointer(child: Center(child: words))],
              )
            : row,
      ),
    );

    if (drag) {
      bar = GestureDetector(
        behavior: HitTestBehavior.translucent,
        // The bar's own children take the pointer first; what's left of it
        // is the window's handle.
        onPanStart: (_) => _startDragging(),
        onDoubleTap: _toggleMaximized,
        child: bar,
      );
    }
    return bar;
  }

  static Future<void> _startDragging() async {
    try {
      await windowManager.startDragging();
    } on Object {
      // No window to drag — a desktop build without the plugin wired up,
      // or a test. A bar that can't move the window is still a bar.
    }
  }

  static Future<void> _toggleMaximized() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } on Object {
      // As above.
    }
  }
}

/// The window's own buttons: minimise, maximise or restore, and close.
///
/// [TitleBar] draws these itself where the platform expects them; reach for
/// the widget directly only to put them somewhere else in a bar of your
/// own. Off desktop it draws nothing.
class WindowControls extends StatefulWidget {
  const WindowControls({this.style, super.key});

  /// The style to paint, bypassing the theme.
  final TitleBarStyle? style;

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _readMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  Future<void> _readMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted && maximized != _maximized) {
        setState(() => _maximized = maximized);
      }
    } on Object {
      // No window to ask — leave the glyph on maximise.
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Nothing to act on; the button simply does nothing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.titleBar.resolve();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          style: style,
          icon: theme.icons.windowMinimize,
          label: theme.labels.minimizeWindow,
          onPressed: () => _act(windowManager.minimize),
        ),
        _WindowButton(
          style: style,
          icon: _maximized
              ? theme.icons.windowRestore
              : theme.icons.windowMaximize,
          label: _maximized
              ? theme.labels.restoreWindow
              : theme.labels.maximizeWindow,
          onPressed: () => _act(
            _maximized ? windowManager.unmaximize : windowManager.maximize,
          ),
        ),
        _WindowButton(
          style: style,
          icon: theme.icons.close,
          label: theme.labels.closeWindow,
          danger: true,
          onPressed: () => _act(windowManager.close),
        ),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.style,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final TitleBarStyle style;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// Closing answers in red, the way every desktop draws it.
  final bool danger;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Interactive(
      onActivate: onPressed,
      ring: style.controlRing,
      ringRadius: BorderRadius.zero,
      hover: danger ? style.closeHover : style.controlHover,
      pressed: danger ? style.closePressed : style.controlPressed,
      builder: (context, state) => Container(
        width: style.controlSize,
        height: style.controlSize,
        color: state.wash,
        child: Icon(
          icon,
          size: style.controlIconSize,
          // Over the red, the glyph has to be what reads on it rather than
          // what read on the bar.
          color: danger && state.wash != null
              ? style.surface.fill ?? style.surface.foreground
              : style.surface.foreground,
        ),
      ),
    ),
  );
}
