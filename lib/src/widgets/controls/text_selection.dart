import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:tomeui/tomeui.dart';

import '../overlays/menu_panel.dart';

/// What can be done with the current selection, as menu entries.
///
/// The single list both presentations are built from: the bar a touch screen
/// gets above its selection, and the menu a desktop gets under its
/// right-click. [EditableTextState] decides *which* actions are available
/// right now — cut needs a selection, paste needs a clipboard — and the
/// theme's [Labels] decide what they're called, since the widgets layer
/// ships no words of its own.
///
/// Pass the result to [TextSelectionMenu.entries] after adding to it, and an
/// app's own verbs sit beside the system's in both presentations at once.
List<MenuEntry> textSelectionEntries(
  BuildContext context,
  EditableTextState state,
) {
  final labels = (ThemeProvider.maybeOf(context) ?? const Theme()).labels;
  return [
    for (final item in state.contextMenuButtonItems)
      MenuItem(
        label: Text(item.label ?? _word(item.type, labels)),
        onPressed: item.onPressed,
      ),
  ];
}

/// A button's type becomes a word. [ContextMenuButtonType.custom] carries
/// its own label — the platform's text-processing actions arrive that way —
/// so it never reaches here with anything to say.
String _word(ContextMenuButtonType type, Labels labels) => switch (type) {
  ContextMenuButtonType.cut => labels.cut,
  ContextMenuButtonType.copy => labels.copy,
  ContextMenuButtonType.paste => labels.paste,
  ContextMenuButtonType.selectAll => labels.selectAll,
  ContextMenuButtonType.delete => labels.delete,
  ContextMenuButtonType.lookUp => labels.lookUp,
  ContextMenuButtonType.searchWeb => labels.searchWeb,
  ContextMenuButtonType.share => labels.share,
  ContextMenuButtonType.liveTextInput => labels.scanText,
  ContextMenuButtonType.custom => '',
};

/// What a [TextField] shows when a selection asks to be acted on.
///
/// One list, two presentations, chosen by platform rather than by input:
///
/// - **Touch** (Android, iOS, Fuchsia) gets a bar — a pill of words floating
///   above the selection, below it when there's no room, clear of the drag
///   handles either way. Reachable with a thumb, which a vertical list of
///   small rows is not.
/// - **Desktop** gets the same entries as a menu, at the point that was
///   right-clicked, drawn by the same [MenuPanel] a dropdown [Menu] uses.
///
/// It doesn't take the keyboard. A selection menu that focused itself would
/// collapse the selection it's about.
///
/// This is `TextField`'s default `contextMenuBuilder`; hand a field its own
/// to add entries, reorder them, or replace the thing entirely.
class TextSelectionMenu extends StatelessWidget {
  const TextSelectionMenu({
    required this.editableTextState,
    this.entries,
    super.key,
  });

  final EditableTextState editableTextState;

  /// What to offer. Null asks [textSelectionEntries] what the editor can
  /// currently do.
  final List<MenuEntry>? entries;

  /// Whether this platform's selection is worked with a finger.
  static bool get _touch => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => true,
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final entries =
        this.entries ?? textSelectionEntries(context, editableTextState);
    if (entries.isEmpty) return const SizedBox.shrink();

    final anchors = editableTextState.contextMenuAnchors;
    // The overlay this is built into starts at the screen's edge, so the
    // padding below has to be taken back out of the anchors — they're in
    // the overlay's coordinates, not this widget's.
    final margin = theme.space.x2;
    final top = MediaQuery.paddingOf(context).top + margin;
    final adjustment = Offset(margin, top);
    final padding = EdgeInsets.fromLTRB(margin, top, margin, margin);

    return _touch
        ? Padding(
            padding: padding,
            child: CustomSingleChildLayout(
              delegate: TextSelectionToolbarLayoutDelegate(
                anchorAbove:
                    anchors.primaryAnchor - Offset(0, margin) - adjustment,
                // Below the selection, the bar has to clear the drag handle
                // hanging off the end of it.
                anchorBelow:
                    (anchors.secondaryAnchor ?? anchors.primaryAnchor) +
                    Offset(0, theme.sizes.iconLarge) -
                    adjustment,
              ),
              child: _Bar(entries: entries),
            ),
          )
        : Padding(
            padding: padding,
            child: CustomSingleChildLayout(
              delegate: DesktopTextSelectionToolbarLayoutDelegate(
                anchor:
                    (anchors.secondaryAnchor ?? anchors.primaryAnchor) -
                    adjustment,
              ),
              child: _Menu(
                entries: entries,
                onChosen: (item) {
                  // Closed first, then acted on — the order [Menu] takes.
                  editableTextState.hideToolbar();
                  item.onPressed?.call();
                },
              ),
            ),
          );
  }
}

/// The touch presentation: one pill, words in a row.
class _Bar extends StatelessWidget {
  const _Bar({required this.entries});

  final List<MenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final panel = theme.widgets.popover.resolve();
    final foreground = panel.surface.foreground;
    final opacities = theme.opacities;

    // A ghost button in the panel's own foreground: the bar is one surface,
    // and a button on it shouldn't introduce a second color.
    final button = theme.widgets.button
        .resolve(SemanticSwatch.neutral, SurfaceVariant.ghost)
        .copyWith(
          surface: SurfaceStyle(
            foreground: foreground,
            radius: theme.radii.full,
          ),
          padding: EdgeInsets.symmetric(horizontal: theme.space.x3),
          textStyle: theme.widgets.text.resolve(TextRole.label, on: foreground),
          ring: foreground,
          hover: foreground.withValues(alpha: opacities.hover),
          pressed: foreground.withValues(alpha: opacities.pressed),
          // The bar is already floating; nothing on it lifts.
          lift: 0,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: theme.radii.full,
        boxShadow: panel.shadow,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - theme.space.x8,
        ),
        child: Surface.custom(
          style: panel.surface.copyWith(radius: theme.radii.full),
          padding: EdgeInsets.symmetric(horizontal: theme.space.x1),
          // More verbs than fit — the platform's text-processing actions can
          // add several — scroll rather than overflow into a second menu.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in entries.whereType<MenuItem>())
                  Button.custom(
                    onPressed: item.onPressed,
                    style: button,
                    child: item.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The desktop presentation: the same rows a dropdown [Menu] draws.
class _Menu extends StatelessWidget {
  const _Menu({required this.entries, required this.onChosen});

  final List<MenuEntry> entries;
  final ValueChanged<MenuItem> onChosen;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = theme.widgets.menu.resolve();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: style.popover.surface.radius,
        boxShadow: style.popover.shadow,
      ),
      child: Surface.custom(
        style: style.popover.surface,
        padding: style.popover.padding,
        child: MenuPanel(
          entries: entries,
          style: style,
          onChosen: onChosen,
          // The field keeps the keyboard; this is walked by pointer.
          autofocus: false,
        ),
      ),
    );
  }
}

/// The grips either end of a selection on a touch screen.
///
/// A circle with one square corner, pointing at the character it holds:
/// rotated to hang off the start of the selection, the end of it, or — while
/// nothing is selected — below the caret, where dragging moves the caret
/// itself.
///
/// Given to [EditableText.selectionControls]; the toolbar half of the old
/// [TextSelectionControls] contract is dead, which is what
/// [TextSelectionHandleControls] says, so the menu comes from
/// [TextSelectionMenu] instead.
class TextSelectionHandles extends TextSelectionControls
    with TextSelectionHandleControls {
  TextSelectionHandles({required this.size, required this.color});

  /// How big the grip is drawn — and how much of it there is to grab.
  final double size;

  final Color color;

  @override
  Size getHandleSize(double textLineHeight) => Size(size, size);

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final handle = SizedBox.fromSize(
      size: getHandleSize(textLineHeight),
      child: CustomPaint(painter: _HandlePainter(color)),
    );
    // The square corner is drawn top-left, so each type turns it toward the
    // text it belongs to.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: switch (type) {
        TextSelectionHandleType.left => Transform.rotate(
          angle: math.pi / 2,
          child: handle,
        ),
        TextSelectionHandleType.right => handle,
        TextSelectionHandleType.collapsed => Transform.rotate(
          angle: math.pi / 4,
          child: handle,
        ),
      },
    );
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      switch (type) {
        // The point of each grip — the corner after rotation — is what lands
        // on the character.
        TextSelectionHandleType.left => Offset(size, 0),
        TextSelectionHandleType.right => Offset.zero,
        TextSelectionHandleType.collapsed => Offset(size / 2, -size / 5),
      };

  @override
  bool operator ==(Object other) =>
      other is TextSelectionHandles &&
      other.size == size &&
      other.color == color;

  @override
  int get hashCode => Object.hash(size, color);
}

class _HandlePainter extends CustomPainter {
  const _HandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    canvas.drawPath(
      Path()
        ..addOval(
          Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        )
        // The square that turns the circle into a pointer.
        ..addRect(Rect.fromLTWH(0, 0, radius, radius)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_HandlePainter oldDelegate) => oldDelegate.color != color;
}
