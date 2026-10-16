import 'package:flutter/gestures.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';
import '../foundation/list_walk.dart';

/// The sidebar's list of places.
///
/// What a [Scaffold]'s leading slot is usually holding: destinations,
/// headings over runs of them, groups that fold away — groups inside groups,
/// as deep as needed — and rules between.
/// The vocabulary is [NavEntry], the same one a [Dock] takes, so a shell
/// that offers a rail on a phone and a sidebar on a desktop is showing one
/// list two ways.
///
/// ```dart
/// NavList<Section>(
///   value: section,
///   onChanged: (value) => setState(() => section = value),
///   entries: [
///     const NavHeading(Text('Ship')),
///     NavDestination(value: Section.log, label: const Text('Log'),
///         icon: icons.file),
///     NavGroup(
///       label: const Text('Cargo'),
///       destinations: [
///         NavDestination(value: Section.manifest,
///             label: const Text('Manifest')),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// The list is as tall as its rows — wrap it in a scroll view where it can
/// outgrow the sidebar. It's one focus stop: the arrows walk the rows,
/// Enter takes one, and headings, rules, and disabled rows are stepped
/// over. Unlike a menu's walk it doesn't claim the keyboard on sight — a
/// sidebar that stole the focus as the page opened would be a nuisance.
class NavList<T> extends StatefulWidget {
  const NavList({
    required this.value,
    required this.onChanged,
    required this.entries,
    this.swatch = SemanticSwatch.primary,
    this.size = NavListSize.medium,
    this.style,
    super.key,
  });

  /// Where you are, or null when that's nowhere in this list.
  final T? value;

  /// Called with a destination's value when it's chosen. Null disables the
  /// whole list.
  final ValueChanged<T>? onChanged;

  final List<NavEntry> entries;

  /// The meaning the row you're on wears.
  final SemanticSwatch swatch;

  /// How large the rows sit — icons, type, and spacing together.
  final NavListSize size;

  /// The style to paint, bypassing the theme.
  final NavListStyle? style;

  @override
  State<NavList<T>> createState() => _NavListState<T>();
}

/// One line of the flattened list: what to draw, and how far in.
class _Row {
  const _Row(this.entry, {this.indent = 0, this.group});

  final Object entry;

  /// Steps in from the list's edge. Not how deeply the row is nested: a
  /// group that keeps its contents flush adds no step.
  final int indent;

  /// The group this row folds, when the row is a group's own.
  final NavGroup<Object?>? group;
}

class _NavListState<T> extends State<NavList<T>> {
  /// Groups the reader has folded open or shut, keyed by the group's
  /// [NavGroup.id] or else its first destination's value — the stable
  /// names a group carries. Object identity would forget every fold the
  /// moment a parent rebuild handed the list fresh entry instances, which
  /// parents do constantly. What the reader did wins over
  /// [NavGroup.initiallyOpen]: a group that starts shut has to open when
  /// tapped.
  final Map<Object?, bool> _folds = {};

  Object? _keyOf(NavGroup<Object?> group) =>
      group.id ??
      group.value ??
      _firstDestination(group.entries)?.value ??
      group;

  /// The last press on a group that is a place, so a second one inside the
  /// double-tap window folds it instead of choosing it again.
  (Object?, DateTime)? _lastPress;

  /// The first destination in [entries], nested groups searched in order.
  NavDestination<Object?>? _firstDestination(List<NavEntry> entries) {
    for (final entry in entries) {
      switch (entry) {
        case final NavDestination<Object?> destination:
          return destination;
        case final NavGroup<Object?> group:
          final inside = _firstDestination(group.entries);
          if (inside != null) return inside;
        default:
          break;
      }
    }
    return null;
  }

  /// Whether where you are sits anywhere inside [entries], however deep.
  bool _holdsValue(List<NavEntry> entries) => entries.any(
    (entry) => switch (entry) {
      NavDestination<Object?>(:final value) => value == widget.value,
      NavGroup<Object?>(:final value, :final entries) =>
        (value != null && value == widget.value) || _holdsValue(entries),
      _ => false,
    },
  );

  bool get _enabled => widget.onChanged != null;

  bool _open(NavGroup<Object?> group) {
    final folded = _folds[_keyOf(group)];
    if (folded == false) return false;
    // A group holding where you are — at any depth, so its ancestors too —
    // is open whatever it was told: a selected row nobody can see is worse
    // than an open group nobody asked for.
    if (_holdsValue(group.entries)) return true;
    return folded ?? group.initiallyOpen;
  }

  /// The entries as rows, with folded groups' contents left out.
  List<_Row> get _rows => _flatten(widget.entries);

  List<_Row> _flatten(List<NavEntry> entries) => [
    for (final entry in entries)
      if (entry is NavGroup<Object?>) ...[
        _Row(entry, group: entry),
        if (_open(entry)) ..._flatten(entry.entries),
      ] else
        _Row(entry),
  ];

  bool _walkable(_Row row) => switch (row.entry) {
    NavDestination(:final enabled) => enabled,
    NavGroup() => true,
    _ => false,
  };

  void _activate(_Row row) {
    if (!_enabled) return;
    switch (row.entry) {
      case NavDestination<T>(:final value, :final enabled):
        if (enabled && value != widget.value) widget.onChanged!(value);
      case NavGroup<T>(:final value?) && final group:
        final key = _keyOf(group);
        final now = DateTime.now();
        final last = _lastPress;
        _lastPress = (key, now);
        if (last != null &&
            last.$1 == key &&
            now.difference(last.$2) <= kDoubleTapTimeout) {
          _lastPress = null;
          _fold(group);
        } else if (value != widget.value) {
          widget.onChanged!(value);
        }
      case final NavGroup<Object?> group:
        _fold(group);
      default:
        break;
    }
  }

  void _fold(NavGroup<Object?> group) {
    if (!_enabled) return;
    setState(() => _folds[_keyOf(group)] = !_open(group));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style =
        widget.style ??
        theme.widgets.navList.resolve(widget.swatch, widget.size);
    final rows = _rows;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      enabled: _enabled,
      child: AnimatedOpacity(
        opacity: _enabled ? 1 : style.disabledOpacity,
        duration: theme.motion.fast,
        curve: theme.motion.move,
        child: ListWalk(
          length: rows.length,
          enabledAt: (index) => _enabled && _walkable(rows[index]),
          onActivate: (index) => _activate(rows[index]),
          // A sidebar doesn't take the keyboard as the page opens; it takes
          // it when someone tabs to it.
          autofocus: false,
          builder: (context, highlight, highlightTo) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _folded(theme, style, highlight, highlightTo),
          ),
        ),
      ),
    );
  }

  /// The rows, with each group's contents inside a fold of their own —
  /// nested groups inside their parent's fold, each with its own.
  ///
  /// The walk still sees the flat list — a shut group's rows are no part of
  /// it — so the indices here are counted the same way [_rows] counts them.
  /// A group on its way shut keeps drawing its rows while they collapse,
  /// and they are not walkable while they go: a row leaving is not a row
  /// you can arrive at.
  List<Widget> _folded(
    Theme theme,
    NavListStyle style,
    int? highlight,
    ValueChanged<int> highlightTo,
  ) {
    // [start] is the walk index of the first row, or null when these rows
    // are no part of the walk — inside a fold that's shut or shutting.
    // [depth] is how deeply nested the rows are; [indent] is how many steps
    // in they're drawn, which a flush group leaves where it was.
    List<Widget> lay(
      List<NavEntry> entries,
      int depth,
      int indent,
      int? start,
    ) {
      final children = <Widget>[];
      var index = start;

      for (final entry in entries) {
        final at = index;
        if (index != null) index++;
        // The gap goes before each row, never before a group's fold: the
        // fold carries its own inside, so a shut one takes up nothing at
        // all rather than leaving a gap where its rows were. Inside a fold
        // every row takes one, the first included — that's the gap after
        // the group's own row.
        if (depth > 0 || children.isNotEmpty) {
          children.add(SizedBox(height: style.rowGap));
        }
        children.add(
          _line(
            theme: theme,
            style: style,
            row: _Row(
              entry,
              indent: indent,
              group: entry is NavGroup<Object?> ? entry : null,
            ),
            highlighted: at != null && at == highlight,
            onHover: at != null ? () => highlightTo(at) : () {},
          ),
        );

        if (entry is! NavGroup<Object?>) continue;
        final open = _open(entry);
        final first = index != null && open ? index : null;
        if (first != null) {
          index = first + _flatten(entry.entries).length;
        }

        children.add(
          _Fold(
            open: open,
            duration: theme.motion.standard,
            curve: theme.motion.move,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: lay(
                entry.entries,
                depth + 1,
                entry.indent ? indent + 1 : indent,
                first,
              ),
            ),
          ),
        );
      }
      return children;
    }

    return lay(widget.entries, 0, 0, 0);
  }

  Widget _line({
    required Theme theme,
    required NavListStyle style,
    required _Row row,
    required bool highlighted,
    required VoidCallback onHover,
  }) => switch (row.entry) {
    NavHeading(:final label) => Padding(
      padding: EdgeInsetsDirectional.only(start: row.indent * style.indent),
      child: Padding(
        padding: style.headingPadding,
        child: DefaultTextStyle.merge(style: style.headingStyle, child: label),
      ),
    ),
    NavSeparator() => Padding(
      padding: EdgeInsetsDirectional.only(
        top: theme.space.x2,
        bottom: theme.space.x2,
        start: row.indent * style.indent,
      ),
      child: Divider(style: DividerStyle(color: style.separator)),
    ),
    final NavGroup<Object?> group => _NavRow(
      style: style,
      indent: row.indent,
      icon: group.icon,
      leading: group.leading,
      label: group.label,
      trailing: _Chevron(
        open: _open(group),
        size: style.iconSize,
        // A group that is a place keeps its row for going there; the
        // chevron alone folds it.
        onPressed: group.value != null && _enabled ? () => _fold(group) : null,
      ),
      menu: const [],
      selected: group.value != null && group.value == widget.value,
      highlighted: highlighted,
      enabled: _enabled,
      onHover: onHover,
      onPressed: () => _activate(row),
    ),
    final NavDestination<Object?> destination => _NavRow(
      style: style,
      indent: row.indent,
      icon: destination.value == widget.value
          ? (destination.selectedIcon ?? destination.icon)
          : destination.icon,
      leading: destination.leading,
      label: destination.label,
      trailing: destination.trailing,
      menu: destination.menu,
      selected: destination.value == widget.value,
      highlighted: highlighted,
      enabled: _enabled && destination.enabled,
      onHover: onHover,
      onPressed: () => _activate(row),
    ),
    _ => const SizedBox.shrink(),
  };
}

/// One pressable row: a glyph, its words, and whatever trails them —
/// with a menu behind a right-click or a long press when it has one.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.style,
    required this.indent,
    required this.icon,
    required this.leading,
    required this.label,
    required this.trailing,
    required this.menu,
    required this.selected,
    required this.highlighted,
    required this.enabled,
    required this.onHover,
    required this.onPressed,
  });

  final NavListStyle style;

  /// Steps in from the list's edge.
  final int indent;

  final IconData? icon;

  /// Drawn in the icon's square instead of [icon] when set.
  final Widget? leading;

  final Widget label;
  final Widget? trailing;

  /// What a right-click or a long press on the row offers. Empty, and it
  /// offers nothing; disabled, and it doesn't answer.
  final List<MenuEntry> menu;

  final bool selected;

  /// Where the keyboard is, which is not where you are.
  final bool highlighted;

  final bool enabled;
  final VoidCallback onHover;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final textStyle = selected ? style.selectedStyle : style.textStyle;
    final hasMenu = menu.isNotEmpty;

    final row = Semantics(
      selected: selected,
      enabled: enabled,
      button: true,
      child: MouseRegion(
        onEnter: (_) => onHover(),
        child: Interactive(
          onActivate: enabled ? onPressed : null,
          ring: style.ring,
          ringRadius: style.radius,
          hover: style.hover,
          pressed: style.pressed,
          disabledOpacity: style.disabledOpacity,
          builder: (context, state) => AnimatedContainer(
            duration: theme.motion.fast,
            curve: theme.motion.move,
            height: style.rowHeight,
            padding: style.padding,
            margin: EdgeInsetsDirectional.only(start: indent * style.indent),
            decoration: BoxDecoration(
              // The selection is the row's own color; the highlight and
              // the wash are what's happening to it this instant.
              color: selected
                  ? style.selected.fill
                  : state.wash ?? (highlighted ? style.highlight : null),
              borderRadius: style.radius,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  SizedBox.square(
                    dimension: style.iconSize,
                    child: IconTheme.merge(
                      data: IconThemeData(
                        color: textStyle.color,
                        size: style.iconSize,
                      ),
                      child: leading!,
                    ),
                  ),
                  SizedBox(width: style.gap),
                ] else if (icon != null) ...[
                  Icon(icon, size: style.iconSize, color: textStyle.color),
                  SizedBox(width: style.gap),
                ],
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    child: label,
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: style.gap),
                  // A column of its own, at least a glyph wide: a chevron
                  // and a count flush to the same edge still sit on
                  // different centers, and a sidebar reads down its
                  // trailing edge.
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: style.iconSize),
                    child: Center(
                      widthFactor: 1,
                      child: IconTheme.merge(
                        data: IconThemeData(color: textStyle.color),
                        child: DefaultTextStyle.merge(
                          style: style.headingStyle,
                          child: trailing!,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // Around the whole row, so a right-click or a long press anywhere on
    // it — the indent included — asks for the menu. A press that becomes a
    // long press is no longer a tap, so it never chooses the row as well.
    // Present while disabled too, only deaf: a list that's disabled for the
    // length of a request keeps every row's state rather than rebuilding it.
    return hasMenu
        ? ContextMenu(entries: menu, enabled: enabled, child: row)
        : row;
  }
}

/// The fold glyph at a group's trailing edge. With [onPressed] it is a
/// button of its own — the one part of a selectable group's row that folds
/// rather than chooses — and wins the tap over the row beneath it.
class _Chevron extends StatelessWidget {
  const _Chevron({required this.open, required this.size, this.onPressed});

  final bool open;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final glyph = Icon(
      open ? theme.icons.chevronDown : theme.icons.chevronRight,
      size: size,
    );
    if (onPressed == null) return glyph;
    return Semantics(
      button: true,
      label: open ? theme.labels.collapse : theme.labels.expand,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: glyph,
        ),
      ),
    );
  }
}

/// A run of rows that opens and shuts by its own height.
///
/// The rows stay laid out the whole way and the fold clips them, which is
/// what makes a group collapse rather than vanish and leave a gap closing
/// after it. Shut and still, it builds nothing at all — a sidebar shouldn't
/// carry the weight of every group it isn't showing.
class _Fold extends StatelessWidget {
  const _Fold({
    required this.open,
    required this.duration,
    required this.curve,
    required this.builder,
  });

  final bool open;
  final Duration duration;
  final Curve curve;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: open ? 1 : 0),
    duration: duration,
    curve: curve,
    builder: (context, extent, _) => extent == 0
        ? const SizedBox.shrink()
        : ClipRect(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              heightFactor: extent,
              child: builder(context),
            ),
          ),
  );
}
