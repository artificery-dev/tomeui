import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// One step on a [Breadcrumbs] trail.
class Crumb {
  const Crumb({required this.label, this.icon, this.onPressed});

  final Widget label;

  /// A glyph ahead of the label — a folder, a home, the kind of thing this
  /// step is.
  final IconData? icon;

  /// Going back to this step. Null makes the crumb a plain word: the
  /// current page's crumb never needs one, and neither does a step nobody
  /// can return to.
  final VoidCallback? onPressed;
}

/// Where you are, and the way back.
///
/// The last crumb is where you are: it wears the full voice and doesn't
/// take a press, whatever it was given. The rest are quiet, and light up
/// under the pointer.
///
/// ```dart
/// Breadcrumbs(
///   crumbs: [
///     Crumb(label: const Text('Fleet'), icon: icons.home, onPressed: toFleet),
///     Crumb(label: const Text('Endeavour'), onPressed: toShip),
///     Crumb(label: const Text('Manifest')),
///   ],
/// )
/// ```
///
/// [separator] replaces the chevron between steps — a slash, a dot, a
/// glyph of the app's own. The crumbs shrink before the trail overflows,
/// so a long name ellipsizes rather than pushing the rest off the end.
class Breadcrumbs extends StatelessWidget {
  const Breadcrumbs({
    required this.crumbs,
    this.separator,
    this.style,
    super.key,
  });

  /// The trail, root first.
  final List<Crumb> crumbs;

  /// What stands between two crumbs. Null takes the theme's
  /// [Icons.chevronRight].
  final Widget? separator;

  /// The style to paint, bypassing the theme.
  final BreadcrumbsStyle? style;

  @override
  Widget build(BuildContext context) {
    // In build, not the constructor: a list's length isn't a constant
    // expression, and `const Breadcrumbs(...)` is worth keeping.
    assert(crumbs.isNotEmpty, 'A trail needs crumbs.');
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.breadcrumbs.resolve();
    final last = crumbs.length - 1;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, crumb) in crumbs.indexed) ...[
            if (index > 0) ...[
              SizedBox(width: style.gap),
              separator ??
                  Icon(
                    theme.icons.chevronRight,
                    size: style.separatorSize,
                    color: style.separator,
                  ),
              SizedBox(width: style.gap),
            ],
            Flexible(
              child: _Crumb(
                crumb: crumb,
                style: style,
                // The end of the trail is a statement, not a way back.
                current: index == last,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.crumb,
    required this.style,
    required this.current,
  });

  final Crumb crumb;
  final BreadcrumbsStyle style;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final textStyle = current ? style.currentStyle : style.textStyle;

    Widget words() => DefaultTextStyle.merge(
      style: textStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      child: Padding(
        padding: style.padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (crumb.icon != null) ...[
              Icon(
                crumb.icon,
                size: style.iconSize,
                color: textStyle.color,
              ),
              SizedBox(width: style.iconGap),
            ],
            Flexible(child: crumb.label),
          ],
        ),
      ),
    );

    if (current || crumb.onPressed == null) {
      return Semantics(header: current, child: words());
    }

    return Semantics(
      button: true,
      child: Interactive(
        onActivate: crumb.onPressed,
        ring: style.ring,
        ringRadius: style.radius,
        hover: style.hover,
        pressed: style.pressed,
        builder: (context, state) => DecoratedBox(
          decoration: BoxDecoration(
            color: state.wash,
            borderRadius: style.radius,
          ),
          child: words(),
        ),
      ),
    );
  }
}
