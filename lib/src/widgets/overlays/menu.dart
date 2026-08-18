import 'package:tomeui/tomeui.dart';

import 'menu_panel.dart';

/// One entry in a [Menu]. Sealed: a menu holds items, separators, and
/// section labels, and nothing else has ever needed to be in one.
sealed class MenuEntry {
  const MenuEntry();
}

/// A thing to do.
///
/// A null [onPressed] disables the row — the same rule [Button] follows —
/// so a menu that offers an action it can't currently perform shows it
/// dimmed rather than hiding it and moving everything else.
class MenuItem extends MenuEntry {
  const MenuItem({
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.swatch,
  });

  final Widget label;

  /// What choosing it does. Null disables the row: it dims, and the walk
  /// steps straight over it.
  final VoidCallback? onPressed;

  /// An icon ahead of the label, sized by the menu.
  final Widget? leading;

  /// The shortcut hint, or whatever else belongs at the end of the row.
  /// Dressed quietly — it's a reminder, not a second label.
  final Widget? trailing;

  /// A meaning for the row to wear: [SemanticSwatch.error] on Delete is the
  /// whole reason this exists. Null keeps the panel's own foreground.
  final SemanticSwatch? swatch;

  bool get enabled => onPressed != null;
}

/// The hairline between groups of entries.
class MenuSeparator extends MenuEntry {
  const MenuSeparator();
}

/// A label over a group of entries. Not a row: it can't be walked to,
/// hovered, or chosen.
class MenuSection extends MenuEntry {
  const MenuSection(this.label);

  final Widget label;
}

/// The dropdown and context menus, on [Popover].
///
/// Controlled like everything else — [open] says whether it's showing and
/// [onDismiss] reports that something asked it to close. Choosing an item
/// closes the menu first and *then* runs the action, so an action that
/// opens a dialog doesn't race the menu's own dismissal.
///
/// The list walks with the arrow keys, wrapping at both ends, and steps
/// over separators, section labels, and disabled items. Escape closes.
///
/// ```dart
/// Menu(
///   open: showing,
///   onDismiss: () => setState(() => showing = false),
///   anchor: Button(
///     onPressed: () => setState(() => showing = !showing),
///     center: const Text('Actions'),
///   ),
///   entries: [
///     const MenuSection(Text('Manifest')),
///     MenuItem(label: const Text('Duplicate'), onPressed: duplicate),
///     const MenuSeparator(),
///     MenuItem(
///       label: const Text('Delete'),
///       swatch: SemanticSwatch.error,
///       onPressed: delete,
///     ),
///   ],
/// )
/// ```
class Menu extends StatelessWidget {
  const Menu({
    required this.open,
    required this.entries,
    required this.anchor,
    this.onDismiss,
    this.side = PopoverSide.bottom,
    this.align = PopoverAlign.start,
    this.anchorRect,
    this.style,
    super.key,
  });

  /// Whether the menu is showing. The caller owns this.
  final bool open;

  final List<MenuEntry> entries;

  /// What the menu hangs off. Always in the tree, open or shut.
  final Widget anchor;

  final VoidCallback? onDismiss;

  final PopoverSide side;
  final PopoverAlign align;

  /// Hang off a point rather than off [anchor] — see [Popover.anchorRect].
  /// This is what [ContextMenu] passes.
  final Rect? anchorRect;

  /// The style to paint, bypassing the theme.
  final MenuStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.menu.resolve();

    void choose(MenuItem item) {
      onDismiss?.call();
      item.onPressed?.call();
    }

    return Popover(
      open: open,
      side: side,
      align: align,
      anchorRect: anchorRect,
      onDismiss: onDismiss,
      // The list walks itself with the arrows, so it holds the keyboard;
      // Escape still carries up to the popover.
      takeFocus: false,
      style: style.popover,
      anchor: anchor,
      content: (context, _) =>
          MenuPanel(entries: entries, style: style, onChosen: choose),
    );
  }
}

/// A menu summoned by the pointer: right-click on a desktop, a long press
/// on a touch screen.
///
/// Opens at the point that summoned it rather than at the edge of [child],
/// which is what makes it feel attached to the thing under the cursor. The
/// position is fixed once taken, so the menu closes rather than following a
/// page that scrolls out from under it.
///
/// ```dart
/// ContextMenu(
///   entries: [MenuItem(label: const Text('Rename'), onPressed: rename)],
///   child: const Placeholder(child: Text('Right-click me')),
/// )
/// ```
class ContextMenu extends StatefulWidget {
  const ContextMenu({
    required this.entries,
    required this.child,
    this.style,
    super.key,
  });

  final List<MenuEntry> entries;

  /// What the menu belongs to. The whole of it answers the pointer.
  final Widget child;

  final MenuStyle? style;

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  /// Where the pointer was when it asked, in global coordinates.
  Offset? _at;

  void _openAt(Offset global) => setState(() => _at = global);

  @override
  Widget build(BuildContext context) => Menu(
    open: _at != null,
    entries: widget.entries,
    style: widget.style,
    onDismiss: () => setState(() => _at = null),
    // A point, given a pixel of size: a zero-area rectangle overlaps
    // nothing, and the popover reads that as "scrolled out of sight".
    anchorRect: _at == null ? null : _at! & const Size(1, 1),
    anchor: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => _openAt(details.globalPosition),
      onLongPressStart: (details) => _openAt(details.globalPosition),
      child: widget.child,
    ),
  );
}
