import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/overlay_dress.dart';

/// Builds a popover's contents, told the anchor's rectangle so a panel can
/// match the trigger it hangs off — a select's list is the width of its
/// closed control.
typedef PopoverContentBuilder =
    Widget Function(BuildContext context, Rect anchor);

/// The floating surface menus, selects, and tooltips share: a panel
/// anchored to a trigger, above everything else on the page.
///
/// Controlled, like every other Tome control — [open] says whether it's
/// showing, [onDismiss] reports that something asked it to close (a tap
/// outside, Escape) and the caller decides whether to believe it:
///
/// ```dart
/// Popover(
///   open: showing,
///   onDismiss: () => setState(() => showing = false),
///   anchor: Button(onPressed: ..., center: const Text('Options')),
///   content: (context) => const Text('…'),
/// )
/// ```
///
/// [side] and [align] are a preference, not a promise: a popover with no
/// room where it wanted to go flips to the opposite side and slides along
/// the anchor's edge to stay on screen.
class Popover extends StatefulWidget {
  const Popover({
    required this.open,
    required this.anchor,
    required this.content,
    this.onDismiss,
    this.side = PopoverSide.bottom,
    this.align = PopoverAlign.center,
    this.barrier = PopoverBarrier.blocking,
    this.takeFocus = true,
    this.anchorRect,
    this.style,
    super.key,
  });

  /// Whether the panel is showing. The caller owns this.
  final bool open;

  /// The trigger the panel hangs off. Always in the tree, open or shut.
  final Widget anchor;

  /// The panel's contents, built when it opens and again whenever the
  /// anchor moves.
  final PopoverContentBuilder content;

  /// Something asked the popover to close. Null means it can't be
  /// dismissed from inside — the caller closes it on its own terms.
  final VoidCallback? onDismiss;

  final PopoverSide side;
  final PopoverAlign align;

  /// What goes between the panel and the page — see [PopoverBarrier].
  final PopoverBarrier barrier;

  /// Whether the panel claims the keyboard on the content's behalf, which
  /// is what puts Escape within reach of a panel of plain words.
  ///
  /// Content that handles its own keys — a list walked with the arrows —
  /// passes false and focuses a node of its own instead. Anything it
  /// doesn't handle still reaches the popover on the way up.
  final bool takeFocus;

  /// Hang off this rectangle instead of off [anchor]'s own box, in global
  /// coordinates. A context menu passes the point the pointer was at, since
  /// what it belongs to is that point rather than the whole widget under it.
  ///
  /// A fixed rectangle doesn't move with the page, so a popover placed this
  /// way is one the caller closes when anything scrolls.
  final Rect? anchorRect;

  /// The style to paint, bypassing the theme.
  final PopoverStyle? style;

  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  bool _syncing = false;
  final List<ScrollPosition> _watched = [];
  bool _following = false;
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'Popover');
  // Built here rather than lazily: a controller wants a ticker, a ticker
  // asks the tree, and a popover that was never opened would be asking it
  // from dispose — too late to be answered.
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    if (widget.open) _scheduleSync();
  }

  @override
  void didUpdateWidget(Popover oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleSync();
  }

  /// Touching the overlay during build marks it dirty mid-build, and the
  /// anchor has no rectangle until it's laid out. Both say: wait a frame.
  void _scheduleSync() {
    if (_syncing) return;
    _syncing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncing = false;
      _sync();
    });
  }

  @override
  void dispose() {
    _unwatch();
    _scope.dispose();
    _entry?.remove();
    _entry = null;
    _animation.dispose();
    super.dispose();
  }

  /// Follow every scrollable between here and the root: when any of them
  /// moves, so does the anchor, and the panel has to go with it.
  void _watch() {
    _unwatch();
    BuildContext? cursor = context;
    ScrollableState? previous;
    // Nested scrollables all count; the cap is a guard, not a limit anyone
    // should reach.
    for (var depth = 0; cursor != null && depth < 16; depth++) {
      final scrollable = Scrollable.maybeOf(cursor);
      if (scrollable == null || scrollable == previous) break;
      _watched.add(scrollable.position..addListener(_anchorMoved));
      previous = scrollable;
      cursor = scrollable.context;
    }
  }

  void _unwatch() {
    for (final position in _watched) {
      position.removeListener(_anchorMoved);
    }
    _watched.clear();
  }

  /// Always after the frame: marking dirty mid-frame is illegal, and a
  /// rebuild before layout would read the anchor's *old* rectangle. The
  /// panel therefore trails a scroll by a frame — invisible in practice,
  /// and the price of placing by layout rather than by paint transform.
  void _anchorMoved() {
    if (_entry == null || _following) return;
    _following = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _following = false;
      _entry?.markNeedsBuild();
    });
  }

  void _sync() {
    if (!mounted) return;
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    _animation.duration = theme.motion.fast;
    if (widget.open) {
      if (_entry == null) {
        _watch();
        _entry = OverlayEntry(builder: _buildOverlay);
        // The root overlay, not the nearest: a nested navigator — a
        // routing shell, say — brings an overlay that covers only its own
        // corner of the window, and a panel inserted there is placed in
        // that corner's coordinates and clipped to it besides.
        Overlay.of(context, rootOverlay: true).insert(_entry!);
      } else {
        // Anchor, style, or content may have moved under it.
        _entry!.markNeedsBuild();
      }
      _animation.forward();
    } else if (_entry != null) {
      // Let it fade out before it leaves the tree.
      _unwatch();
      _animation.reverse().whenComplete(() {
        if (_animation.value != 0) return;
        _entry?.remove();
        _entry = null;
      });
    }
  }

  /// The anchor's rectangle in the root overlay's coordinates — the space
  /// the panel is laid out in — or null before layout. Usually those are
  /// global coordinates too; converting keeps it true when they aren't.
  Rect? get _anchorRect {
    if (widget.anchorRect != null) return widget.anchorRect;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox?;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    return topLeft & box.size;
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.popover.resolve();
    final anchor = _anchorRect;
    if (anchor == null) return const SizedBox.shrink();
    // Scrolled out of sight: a panel pinned to an anchor nobody can see is
    // just litter on the screen.
    final view = Offset.zero & MediaQuery.sizeOf(overlayContext);
    if (!anchor.overlaps(view)) return const SizedBox.shrink();

    Widget panel = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: style.maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: style.surface.radius,
          boxShadow: style.shadow,
        ),
        child: Surface.custom(
          style: style.surface,
          padding: style.padding,
          child: Builder(builder: (context) => widget.content(context, anchor)),
        ),
      ),
    );

    // Grows out of the anchor rather than appearing on top of it.
    panel = FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: _animation, curve: theme.motion.enter),
        ),
        alignment: _growth(widget.side),
        child: panel,
      ),
    );

    final Widget placed = CustomSingleChildLayout(
      delegate: _PopoverLayout(
        anchor: anchor,
        side: widget.side,
        align: widget.align,
        gap: style.gap,
        margin: style.margin,
      ),
      child: dressForOverlay(
        theme: theme,
        foreground: style.surface.foreground,
        child: panel,
      ),
    );

    if (widget.barrier == PopoverBarrier.none) {
      // A tooltip must not eat the pointer: it's an annotation, and the
      // thing it annotates stays clickable underneath.
      return Positioned.fill(child: IgnorePointer(child: placed));
    }

    return Stack(
      children: [
        Positioned.fill(
          child: widget.barrier == PopoverBarrier.blocking
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onDismiss,
                )
              // Translucent: the press dismisses on its way past, and
              // carries on to whatever it was aimed at. Hover passes too,
              // which is what lets a bar's next word light up.
              : Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => widget.onDismiss?.call(),
                ),
        ),
        // A barrier popover takes the keyboard with it — that's what makes
        // Escape reach it, and what a menu or select wants anyway. The
        // autofocused node is inside the shortcut so events bubble up to
        // it.
        Positioned.fill(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  widget.onDismiss?.call(),
            },
            child: FocusScope(
              node: _scope,
              child: widget.takeFocus
                  ? Focus(autofocus: true, child: placed)
                  : placed,
            ),
          ),
        ),
      ],
    );
  }

  /// The corner the panel expands from: the one nearest its anchor.
  static Alignment _growth(PopoverSide side) => switch (side) {
    PopoverSide.top => Alignment.bottomCenter,
    PopoverSide.bottom => Alignment.topCenter,
    PopoverSide.left => Alignment.centerRight,
    PopoverSide.right => Alignment.centerLeft,
  };

  @override
  Widget build(BuildContext context) {
    return widget.anchor;
  }
}

/// Places the panel beside its anchor: on the wanted side if it fits, the
/// opposite side if it doesn't, slid along the edge to stay on screen.
class _PopoverLayout extends SingleChildLayoutDelegate {
  const _PopoverLayout({
    required this.anchor,
    required this.side,
    required this.align,
    required this.gap,
    required this.margin,
  });

  final Rect anchor;
  final PopoverSide side;
  final PopoverAlign align;
  final double gap;
  final double margin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          (constraints.maxWidth - margin * 2).clamp(0, double.infinity),
          (constraints.maxHeight - margin * 2).clamp(0, double.infinity),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final vertical = side == PopoverSide.top || side == PopoverSide.bottom;
    final resolved = _fits(side, size, childSize)
        ? side
        : _fits(_opposite(side), size, childSize)
        // No room where it wanted to go, but room across the anchor.
        ? _opposite(side)
        : side;

    final double main = switch (resolved) {
      PopoverSide.top => anchor.top - gap - childSize.height,
      PopoverSide.bottom => anchor.bottom + gap,
      PopoverSide.left => anchor.left - gap - childSize.width,
      PopoverSide.right => anchor.right + gap,
    };

    // Along the anchor's edge, then slid back inside the screen.
    final crossExtent = vertical ? childSize.width : childSize.height;
    final anchorStart = vertical ? anchor.left : anchor.top;
    final anchorEnd = vertical ? anchor.right : anchor.bottom;
    final cross = switch (align) {
      PopoverAlign.start => anchorStart,
      PopoverAlign.center =>
        anchorStart + (anchorEnd - anchorStart) / 2 - crossExtent / 2,
      PopoverAlign.end => anchorEnd - crossExtent,
    };
    final limit = (vertical ? size.width : size.height) - margin - crossExtent;
    final clamped = limit < margin ? margin : cross.clamp(margin, limit);

    return vertical ? Offset(clamped, main) : Offset(main, clamped);
  }

  bool _fits(PopoverSide candidate, Size size, Size childSize) =>
      switch (candidate) {
        PopoverSide.top => anchor.top - gap - childSize.height >= margin,
        PopoverSide.bottom =>
          anchor.bottom + gap + childSize.height <= size.height - margin,
        PopoverSide.left => anchor.left - gap - childSize.width >= margin,
        PopoverSide.right =>
          anchor.right + gap + childSize.width <= size.width - margin,
      };

  static PopoverSide _opposite(PopoverSide side) => switch (side) {
    PopoverSide.top => PopoverSide.bottom,
    PopoverSide.bottom => PopoverSide.top,
    PopoverSide.left => PopoverSide.right,
    PopoverSide.right => PopoverSide.left,
  };

  @override
  bool shouldRelayout(_PopoverLayout oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.side != side ||
      oldDelegate.align != align ||
      oldDelegate.gap != gap ||
      oldDelegate.margin != margin;
}
