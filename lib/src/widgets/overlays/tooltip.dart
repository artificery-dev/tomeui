import 'dart:async';

import 'package:tomeui/tomeui.dart';

/// A word about the thing underneath, shown on hover, on focus, or on a
/// long press.
///
/// The first [Popover] built on the shared one: an inverted panel that
/// annotates the page without interrupting it. It never takes the pointer,
/// so what it describes stays clickable, and it waits
/// ([TooltipStyle.wait]) before speaking — a pointer passing through gets
/// nothing to read.
///
/// Unlike the controls, a tooltip owns its own state: showing it isn't a
/// decision the caller makes, it's something the pointer does.
class Tooltip extends StatefulWidget {
  const Tooltip({
    required this.message,
    required this.child,
    this.side = PopoverSide.top,
    this.align = PopoverAlign.center,
    this.style,
    super.key,
  });

  /// What the tooltip says. A widget, like every other slot — text is the
  /// usual thing, and it wears [TooltipStyle.textStyle] without asking.
  final Widget message;

  /// What it's about.
  final Widget child;

  final PopoverSide side;
  final PopoverAlign align;

  /// The style to paint, bypassing the theme.
  final TooltipStyle? style;

  @override
  State<Tooltip> createState() => _TooltipState();
}

class _TooltipState extends State<Tooltip> {
  bool _showing = false;
  Timer? _waiting;

  @override
  void dispose() {
    _waiting?.cancel();
    super.dispose();
  }

  void _show(Duration wait) {
    _waiting?.cancel();
    if (_showing) return;
    if (wait == Duration.zero) {
      setState(() => _showing = true);
      return;
    }
    _waiting = Timer(wait, () {
      if (mounted) setState(() => _showing = true);
    });
  }

  void _hide() {
    _waiting?.cancel();
    _waiting = null;
    if (_showing) setState(() => _showing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.tooltip.resolve();

    return MouseRegion(
      onEnter: (_) => _show(style.wait),
      onExit: (_) => _hide(),
      child: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        // Keyboard users get the tooltip too, without the wait: arriving by
        // Tab is already deliberate.
        onFocusChange: (focused) => focused ? _show(Duration.zero) : _hide(),
        child: GestureDetector(
          // Translucent: an annotation notices the press wherever its child
          // sits, without taking it away from what's underneath.
          behavior: HitTestBehavior.translucent,
          // Touch has no hover; a long press is how it asks, and letting go
          // is how it stops asking.
          onLongPress: () => _show(Duration.zero),
          onLongPressEnd: (_) => _hide(),
          child: Popover(
            open: _showing,
            side: widget.side,
            align: widget.align,
            barrier: false,
            style: style.popover,
            anchor: widget.child,
            content: (context, _) => DefaultTextStyle.merge(
              style: style.textStyle,
              child: widget.message,
            ),
          ),
        ),
      ),
    );
  }
}
