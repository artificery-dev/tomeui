import 'package:tomeui/tomeui.dart';

/// What a navigation surface is made of.
///
/// One vocabulary for every widget that offers places to go — [Dock] takes
/// a list of [NavDestination] and nothing else, [NavList] takes the lot —
/// so an app that moves its navigation from a rail to a sidebar is moving
/// the same list, not writing a second one.
sealed class NavEntry {
  const NavEntry();
}

/// Somewhere to go.
class NavDestination<T> extends NavEntry {
  const NavDestination({
    required this.value,
    required this.label,
    this.icon,
    this.leading,
    this.selectedIcon,
    this.trailing,
    this.menu = const [],
    this.enabled = true,
  });

  /// What going here means.
  final T value;

  final Widget label;

  /// The glyph beside — or above — the label.
  final IconData? icon;

  /// The glyph while this is where you are, where the icon set has a
  /// filled twin. Null keeps [icon] either way.
  final IconData? selectedIcon;

  /// A widget in the glyph's place — an avatar, a status badge — drawn in
  /// the same icon-sized square and winning over [icon] and [selectedIcon]
  /// when set. A [Dock] keeps to [icon].
  final Widget? leading;

  /// After the label: an unread count, a status dot. A [Dock] hasn't the
  /// room and leaves it out.
  final Widget? trailing;

  /// What can be done to this place without going there — rename it,
  /// archive it, delete it. A [NavList] opens these at the pointer on a
  /// right-click or a long press anywhere on the row, without choosing the
  /// row. Empty, the row has no menu. A disabled row or list doesn't
  /// answer. A [Dock] hasn't the room and leaves it out.
  final List<MenuEntry> menu;

  final bool enabled;
}

/// Destinations under a heading you can fold away.
///
/// Give it a [value] and the group is a place of its own as well as a
/// heading: pressing the row goes there, the chevron folds, and a second
/// press within the double-tap window folds too. Without one the whole row
/// is the fold.
class NavGroup<T> extends NavEntry {
  const NavGroup({
    required this.label,
    this.value,
    this.destinations = const [],
    List<NavEntry>? entries,
    this.icon,
    this.leading,
    this.id,
    this.initiallyOpen = true,
    this.indent = true,
  }) : _entries = entries;

  final Widget label;

  /// What going to the group's own row means, for a group that is a place
  /// (a folder, a frame) rather than only a heading over places. Null, and
  /// pressing the row folds it.
  final T? value;

  /// What's inside, one step in from the group's own row.
  final List<NavDestination<T>> destinations;

  /// Destinations, headings, separators, and further groups inside the
  /// group, each nested group one more step in. When omitted,
  /// [destinations] supplies the children for existing callers.
  final List<NavEntry>? _entries;
  List<NavEntry> get entries => _entries ?? destinations;

  final IconData? icon;

  /// A widget in the glyph's place, drawn in the same icon-sized square and
  /// winning over [icon] when set.
  final Widget? leading;

  /// The name the group's fold is remembered by across rebuilds. Null
  /// falls back to [value], then to the value of the first destination
  /// inside it, nested groups searched in order — give an id to a group
  /// whose contents come and go, or whose first destination can change.
  final Object? id;

  /// Whether the group starts open. A group holding where you are opens
  /// regardless — a selected row nobody can see is worse than an open
  /// group nobody asked for.
  final bool initiallyOpen;

  /// Whether what's inside sits one step in from the group's own row.
  /// False keeps it flush with the row — for a sidebar whose groups are
  /// sections rather than a tree, where every step in is width the labels
  /// lose. Only the drawing changes: the group folds, walks, and spaces its
  /// rows the same either way, and a group inside still steps its own
  /// contents in unless told otherwise.
  final bool indent;
}

/// A label over a run of destinations, with nothing to fold.
class NavHeading extends NavEntry {
  const NavHeading(this.label);

  final Widget label;
}

/// A rule between runs.
class NavSeparator extends NavEntry {
  const NavSeparator();
}
