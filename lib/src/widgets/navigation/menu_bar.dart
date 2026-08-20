import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// One menu on a [MenuBar]: a word, and what drops from it.
class BarMenu {
  const BarMenu({required this.label, required this.entries, this.enabled = true});

  /// The word on the bar — File, Edit, View.
  final Widget label;

  final List<MenuEntry> entries;

  final bool enabled;
}

/// The desktop application menu bar.
///
/// A row of words, each dropping a [Menu]. Once one is open the bar is
/// "active": moving the pointer along it switches menus without a second
/// click, and the arrows walk between them — the behaviour every desktop
/// menu bar has had for thirty years.
///
/// ```dart
/// TitleBar(
///   leading: [
///     MenuBar(menus: [
///       BarMenu(label: const Text('File'), entries: [...]),
///       BarMenu(label: const Text('Edit'), entries: [...]),
///     ]),
///   ],
/// )
/// ```
///
/// macOS puts this in the system menu bar instead, so a shell that runs
/// everywhere draws it only where it belongs — the toolkit doesn't decide
/// that for you.
///
/// Desktop furniture, and it assumes a desktop's pointer: the bar knows a
/// press is its own because the pointer hovered its way there first. Under
/// a finger, which arrives without hovering, a tap on the open word leaves
/// it open — tap the page, or press Escape, to put it away.
class MenuBar extends StatefulWidget {
  const MenuBar({required this.menus, this.style, super.key});

  final List<BarMenu> menus;

  /// The style to paint, bypassing the theme.
  final MenuBarStyle? style;

  @override
  State<MenuBar> createState() => _MenuBarState();
}

class _MenuBarState extends State<MenuBar> {
  /// Which menu is showing, or null for none — which is also what makes
  /// the bar inactive again.
  int? _open;

  /// Whether the pointer is on the bar. A click on the bar is the bar's
  /// own business: the panel's barrier lets the press through and would
  /// otherwise close a menu the trigger is about to toggle.
  bool _pointerOnBar = false;

  @override
  void dispose() {
    _listenForWalk(false);
    super.dispose();
  }

  void _openAt(int index) {
    if (!widget.menus[index].enabled) return;
    setState(() => _open = index);
    _listenForWalk(true);
  }

  void _close() {
    setState(() => _open = null);
    _listenForWalk(false);
  }

  /// The barrier reporting a press somewhere else. On the bar, that press
  /// belongs to whichever word it landed on.
  void _dismiss() {
    if (_pointerOnBar) return;
    _close();
  }

  /// Left and Right walk the bar while a menu is down — and while it is,
  /// the keyboard belongs to the panel, which hangs off the overlay rather
  /// than off this widget. Nothing in the bar's own subtree would ever see
  /// the key, so the bar listens for it directly, and only while open.
  bool _walking = false;
  void _listenForWalk(bool listen) {
    if (listen == _walking) return;
    _walking = listen;
    if (listen) {
      HardwareKeyboard.instance.addHandler(_onKey);
    } else {
      HardwareKeyboard.instance.removeHandler(_onKey);
    }
  }

  bool _onKey(KeyEvent event) {
    if (_open == null || event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _step(-1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _step(1);
      return true;
    }
    return false;
  }

  /// Along the bar to the next menu that can open, wrapping.
  void _step(int by) {
    final at = _open;
    if (at == null) return;
    final count = widget.menus.length;
    for (var i = 1; i <= count; i++) {
      final next = (at + by * i) % count;
      if (widget.menus[next].enabled) {
        setState(() => _open = next);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.menus.isNotEmpty, 'A menu bar needs menus.');
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.menuBar.resolve();

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: MouseRegion(
        onEnter: (_) => _pointerOnBar = true,
        onExit: (_) => _pointerOnBar = false,
        child: SizedBox(
          height: style.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, menu) in widget.menus.indexed) ...[
                if (index > 0) SizedBox(width: style.gap),
                Menu(
                  open: _open == index,
                  entries: menu.entries,
                  style: style.menu,
                  align: PopoverAlign.start,
                  // The bar stays reachable while a panel is down: that's
                  // what lets the pointer walk from word to word and a
                  // click on the next one open it outright.
                  barrier: PopoverBarrier.through,
                  onDismiss: _dismiss,
                  anchor: _Trigger(
                    style: style,
                    label: menu.label,
                    enabled: menu.enabled,
                    open: _open == index,
                    // The bar is active once a menu is open: the pointer
                    // passing over a word is enough to switch to it.
                    onHover: _open == null ? null : () => _openAt(index),
                    onPressed: () =>
                        _open == index ? _close() : _openAt(index),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Trigger extends StatelessWidget {
  const _Trigger({
    required this.style,
    required this.label,
    required this.enabled,
    required this.open,
    required this.onHover,
    required this.onPressed,
  });

  final MenuBarStyle style;
  final Widget label;
  final bool enabled;

  /// Whether this trigger's own panel is showing.
  final bool open;

  /// Called when the pointer arrives while the bar is active.
  final VoidCallback? onHover;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    expanded: open,
    child: MouseRegion(
      onEnter: enabled && onHover != null ? (_) => onHover!() : null,
      child: Interactive(
        onActivate: enabled ? onPressed : null,
        ring: style.ring,
        ringRadius: style.radius,
        hover: style.hover,
        pressed: style.pressed,
        builder: (context, state) => DecoratedBox(
          decoration: BoxDecoration(
            color: open ? style.open : state.wash,
            borderRadius: style.radius,
          ),
          child: Padding(
            padding: style.padding,
            child: DefaultTextStyle.merge(style: style.textStyle, child: label),
          ),
        ),
      ),
    ),
  );
}
