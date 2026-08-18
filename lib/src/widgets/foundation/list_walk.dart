import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

/// The keyboard walk every list of rows shares: which row the keyboard is
/// on, the arrows that move it, and Enter or Space to take it.
///
/// Rows are addressed by index and [enabledAt] says which ones can be landed
/// on, so separators, section labels, and disabled entries are stepped over
/// rather than stopped on. The walk wraps at both ends — a list you can fall
/// off is a list you have to look at.
///
/// Holds a [Focus] node of its own rather than leaning on the enclosing
/// [Popover]'s: content that walks itself is exactly what
/// `Popover.takeFocus: false` exists for, and anything the walk doesn't
/// handle — Escape, most importantly — still bubbles up to the popover.
///
/// Toolkit-internal: `Select` and `Menu` are built on it, and it isn't
/// exported by the barrel.
class ListWalk extends StatefulWidget {
  const ListWalk({
    required this.length,
    required this.enabledAt,
    required this.onActivate,
    required this.builder,
    this.initial = -1,
    this.autofocus = true,
    super.key,
  });

  final int length;

  /// Whether the row at this index can hold the highlight.
  final bool Function(int index) enabledAt;

  /// Enter, Space, or a click on a row.
  final ValueChanged<int> onActivate;

  /// Draws the rows: told where the highlight is, and handed the way to
  /// move it — which is what a row's hover calls.
  final Widget Function(
    BuildContext context,
    int highlight,
    ValueChanged<int> highlightTo,
  )
  builder;

  /// Where the highlight starts. Negative — or an index that can't hold it
  /// — starts on the first row that can.
  final int initial;

  /// Whether the walk claims the keyboard when it appears.
  ///
  /// False for a list that opens *beside* something already holding it — a
  /// text field's selection menu, where taking the focus would collapse the
  /// very selection the menu is about. Such a list is walked by pointer
  /// only, which is what a desktop selection menu does anyway.
  final bool autofocus;

  @override
  State<ListWalk> createState() => _ListWalkState();
}

class _ListWalkState extends State<ListWalk> {
  late int _highlight = _seed();

  int _seed() {
    if (widget.initial >= 0 &&
        widget.initial < widget.length &&
        widget.enabledAt(widget.initial)) {
      return widget.initial;
    }
    return _walkable.firstOrNull ?? -1;
  }

  List<int> get _walkable => [
    for (var i = 0; i < widget.length; i++)
      if (widget.enabledAt(i)) i,
  ];

  @override
  void didUpdateWidget(ListWalk oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A reopened list starts fresh, and a list whose rows changed under it
    // can't keep pointing at a row that may no longer be there.
    if (widget.initial != oldWidget.initial ||
        widget.length != oldWidget.length) {
      _highlight = _seed();
    }
  }

  /// Steps to the next row that can hold the highlight, wrapping around.
  void _step(int by) {
    final walkable = _walkable;
    if (walkable.isEmpty) return;
    final at = walkable.indexOf(_highlight);
    setState(
      () => _highlight = at < 0
          ? (by > 0 ? walkable.first : walkable.last)
          : walkable[(at + by) % walkable.length],
    );
  }

  void _jump(int to) {
    if (to < 0) return;
    setState(() => _highlight = to);
  }

  void _activate() {
    if (_highlight >= 0 && widget.enabledAt(_highlight)) {
      widget.onActivate(_highlight);
    }
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(1),
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(-1),
      const SingleActivator(LogicalKeyboardKey.home): () =>
          _jump(_walkable.firstOrNull ?? -1),
      const SingleActivator(LogicalKeyboardKey.end): () =>
          _jump(_walkable.lastOrNull ?? -1),
      const SingleActivator(LogicalKeyboardKey.enter): _activate,
      const SingleActivator(LogicalKeyboardKey.space): _activate,
    },
    // The focused node sits inside the shortcuts, so keys reach them on the
    // way up and everything else carries on past.
    child: Focus(
      autofocus: widget.autofocus,
      child: widget.builder(context, _highlight, _jump),
    ),
  );
}

/// One row of a walked list: the hover, the click, and the background that
/// marks where the keyboard is.
///
/// Everything the row *contains* is the caller's — a select's tick, a menu's
/// shortcut hint — but the way it answers a pointer is the same either way.
class ListWalkRow extends StatelessWidget {
  const ListWalkRow({
    required this.enabled,
    required this.background,
    required this.radius,
    required this.padding,
    required this.onHover,
    required this.onTap,
    required this.child,
    super.key,
  });

  final bool enabled;

  /// What's behind the row: the highlight, the selection, or nothing.
  final Color? background;

  final BorderRadius radius;
  final EdgeInsetsGeometry padding;

  /// The pointer arrived — the walk follows the mouse.
  final VoidCallback onHover;
  final VoidCallback onTap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    return Opacity(
      opacity: enabled ? 1 : theme.opacities.disabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => onHover() : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: theme.motion.instant,
            curve: theme.motion.move,
            decoration: BoxDecoration(color: background, borderRadius: radius),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
