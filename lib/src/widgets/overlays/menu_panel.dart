import 'package:tomeui/tomeui.dart';
import 'package:flutter/services.dart';

import 'menu_submenu.dart';

import '../foundation/list_walk.dart';

/// The body of a menu: the rows, the walk that moves through them, and the
/// scroll that takes over when there are more than fit.
///
/// Everything a menu *is* except where it floats — which is why the dropdown
/// [Menu] and a text field's desktop selection menu can be the same list of
/// [MenuEntry] rendered by the same code, one inside a [Popover] and the
/// other inside the editor's own overlay.
///
/// Toolkit-internal: not exported by the barrel.
class MenuPanel extends StatefulWidget {
  const MenuPanel({
    required this.entries,
    required this.style,
    required this.onChosen,
    this.autofocus = true,
    super.key,
  });

  final List<MenuEntry> entries;
  final MenuStyle style;

  /// A row was taken — by a click, or by Enter on the highlight.
  final ValueChanged<MenuItem> onChosen;

  /// Whether the panel claims the keyboard. See [ListWalk.autofocus].
  final bool autofocus;

  /// Retains submenu anchors across keyboard highlight changes.
  @override
  State<MenuPanel> createState() => _MenuPanelState();
}

/// Coordinates keyboard entry into flyouts without activating their parent row.
class _MenuPanelState extends State<MenuPanel> {
  final Map<int, GlobalKey<MenuSubmenuState>> submenus = {};
  int highlighted = -1;

  /// Chooses leaves directly while opening nested entries in place.
  void chooseAt(int index) {
    final item = widget.entries[index] as MenuItem;
    if (item.children.isNotEmpty) {
      submenus[index]?.currentState?.open();
    } else {
      widget.onChosen(item);
    }
  }

  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.arrowRight &&
          submenus.containsKey(highlighted)) {
        chooseAt(highlighted);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: ListWalk(
      length: widget.entries.length,
      enabledAt: (index) => switch (widget.entries[index]) {
        MenuItem(:final enabled) => enabled,
        _ => false,
      },
      onActivate: chooseAt,
      autofocus: widget.autofocus,
      builder: (context, highlight, highlightTo) {
        highlighted = highlight;
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.style.minWidth,
            maxHeight: widget.style.maxHeight,
          ),
          // A menu is as wide as its widest row and no wider: without this the
          // stretched column fills whatever the overlay offers, which is the
          // whole screen.
          child: IntrinsicWidth(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.entries.length; i++)
                    switch (widget.entries[i]) {
                      final MenuItem item when item.children.isNotEmpty =>
                        MenuSubmenu(
                          key: submenus.putIfAbsent(
                            i,
                            () => GlobalKey<MenuSubmenuState>(),
                          ),
                          item: item,
                          style: widget.style,
                          active: i == highlight,
                          onChosen: widget.onChosen,
                          child: _Item(
                            item: item,
                            style: widget.style,
                            highlighted: i == highlight,
                            onHover: () {
                              highlightTo(i);
                              submenus[i]?.currentState?.open();
                            },
                            onTap: () {
                              highlightTo(i);
                              chooseAt(i);
                            },
                          ),
                        ),
                      final MenuItem item => _Item(
                        item: item,
                        style: widget.style,
                        highlighted: i == highlight,
                        onHover: () => highlightTo(i),
                        onTap: () => widget.onChosen(item),
                      ),
                      MenuSeparator() => _Separator(style: widget.style),
                      final MenuSection section => _Section(
                        section: section,
                        style: widget.style,
                      ),
                    },
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// One row of an open [Menu].
class _Item extends StatelessWidget {
  const _Item({
    required this.item,
    required this.style,
    required this.highlighted,
    required this.onHover,
    required this.onTap,
  });

  final MenuItem item;
  final MenuStyle style;
  final bool highlighted;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();

    Widget row = Row(
      children: [
        if (item.leading != null) ...[
          IconTheme.merge(
            data: IconThemeData(size: style.iconSize),
            child: item.leading!,
          ),
          SizedBox(width: style.itemGap),
        ],
        Expanded(child: item.label),
        if (item.trailing != null || item.children.isNotEmpty) ...[
          SizedBox(width: style.itemGap),
          DefaultTextStyle.merge(
            style: style.trailingStyle,
            child: item.trailing ?? const Icon(LucideIcons.chevronRight),
          ),
        ],
      ],
    );

    // A row that means something wears that meaning, label and icon alike.
    final tint = item.swatch == null
        ? null
        : theme.widgets.text.tint(swatch: item.swatch);
    if (tint != null) {
      row = DefaultTextStyle.merge(
        style: TextStyle(color: tint),
        child: IconTheme.merge(
          data: IconThemeData(color: tint),
          child: row,
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: item.enabled,
      child: ListWalkRow(
        enabled: item.enabled,
        background: highlighted ? style.highlight : null,
        radius: style.itemRadius,
        padding: style.itemPadding,
        onHover: onHover,
        onTap: onTap,
        child: row,
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator({required this.style});

  final MenuStyle style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: style.separatorMargin,
    child: SizedBox(
      height: style.separatorThickness,
      child: ColoredBox(color: style.separator),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.section, required this.style});

  final MenuSection section;
  final MenuStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: style.sectionPadding,
      child: DefaultTextStyle.merge(
        style: style.sectionStyle,
        child: section.label,
      ),
    ),
  );
}
