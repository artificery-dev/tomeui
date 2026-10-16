import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import 'menu_panel.dart';

/// Anchors nested actions to their row while retaining the parent menu.
class MenuSubmenu extends StatefulWidget {
  /// Shares the root choice callback so selecting a leaf dismisses the whole menu.
  const MenuSubmenu({
    required this.item,
    required this.style,
    required this.active,
    required this.onChosen,
    required this.child,
    super.key,
  });
  final MenuItem item;
  final MenuStyle style;
  final bool active;
  final ValueChanged<MenuItem> onChosen;
  final Widget child;

  /// Retains the flyout's open state independently from pointer hover.
  @override
  MenuSubmenuState createState() => MenuSubmenuState();
}

/// Lets both pointer and keyboard navigation enter and leave the same flyout.
class MenuSubmenuState extends State<MenuSubmenu> {
  bool expanded = false;
  FocusNode? previousFocus;

  /// Remembers the parent keyboard walk for returning with Left or Escape.
  void open() {
    if (expanded) return;
    previousFocus = FocusManager.instance.primaryFocus;
    setState(() => expanded = true);
  }

  /// Restores navigation to the parent rather than dismissing every menu.
  void close() {
    setState(() => expanded = false);
    previousFocus?.requestFocus();
  }

  /// Moving to another parent entry closes its obsolete child menu.
  @override
  void didUpdateWidget(MenuSubmenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) expanded = false;
  }

  /// Uses the same themed popover and menu walk as top-level actions.
  @override
  Widget build(BuildContext context) => Popover(
    open: expanded,
    side: PopoverSide.right,
    align: PopoverAlign.start,
    barrier: PopoverBarrier.through,
    takeFocus: false,
    style: widget.style.popover,
    onDismiss: close,
    anchor: widget.child,
    content: (context, _) => Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.escape)) {
          close();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MenuPanel(
        entries: widget.item.children,
        style: widget.style,
        onChosen: widget.onChosen,
      ),
    ),
  );
}
