import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// App navigation docked to an edge: the rail and the bottom bar, in one
/// widget.
///
/// [Axis.horizontal] is the phone's bottom bar; [Axis.vertical] is the
/// desktop's rail. Same destinations, same state, same widget — a shell
/// that swaps one for the other at a breakpoint is changing an axis, not a
/// navigation model.
///
/// ```dart
/// Dock<Section>(
///   value: section,
///   onChanged: (value) => setState(() => section = value),
///   axis: band.atLeast(Breakpoint.medium) ? Axis.vertical : Axis.horizontal,
///   destinations: [
///     DockDestination(value: Section.home, label: const Text('Home'),
///         icon: icons.home),
///     DockDestination(value: Section.crew, label: const Text('Crew'),
///         icon: icons.group),
///   ],
/// )
/// ```
///
/// The dock never scrolls. What doesn't fit goes to a menu behind a *More*
/// button at the end of the run — a destination you have to swipe to reach
/// is a destination nobody reaches — and the button wears the chosen state
/// when the answer is one of the ones it's holding.
class Dock<T> extends StatefulWidget {
  const Dock({
    required this.value,
    required this.onChanged,
    required this.destinations,
    this.axis = Axis.horizontal,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  });

  /// Where you are, or null when that's nowhere in this dock.
  final T? value;

  /// Called with a destination's value when it's chosen. Null disables the
  /// whole dock.
  final ValueChanged<T>? onChanged;

  /// The places this dock offers. Destinations only: a dock is a run of
  /// places, so the headings and groups a [NavList] takes have no meaning
  /// here.
  final List<NavDestination<T>> destinations;

  /// Horizontal is the bottom bar, vertical the rail.
  final Axis axis;

  /// The meaning the chosen destination wears.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final DockStyle? style;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T> extends State<Dock<T>> {
  bool _overflowOpen = false;

  bool get _enabled => widget.onChanged != null;

  void _choose(NavDestination<T> destination) {
    if (!_enabled || !destination.enabled) return;
    if (destination.value != widget.value) widget.onChanged!(destination.value);
  }

  /// How many destinations the run has room for, given what one takes.
  /// Everything past that is the overflow menu's, and the *More* button
  /// takes a place of its own.
  int _room(double extent, DockStyle style) {
    final fits = extent <= 0 ? 0 : (extent / style.itemExtent).floor();
    if (fits >= widget.destinations.length) return widget.destinations.length;
    // One place goes to More, and at least one destination stays on the
    // bar — a dock of nothing but an overflow button is a menu.
    return fits <= 1 ? 1 : fits - 1;
  }

  @override
  Widget build(BuildContext context) {
    // In build, not the constructor: a list's length isn't a constant
    // expression, and `const Dock(...)` is worth keeping.
    assert(widget.destinations.isNotEmpty, 'A dock needs destinations.');
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.dock.resolve(widget.swatch);
    final horizontal = widget.axis == Axis.horizontal;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      enabled: _enabled,
      child: AnimatedOpacity(
        opacity: _enabled ? 1 : style.disabledOpacity,
        duration: theme.motion.fast,
        curve: theme.motion.move,
        child: Surface.custom(
          style: style.surface,
          padding: style.padding,
          child: SizedBox(
            width: horizontal ? null : style.thickness,
            height: horizontal ? style.thickness : null,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final extent = horizontal
                    ? constraints.maxWidth
                    : constraints.maxHeight;
                final shown = _room(extent, style);
                final hidden = widget.destinations.sublist(shown);

                // Along a bar the places share the width evenly, the way a
                // bottom bar's always have; down a rail they take a place
                // apiece and the rail's full width across.
                Widget place(Widget slot) => horizontal
                    ? Expanded(child: slot)
                    : SizedBox(height: style.itemExtent, child: slot);

                return Flex(
                  direction: widget.axis,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: horizontal
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.stretch,
                  children: [
                    for (final destination in widget.destinations.take(shown))
                      place(_item(theme, style, destination)),
                    if (hidden.isNotEmpty) place(_more(theme, style, hidden)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(Theme theme, DockStyle style, NavDestination<T> destination) {
    final chosen = destination.value == widget.value;
    return _DockSlot(
      style: style,
      chosen: chosen,
      enabled: _enabled && destination.enabled,
      icon: chosen
          ? (destination.selectedIcon ?? destination.icon)
          : destination.icon,
      label: destination.label,
      onPressed: () => _choose(destination),
    );
  }

  /// The rest of the destinations, behind one button. It wears the chosen
  /// state itself when the answer is in there — otherwise the dock would
  /// show nothing chosen at all.
  Widget _more(
    Theme theme,
    DockStyle style,
    List<NavDestination<T>> hidden,
  ) {
    final holdsAnswer = hidden.any(
      (destination) => destination.value == widget.value,
    );

    return Menu(
      open: _overflowOpen,
      side: widget.axis == Axis.horizontal
          ? PopoverSide.top
          : PopoverSide.right,
      onDismiss: () => setState(() => _overflowOpen = false),
      entries: [
        for (final destination in hidden)
          MenuItem(
            label: destination.label,
            leading: Icon(destination.icon),
            trailing: destination.value == widget.value
                ? Icon(theme.icons.confirm)
                : null,
            onPressed: _enabled && destination.enabled
                ? () {
                    setState(() => _overflowOpen = false);
                    _choose(destination);
                  }
                : null,
          ),
      ],
      anchor: _DockSlot(
        style: style,
        chosen: holdsAnswer,
        enabled: _enabled,
        icon: theme.icons.more,
        label: Text(theme.labels.more),
        onPressed: () => setState(() => _overflowOpen = !_overflowOpen),
      ),
    );
  }
}

/// One place in the run: a glyph in a pill when chosen, with its words
/// beneath.
class _DockSlot extends StatelessWidget {
  const _DockSlot({
    required this.style,
    required this.chosen,
    required this.enabled,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final DockStyle style;
  final bool chosen;
  final bool enabled;
  final IconData? icon;
  final Widget label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final textStyle = chosen ? style.selectedStyle : style.unselectedStyle;

    return Semantics(
      selected: chosen,
      enabled: enabled,
      button: true,
      child: Interactive(
        onActivate: enabled ? onPressed : null,
        ring: style.ring,
        ringRadius: style.indicator.radius,
        hover: style.hover,
        pressed: style.pressed,
        disabledOpacity: style.disabledOpacity,
        builder: (context, state) => Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The pill is the glyph's, so a destination with no glyph is
            // its words and nothing else.
            if (icon != null) ...[
              AnimatedContainer(
                duration: theme.motion.fast,
                curve: theme.motion.move,
                padding: style.indicatorPadding,
                decoration: BoxDecoration(
                  color: chosen
                      ? (state.wash == null
                            ? style.indicator.fill
                            : Color.alphaBlend(
                                state.wash!,
                                style.indicator.fill ??
                                    const Color(0x00000000),
                              ))
                      : state.wash,
                  borderRadius: style.indicator.radius,
                ),
                child: Icon(
                  icon,
                  size: style.iconSize,
                  color: chosen
                      ? style.indicator.foreground
                      : textStyle.color,
                ),
              ),
              SizedBox(height: style.gap),
            ],
            DefaultTextStyle.merge(
              style: textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
              child: label,
            ),
          ],
        ),
      ),
    );
  }
}
