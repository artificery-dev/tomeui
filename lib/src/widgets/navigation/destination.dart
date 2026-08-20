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
    this.selectedIcon,
    this.trailing,
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

  /// After the label: an unread count, a status dot. A [Dock] hasn't the
  /// room and leaves it out.
  final Widget? trailing;

  final bool enabled;
}

/// Destinations under a heading you can fold away.
class NavGroup<T> extends NavEntry {
  const NavGroup({
    required this.label,
    required this.destinations,
    this.icon,
    this.initiallyOpen = true,
  });

  final Widget label;

  /// What's inside, one step in from the group's own row.
  final List<NavDestination<T>> destinations;

  final IconData? icon;

  /// Whether the group starts open. A group holding where you are opens
  /// regardless — a selected row nobody can see is worse than an open
  /// group nobody asked for.
  final bool initiallyOpen;
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
