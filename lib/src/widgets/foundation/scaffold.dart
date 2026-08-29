import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

/// A band that dresses itself — its own surface, its own gutters.
///
/// A [Scaffold] dresses each toolbar and status bar in the theme's bar
/// surface and [ScaffoldStyle.barPadding]. A bar that implements this
/// interface is handed the band bare instead: no fill, no gutter.
/// [TitleBar] is one — its window buttons run to the very corner of the
/// window, which a gutter would hold them out of.
abstract interface class SelfDressedBar implements Widget {}

/// The page skeleton: bars across the top and bottom, sidebars down the
/// sides, and the body in the middle.
///
/// Five slots, and the scaffold's whole job is arranging them:
///
/// ```dart
/// Scaffold(
///   toolbars: [TitleRow(), BreadcrumbRow()],
///   leading: NavigationList(),
///   body: Document(),
///   trailing: Inspector(),
///   statusbars: [StatusRow()],
/// )
/// ```
///
/// [toolbars] and [statusbars] are lists rather than single widgets because
/// a shell's chrome stacks — a title row over a tab row, a status row under
/// a find bar — and each one is a full-width band. The theme's hairline is
/// the *body's* frame: drawn along the body's own edges where chrome
/// stands, never through the chrome, so the lines read as framing the
/// page. The bands bracket the body *and* the sidebars: a toolbar spans
/// the window, and the sidebars start beneath it. That keeps a
/// [ScaffoldSidebarToggle] in a toolbar visible while the sidebar it
/// controls is open, which is the whole reason to reach for it a second
/// time.
///
/// [leading] and [trailing] are sidebars, and they adapt: wide enough and
/// they stand beside the body; too narrow and the same widget is presented
/// as a drawer over the body, behind a scrim. What "too narrow" means is
/// [ScaffoldStyle.minBodyWidth] — the narrowest body the scaffold will
/// leave — and nothing else. The mode follows the window, never what's
/// currently showing, so a sidebar doesn't change character just because
/// its neighbour was closed.
///
/// The open/shut state is the scaffold's own: it hands a [ScaffoldState]
/// down through [ScaffoldStateProvider], and anything below can find it and
/// work the sidebars. [ScaffoldSidebarToggle] is that, as a button.
class Scaffold extends StatefulWidget {
  const Scaffold({
    this.body,
    this.toolbars = const [],
    this.statusbars = const [],
    this.leading,
    this.trailing,
    this.initialLeadingOpen,
    this.initialTrailingOpen,
    this.style,
    super.key,
  });

  /// The page itself, between the bars and inside the sidebars.
  final Widget? body;

  /// Full-width bands above the body, stacked in the order given.
  final List<Widget> toolbars;

  /// Full-width bands below the body, stacked in the order given.
  final List<Widget> statusbars;

  /// The sidebars. A null slot is no sidebar at all — a
  /// [ScaffoldSidebarToggle] pointed at one draws nothing rather than
  /// offering to open what isn't there.
  final Widget? leading;
  final Widget? trailing;

  /// Whether a sidebar starts open *while it's inline*. Null takes the
  /// default, which is open — a sidebar wide enough to stand beside the
  /// body may as well be doing so.
  ///
  /// Drawers are a separate question and always start shut: a drawer is
  /// over the body, and nothing should cover the page before it's asked
  /// to.
  final bool? initialLeadingOpen;
  final bool? initialTrailingOpen;

  /// The style to paint, bypassing the theme.
  final ScaffoldStyle? style;

  @override
  ScaffoldState createState() => ScaffoldState();
}

/// A [Scaffold]'s sidebar state, and the handle for changing it.
///
/// Reached through [ScaffoldStateProvider.of], which is also what makes the
/// reader rebuild when a sidebar opens or shuts.
class ScaffoldState extends State<Scaffold> {
  /// Whether each side is open, kept once per presentation. A sidebar
  /// closed as a drawer and a sidebar closed inline are two different
  /// statements, so widening the window restores what was true the last
  /// time the thing was inline rather than inheriting a decision made about
  /// a drawer.
  late final Map<ScaffoldSide, bool> _inlineOpen = {
    ScaffoldSide.leading: widget.initialLeadingOpen ?? true,
    ScaffoldSide.trailing: widget.initialTrailingOpen ?? true,
  };
  final Map<ScaffoldSide, bool> _drawerOpen = {
    ScaffoldSide.leading: false,
    ScaffoldSide.trailing: false,
  };

  /// Which presentation each side is in, from the last layout.
  final Map<ScaffoldSide, bool> _isDrawer = {
    ScaffoldSide.leading: false,
    ScaffoldSide.trailing: false,
  };

  /// Where each side's reveal starts on the very first frame, so a scaffold
  /// opens already settled instead of animating itself in.
  final Map<ScaffoldSide, double> _initial = {};

  final Map<ScaffoldSide, FocusScopeNode> _scopes = {
    for (final side in ScaffoldSide.values)
      side: FocusScopeNode(debugLabel: 'Scaffold ${side.name} drawer'),
  };

  @override
  void dispose() {
    for (final scope in _scopes.values) {
      scope.dispose();
    }
    super.dispose();
  }

  Widget? _slot(ScaffoldSide side) =>
      side == ScaffoldSide.leading ? widget.leading : widget.trailing;

  /// Whether there's a sidebar on this side at all.
  bool has(ScaffoldSide side) => _slot(side) != null;

  /// Whether this side is presented as a drawer over the body rather than
  /// standing beside it. A question about the window, not about what's
  /// showing.
  bool isDrawer(ScaffoldSide side) => _isDrawer[side]!;

  /// Whether this side is currently showing.
  bool isOpen(ScaffoldSide side) =>
      has(side) && (isDrawer(side) ? _drawerOpen[side]! : _inlineOpen[side]!);

  /// Show this side. Does nothing if the slot is empty.
  void open(ScaffoldSide side) => _set(side, true);

  /// Hide this side.
  void close(ScaffoldSide side) => _set(side, false);

  void toggle(ScaffoldSide side) => _set(side, !isOpen(side));

  void _set(ScaffoldSide side, bool value) {
    if (!has(side) || isOpen(side) == value) return;
    setState(() {
      (isDrawer(side) ? _drawerOpen : _inlineOpen)[side] = value;
    });
    if (!isDrawer(side)) return;
    // A drawer is modal enough to want the keyboard: that's what puts
    // Escape and the drawer's own contents within reach without a tap.
    // After the frame, because until the rebuild lands the drawer is still
    // outside the focus tree and the request would be dropped.
    if (value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && isOpen(side) && isDrawer(side)) {
          _scopes[side]!.requestFocus();
        }
      });
    } else {
      _scopes[side]!.unfocus();
    }
  }

  ScaffoldSidebar _snapshot(ScaffoldSide side) => ScaffoldSidebar(
    present: has(side),
    open: isOpen(side),
    drawer: isDrawer(side),
  );

  /// Which sides fit beside the body at this width.
  ///
  /// Leading has first refusal — it's the primary navigation, and the one
  /// a shell can least afford to hide — so trailing is the first to be
  /// asked to become a drawer. The room leading needs is counted whether
  /// or not it's open, since the mode is a fact about the window.
  void _measure(double width, ScaffoldStyle style) {
    final wide = width - style.sidebarWidth >= style.minBodyWidth;
    final both = width - style.sidebarWidth * 2 >= style.minBodyWidth;
    _isDrawer[ScaffoldSide.leading] = !wide;
    _isDrawer[ScaffoldSide.trailing] = has(ScaffoldSide.leading)
        ? !both
        : !wide;
  }

  void _closeDrawers() {
    for (final side in ScaffoldSide.values) {
      if (isDrawer(side)) close(side);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.scaffold.resolve();

    return LayoutBuilder(
      builder: (context, constraints) {
        _measure(constraints.maxWidth, style);
        return ScaffoldStateProvider(
          state: this,
          leading: _snapshot(ScaffoldSide.leading),
          trailing: _snapshot(ScaffoldSide.trailing),
          // The window wears the same hairline on its very outside
          // pixels — foreground, so no chrome or page erases it.
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: style.dividerThickness <= 0
                  ? null
                  : Border.all(
                      color: style.divider,
                      width: style.dividerThickness,
                    ),
            ),
            position: DecorationPosition.foreground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final bar in widget.toolbars) _band(style, bar),
                Expanded(child: _body(theme, style, constraints.maxWidth)),
                for (final bar in widget.statusbars) _band(style, bar),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One toolbar or status bar: the chrome dress and its gutters. A
  /// [SelfDressedBar] is handed the band bare.
  Widget _band(ScaffoldStyle style, Widget bar) => bar is SelfDressedBar
      ? bar
      : Surface.custom(style: style.bar, padding: style.barPadding, child: bar);

  /// The hairline is the body's frame: drawn on each of the body's own
  /// edges where chrome stands — under the toolbars but only across the
  /// body, along an inline sidebar, never through the chrome itself — so
  /// the lines read as framing the page rather than slicing the window.
  BoxBorder? _frame(ScaffoldStyle style) {
    if (style.dividerThickness <= 0) return null;
    final line = BorderSide(
      color: style.divider,
      width: style.dividerThickness,
    );
    bool beside(ScaffoldSide side) => has(side) && !isDrawer(side);
    return BorderDirectional(
      top: widget.toolbars.isEmpty ? BorderSide.none : line,
      bottom: widget.statusbars.isEmpty ? BorderSide.none : line,
      start: beside(ScaffoldSide.leading) ? line : BorderSide.none,
      end: beside(ScaffoldSide.trailing) ? line : BorderSide.none,
    );
  }

  Widget _body(Theme theme, ScaffoldStyle style, double width) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (has(ScaffoldSide.leading) && !isDrawer(ScaffoldSide.leading))
          _inline(theme, style, ScaffoldSide.leading),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(border: _frame(style)),
            // Over the page, not under it: a body that paints its own
            // ground (a pinned header, an opaque pane) must not erase
            // the frame it sits in.
            position: DecorationPosition.foreground,
            child: widget.body ?? const SizedBox.shrink(),
          ),
        ),
        if (has(ScaffoldSide.trailing) && !isDrawer(ScaffoldSide.trailing))
          _inline(theme, style, ScaffoldSide.trailing),
      ],
    );

    final drawers = [
      for (final side in ScaffoldSide.values)
        if (has(side) && isDrawer(side)) side,
    ];
    if (drawers.isEmpty) return row;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _closeDrawers,
      },
      // A drawer slides on a paint-time transform, which layout never sees
      // — so the Stack has no overflow to notice and wouldn't clip on its
      // own. Without this, a shut drawer paints over whatever is beside
      // the scaffold rather than off its edge.
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            row,
            _scrim(theme, style, drawers),
            for (final side in drawers) _drawer(theme, style, side, width),
          ],
        ),
      ),
    );
  }

  /// A sidebar standing beside the body. It reveals from its own edge —
  /// the panel keeps its width and slides out from under the frame, rather
  /// than the contents being squeezed narrower and back.
  Widget _inline(Theme theme, ScaffoldStyle style, ScaffoldSide side) =>
      _reveal(
        theme,
        side,
        builder: (t) => ClipRect(
          child: Align(
            alignment: side == ScaffoldSide.leading
                ? Alignment.centerRight
                : Alignment.centerLeft,
            widthFactor: t,
            // Full height outright: the Align above is for the width
            // reveal, and without saying so it would also shrink-wrap and
            // centre the panel vertically — a sidebar floating mid-window.
            child: SizedBox(
              width: style.sidebarWidth,
              height: double.infinity,
              child: _panel(style, side),
            ),
          ),
        ),
      );

  /// The same sidebar, over the body: pinned to its edge and slid in from
  /// off screen. Capped against the window so there's always a strip of
  /// scrim left to tap.
  Widget _drawer(
    Theme theme,
    ScaffoldStyle style,
    ScaffoldSide side,
    double width,
  ) {
    final leading = side == ScaffoldSide.leading;
    return Positioned(
      top: 0,
      bottom: 0,
      left: leading ? 0 : null,
      right: leading ? null : 0,
      child: _reveal(
        theme,
        side,
        builder: (t) => IgnorePointer(
          ignoring: !isOpen(side),
          child: ExcludeFocus(
            excluding: !isOpen(side),
            child: FractionalTranslation(
              translation: Offset(leading ? t - 1 : 1 - t, 0),
              child: SizedBox(
                width: math.min(style.drawerWidth, width * 0.85),
                child: FocusScope(
                  node: _scopes[side]!,
                  child: DecoratedBox(
                    decoration: BoxDecoration(boxShadow: style.drawerShadow),
                    child: _panel(style, side),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The wash over the body while any drawer is open, and the tap target
  /// that shuts them.
  Widget _scrim(Theme theme, ScaffoldStyle style, List<ScaffoldSide> drawers) {
    final showing = drawers.any(isOpen);
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: showing ? 1 : 0, end: showing ? 1 : 0),
        duration: theme.motion.standard,
        curve: showing ? theme.motion.enter : theme.motion.exit,
        builder: (context, t, _) => IgnorePointer(
          ignoring: t == 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeDrawers,
            child: ColoredBox(
              color: style.scrim.withValues(alpha: style.scrim.a * t),
            ),
          ),
        ),
      ),
    );
  }

  /// The reveal both presentations ride on: 0 shut, 1 open.
  ///
  /// [TweenAnimationBuilder] rather than a controller because the target is
  /// a pure function of the state we already hold, and its `begin` is only
  /// ever read on the first build — which is exactly where we want the
  /// settled value rather than a slide.
  Widget _reveal(
    Theme theme,
    ScaffoldSide side, {
    required Widget Function(double t) builder,
  }) {
    final open = isOpen(side);
    final start = _initial[side] ??= open ? 1.0 : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: start, end: open ? 1.0 : 0.0),
      duration: theme.motion.standard,
      curve: open ? theme.motion.enter : theme.motion.exit,
      builder: (context, t, _) => builder(t),
    );
  }

  /// The panel a sidebar's contents sit on. No hairline of its own — the
  /// line between sidebar and body is the body's frame.
  Widget _panel(ScaffoldStyle style, ScaffoldSide side) => Surface.custom(
    style: style.sidebar,
    padding: style.sidebarPadding,
    child: _slot(side)!,
  );
}

/// What one of a [Scaffold]'s sidebars is doing, the instant it's read.
@immutable
class ScaffoldSidebar {
  const ScaffoldSidebar({
    required this.present,
    required this.open,
    required this.drawer,
  });

  /// Whether the scaffold was given a sidebar for this side at all.
  final bool present;

  /// Whether it's showing.
  final bool open;

  /// Whether it's presented over the body rather than beside it.
  final bool drawer;

  @override
  bool operator ==(Object other) =>
      other is ScaffoldSidebar &&
      other.present == present &&
      other.open == open &&
      other.drawer == drawer;

  @override
  int get hashCode => Object.hash(present, open, drawer);
}

/// The enclosing [Scaffold]'s sidebar state, handed down the tree.
///
/// Read it to know what a sidebar is doing, call it to change it:
///
/// ```dart
/// final scaffold = ScaffoldStateProvider.of(context);
/// if (scaffold.leading.open) scaffold.close(ScaffoldSide.leading);
/// ```
///
/// Reading through [of] is what makes a widget rebuild when a sidebar opens,
/// shuts, or changes presentation — which is how a toggle knows to redraw
/// itself.
class ScaffoldStateProvider extends InheritedWidget {
  const ScaffoldStateProvider({
    required this.state,
    required this.leading,
    required this.trailing,
    required super.child,
    super.key,
  });

  /// The scaffold itself, for anything the snapshots don't cover.
  final ScaffoldState state;

  final ScaffoldSidebar leading;
  final ScaffoldSidebar trailing;

  ScaffoldSidebar sidebar(ScaffoldSide side) =>
      side == ScaffoldSide.leading ? leading : trailing;

  void open(ScaffoldSide side) => state.open(side);
  void close(ScaffoldSide side) => state.close(side);
  void toggle(ScaffoldSide side) => state.toggle(side);

  /// The enclosing scaffold, or null if there isn't one.
  static ScaffoldStateProvider? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ScaffoldStateProvider>();

  /// The enclosing scaffold. Throws if there isn't one — a widget that
  /// works a sidebar has nothing to work without a [Scaffold] above it.
  static ScaffoldStateProvider of(BuildContext context) {
    final provider = maybeOf(context);
    if (provider == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No Scaffold found above this widget.'),
        ErrorDescription(
          'ScaffoldStateProvider.of was called from a context with no '
          'Scaffold in it. The sidebar state it reads belongs to a '
          'scaffold, so there has to be one above.',
        ),
        ErrorHint(
          'Check that the widget really is inside the Scaffold — a route '
          'pushed on top of one is a new page, not a descendant, and an '
          'overlay entry hangs off the Overlay rather than off the page.',
        ),
      ]);
    }
    return provider;
  }

  @override
  bool updateShouldNotify(ScaffoldStateProvider oldWidget) =>
      oldWidget.leading != leading ||
      oldWidget.trailing != trailing ||
      oldWidget.state != state;
}

/// The button that opens and shuts one of a [Scaffold]'s sidebars.
///
/// Put one in a toolbar and point it at a side:
///
/// ```dart
/// Scaffold(
///   toolbars: [
///     Row(children: [ScaffoldSidebarToggle(ScaffoldSide.leading), ...]),
///   ],
///   leading: NavigationList(),
///   body: Document(),
/// )
/// ```
///
/// It finds the scaffold through [ScaffoldStateProvider] and works whatever
/// presentation that side is in — the same tap slides an inline sidebar out
/// of the row on a wide window and raises it as a drawer on a narrow one.
///
/// A toggle pointed at an empty slot draws nothing: a button offering to
/// open a sidebar that doesn't exist is a lie about the page.
class ScaffoldSidebarToggle extends StatelessWidget {
  const ScaffoldSidebarToggle(
    this.side, {
    this.icon,
    this.variant = SurfaceVariant.ghost,
    this.swatch = SemanticSwatch.neutral,
    super.key,
  });

  final ScaffoldSide side;

  /// The glyph, when the theme's [Icons.sidebarLeading] and
  /// [Icons.sidebarTrailing] aren't what this shell calls its panels.
  final IconData? icon;

  final SurfaceVariant variant;
  final SemanticSwatch swatch;

  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldStateProvider.of(context);
    final sidebar = scaffold.sidebar(side);
    if (!sidebar.present) return const SizedBox.shrink();

    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final glyph =
        icon ??
        switch (side) {
          ScaffoldSide.leading => theme.icons.sidebarLeading,
          ScaffoldSide.trailing => theme.icons.sidebarTrailing,
        };

    return Semantics(
      toggled: sidebar.open,
      label: sidebar.open ? theme.labels.hideSidebar : theme.labels.showSidebar,
      child: Button(
        onPressed: () => scaffold.toggle(side),
        variant: variant,
        swatch: swatch,
        center: Icon(glyph),
      ),
    );
  }
}
