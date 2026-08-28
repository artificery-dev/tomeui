import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';
// The plugin has a `TitleBarStyle` of its own — an enum for the *native*
// bar, which an app hides to draw this one. Ours is the style [TitleBar]
// paints, and it wins here.
import 'package:window_manager/window_manager.dart' hide TitleBarStyle;
// The one name the hide above drops, wanted once in [TitleBar.claimWindow].
import 'package:window_manager/window_manager.dart' as wm show TitleBarStyle;

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
class TitleBar extends StatelessWidget implements SelfDressedBar {
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

  /// Claim the window: hide the native title bar so the [TitleBar] in the
  /// app's chrome is the window's own. Call before [runApp]:
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   await TitleBar.claimWindow();
  ///   runApp(const App());
  /// }
  /// ```
  ///
  /// The window stays hidden until the first frame is ready, so it never
  /// flashes native chrome on the way up. A no-op off desktop, so one
  /// `main` serves every platform.
  static Future<void> claimWindow() async {
    if (!_desktop) return;
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    const options = WindowOptions(titleBarStyle: wm.TitleBarStyle.hidden);
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

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
        // One flexible child, which takes *all* the room the slots leave —
        // a `Flexible` for the words beside a `Spacer` would split it
        // between them, and whatever the loose half didn't want would sit
        // at the end of the row, holding the actions out of the corner.
        //
        // No pointer for the words: a title is what the page is, not a
        // control, and text that took the hit would hold a drag that
        // should fall through to the window.
        Expanded(
          child: centerTitle
              ? const SizedBox.shrink()
              : IgnorePointer(child: words),
        ),
        for (final widget in actions) ...[SizedBox(width: style.gap), widget],
      ],
    );

    // The window's own buttons are the one thing the bar's padding doesn't
    // hold in: they run to the very corner and the full height of the bar,
    // square, the way a desktop's do. Everything else keeps its inset.
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(padding: style.padding, child: row),
        ),
        if (controls) WindowControls(style: style),
      ],
    );

    Widget inner = centerTitle
        // Centred means centred on the *bar*, not on what the slots
        // left over, so a title doesn't shift when a toggle appears
        // beside it. It rides over the row and takes no pointer, which
        // asks that a centred title be short enough not to reach the
        // slots.
        ? Stack(
            alignment: Alignment.center,
            children: [
              content,
              IgnorePointer(child: Center(child: words)),
            ],
          )
        : content;

    if (drag) {
      inner = Stack(
        children: [
          // Behind the content rather than around the bar. Wrapped around,
          // the double-tap recognizer joins the arena of every press the
          // bar's children take, and holds it for `kDoubleTapTimeout`
          // before letting a tap through — a third of a second between
          // clicking a menu and seeing it. Behind, it is only in the path
          // of the presses that reached the bar itself.
          //
          // And *inside* the surface, not behind it: the surface's
          // decoration absorbs every hit that reaches it, so a detector
          // on the far side would never hear one.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => _startDragging(),
              onDoubleTap: _toggleMaximized,
            ),
          ),
          inner,
        ],
      );
    }

    return Surface.custom(
      style: style.surface,
      child: SizedBox(height: style.height, child: inner),
    );
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

    return SizedBox(
      height: style.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Full bleed: each button is as tall as the bar and square with it
        // — a window button is a corner of the window rather than a control
        // on a page, so it keeps no margin of its own.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WindowButton(
            style: style,
            glyph: WindowGlyph.minimize,
            icon: theme.icons.windowMinimize,
            label: theme.labels.minimizeWindow,
            onPressed: () => _act(windowManager.minimize),
          ),
          _WindowButton(
            style: style,
            glyph: _maximized ? WindowGlyph.restore : WindowGlyph.maximize,
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
            glyph: WindowGlyph.close,
            icon: theme.icons.windowClose,
            label: theme.labels.closeWindow,
            danger: true,
            onPressed: () => _act(windowManager.close),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.style,
    required this.glyph,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final TitleBarStyle style;

  /// The standard shape to paint, when the theme hasn't named a glyph.
  final WindowGlyph glyph;

  /// The theme's glyph for this button, or null for [glyph]'s own shape.
  final IconData? icon;

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
      builder: (context, state) {
        // Over the red, the glyph has to be what reads on *it* rather than
        // what read on the bar — and only while the red is actually there.
        // A wash at rest is the hover colour at zero alpha, not null, so
        // asking whether there is one at all painted the close cross in
        // the bar's own fill: a button you could press and never see.
        final washed = danger && (state.hovered || state.pressed);
        final colour = washed
            ? style.surface.fill ?? style.surface.foreground
            : style.surface.foreground;

        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: state.wash,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: style.controlIconSize, color: colour)
                  : CustomPaint(
                      size: Size.square(style.controlIconSize),
                      painter: _WindowGlyphPainter(
                        glyph: glyph,
                        color: colour,
                        stroke: style.glyphStroke,
                      ),
                    ),
            ),
          ),
        );
      },
    ),
  );
}

/// The four shapes a window button wears.
///
/// Painted rather than borrowed from an icon set, because no icon set has
/// them: a dash drawn for arithmetic is shorter and rounder than the square
/// beside it, and a set's "restore" is the pair of arrows that means *leave
/// full screen*. Every desktop draws these four at one weight, and so does
/// [WindowControls] — unless the theme names a glyph of its own
/// ([Icons.windowMinimize] and its neighbours).
enum WindowGlyph { minimize, maximize, restore, close }

class _WindowGlyphPainter extends CustomPainter {
  const _WindowGlyphPainter({
    required this.glyph,
    required this.color,
    required this.stroke,
  });

  final WindowGlyph glyph;
  final Color color;
  final double stroke;

  /// How far the back square of [WindowGlyph.restore] stands out from the
  /// front one, as a fraction of the glyph.
  static const _offset = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..color = color;

    // A stroke straddles the line it's given, so the shapes are drawn half
    // a stroke inside the box and end up square with it.
    final box = (Offset.zero & size).deflate(stroke / 2);

    switch (glyph) {
      case WindowGlyph.minimize:
        canvas.drawLine(
          Offset(box.left, box.center.dy),
          Offset(box.right, box.center.dy),
          paint,
        );
      case WindowGlyph.maximize:
        canvas.drawRect(box, paint);
      case WindowGlyph.restore:
        final step = size.width * _offset;
        final front = Rect.fromLTRB(
          box.left,
          box.top + step,
          box.right - step,
          box.bottom,
        );
        final back = front.translate(step, -step);
        canvas
          ..drawRect(front, paint)
          // Only what stands clear of the front square: its bottom and
          // left edges are behind it, and a line nobody can see is a line
          // that shouldn't be drawn.
          ..drawPath(
            Path()
              ..moveTo(back.left, front.top)
              ..lineTo(back.left, back.top)
              ..lineTo(back.right, back.top)
              ..lineTo(back.right, back.bottom)
              ..lineTo(front.right, back.bottom),
            paint,
          );
      case WindowGlyph.close:
        canvas
          ..drawLine(box.topLeft, box.bottomRight, paint)
          ..drawLine(box.topRight, box.bottomLeft, paint);
    }
  }

  @override
  bool shouldRepaint(_WindowGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.stroke != stroke;
}
