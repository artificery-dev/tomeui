import 'package:tomeui/tomeui.dart';

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
class MenuPanel extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) => ListWalk(
    length: entries.length,
    enabledAt: (index) => switch (entries[index]) {
      MenuItem(:final enabled) => enabled,
      _ => false,
    },
    onActivate: (index) => onChosen(entries[index] as MenuItem),
    autofocus: autofocus,
    builder: (context, highlight, highlightTo) => ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: style.minWidth,
        maxHeight: style.maxHeight,
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
              for (var i = 0; i < entries.length; i++)
                switch (entries[i]) {
                  final MenuItem item => _Item(
                    item: item,
                    style: style,
                    highlighted: i == highlight,
                    onHover: () => highlightTo(i),
                    onTap: () => onChosen(item),
                  ),
                  MenuSeparator() => _Separator(style: style),
                  final MenuSection section => _Section(
                    section: section,
                    style: style,
                  ),
                },
            ],
          ),
        ),
      ),
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
        if (item.trailing != null) ...[
          SizedBox(width: style.itemGap),
          DefaultTextStyle.merge(
            style: style.trailingStyle,
            child: item.trailing!,
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
