import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';
import '../foundation/list_walk.dart';

/// The sidebar's list of places.
///
/// What a [Scaffold]'s leading slot is usually holding: destinations,
/// headings over runs of them, groups that fold away, and rules between.
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

  /// The style to paint, bypassing the theme.
  final NavListStyle? style;

  @override
  State<NavList<T>> createState() => _NavListState<T>();
}

/// One line of the flattened list: what to draw, and how far in.
class _Row {
  const _Row(this.entry, {this.depth = 0, this.group});

  final Object entry;
  final int depth;

  /// The group this row folds, when the row is a group's own.
  final NavGroup<Object?>? group;
}

class _NavListState<T> extends State<NavList<T>> {
  /// Groups the reader has folded shut, by identity — a group has no key
  /// of its own, and its label is a widget rather than a name.
  final Set<NavGroup<Object?>> _shut = {};

  bool get _enabled => widget.onChanged != null;

  bool _open(NavGroup<Object?> group) {
    if (_shut.contains(group)) return false;
    // A group holding where you are is open whatever it was told: a
    // selected row nobody can see is worse than an open group nobody asked
    // for.
    if (group.destinations.any((one) => one.value == widget.value)) return true;
    return group.initiallyOpen;
  }

  /// The entries as rows, with folded groups' contents left out.
  List<_Row> get _rows => [
    for (final entry in widget.entries)
      ...switch (entry) {
        NavGroup<Object?>(:final destinations) => [
          _Row(entry, group: entry),
          if (_open(entry))
            for (final destination in destinations) _Row(destination, depth: 1),
        ],
        _ => [_Row(entry)],
      },
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
      case final NavGroup<Object?> group:
        setState(() => _open(group) ? _shut.add(group) : _shut.remove(group));
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.navList.resolve(widget.swatch);
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

  /// The rows, with each group's destinations inside a fold of their own.
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
    final children = <Widget>[];
    var index = 0;

    for (final entry in widget.entries) {
      final at = index++;
      children.add(
        _line(
          theme: theme,
          style: style,
          row: _Row(entry, group: entry is NavGroup<Object?> ? entry : null),
          highlighted: at == highlight,
          onHover: () => highlightTo(at),
        ),
      );

      if (entry is! NavGroup<Object?>) continue;
      final open = _open(entry);
      final first = index;
      if (open) index += entry.destinations.length;

      children.add(
        _Fold(
          open: open,
          duration: theme.motion.standard,
          curve: theme.motion.move,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (offset, destination) in entry.destinations.indexed)
                _line(
                  theme: theme,
                  style: style,
                  row: _Row(destination, depth: 1),
                  highlighted: open && first + offset == highlight,
                  onHover: open ? () => highlightTo(first + offset) : () {},
                ),
            ],
          ),
        ),
      );
    }
    return children;
  }

  Widget _line({
    required Theme theme,
    required NavListStyle style,
    required _Row row,
    required bool highlighted,
    required VoidCallback onHover,
  }) => switch (row.entry) {
    NavHeading(:final label) => Padding(
      padding: style.headingPadding,
      child: DefaultTextStyle.merge(style: style.headingStyle, child: label),
    ),
    NavSeparator() => Padding(
      padding: EdgeInsets.symmetric(vertical: theme.space.x2),
      child: Divider(style: DividerStyle(color: style.separator)),
    ),
    final NavGroup<Object?> group => _NavRow(
      style: style,
      depth: row.depth,
      icon: group.icon,
      label: group.label,
      trailing: Icon(
        _open(group) ? theme.icons.chevronDown : theme.icons.chevronRight,
        size: style.iconSize,
      ),
      selected: false,
      highlighted: highlighted,
      enabled: _enabled,
      onHover: onHover,
      onPressed: () => _activate(row),
    ),
    final NavDestination<Object?> destination => _NavRow(
      style: style,
      depth: row.depth,
      icon: destination.value == widget.value
          ? (destination.selectedIcon ?? destination.icon)
          : destination.icon,
      label: destination.label,
      trailing: destination.trailing,
      selected: destination.value == widget.value,
      highlighted: highlighted,
      enabled: _enabled && destination.enabled,
      onHover: onHover,
      onPressed: () => _activate(row),
    ),
    _ => const SizedBox.shrink(),
  };
}

/// One pressable row: a glyph, its words, and whatever trails them.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.style,
    required this.depth,
    required this.icon,
    required this.label,
    required this.trailing,
    required this.selected,
    required this.highlighted,
    required this.enabled,
    required this.onHover,
    required this.onPressed,
  });

  final NavListStyle style;
  final int depth;
  final IconData? icon;
  final Widget label;
  final Widget? trailing;
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

    return Semantics(
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
            margin: EdgeInsetsDirectional.only(start: depth * style.indent),
            decoration: BoxDecoration(
              // The selection is the row's own colour; the highlight and
              // the wash are what's happening to it this instant.
              color: selected
                  ? style.selected.fill
                  : state.wash ?? (highlighted ? style.highlight : null),
              borderRadius: style.radius,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
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
                  // different centres, and a sidebar reads down its
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
