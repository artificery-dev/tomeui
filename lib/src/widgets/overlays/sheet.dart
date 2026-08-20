import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/overlay_dress.dart';

/// A panel that comes in from an edge.
///
/// The bottom sheet a phone uses where a desktop would drop a menu, and the
/// side sheet a desktop uses where it hasn't the room to dock a sidebar —
/// one widget, told which edge by [side].
///
/// ```dart
/// showSheet<void>(
///   context,
///   builder: (context) => Sheet(
///     title: const Text('Sort by'),
///     child: RadioGroup(...),
///   ),
/// )
/// ```
///
/// A bottom sheet wears a grabber and can be thrown back down; a side sheet
/// doesn't, since there's nothing to throw it at. As with [Dialog], the
/// widget is only the panel — [showSheet] is what puts one on screen.
class Sheet extends StatelessWidget {
  const Sheet({
    this.title,
    this.child,
    this.side = SheetSide.bottom,
    this.style,
    super.key,
  });

  /// What the sheet is for, across its top.
  final Widget? title;

  final Widget? child;

  /// Which edge it belongs to. [showSheet] passes its own, so this matters
  /// only when the panel is placed by hand.
  final SheetSide side;

  /// The style to paint, bypassing the theme.
  final SheetStyle? style;

  /// The corners on the edges the sheet *isn't* against.
  static BorderRadius cornersFor(SheetSide side, Radius radius) =>
      switch (side) {
        SheetSide.bottom => BorderRadius.only(
          topLeft: radius,
          topRight: radius,
        ),
        SheetSide.leading => BorderRadius.horizontal(right: radius),
        SheetSide.trailing => BorderRadius.horizontal(left: radius),
      };

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.sheet.resolve();
    final corners = cornersFor(side, style.radius);

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: corners,
          boxShadow: style.shadow,
        ),
        child: Surface.custom(
          style: style.surface.copyWith(radius: corners),
          child: SafeArea(
            top: side != SheetSide.bottom,
            child: Padding(
              padding: style.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (side == SheetSide.bottom) ...[
                    Center(
                      child: SizedBox(
                        width: style.grabberSize.width,
                        height: style.grabberSize.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: style.grabber,
                            borderRadius: BorderRadius.circular(
                              style.grabberSize.height,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: style.gap),
                  ],
                  if (title != null) ...[
                    Semantics(
                      header: true,
                      child: DefaultTextStyle.merge(
                        style: style.titleStyle,
                        child: title!,
                      ),
                    ),
                    SizedBox(height: style.gap),
                  ],
                  if (child != null) Flexible(child: child!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The route a [Sheet] arrives on: pinned to its edge, over a scrim.
///
/// A route for the same reasons a [DialogRoute] is one — the keyboard
/// trapped inside, the focus handed back, the back gesture understood, a
/// result returned. A bottom sheet adds the drag: pull it down far enough,
/// or fast enough, and it goes.
class SheetRoute<T> extends PopupRoute<T> {
  SheetRoute({
    required this.builder,
    required Theme theme,
    this.side = SheetSide.bottom,
    this.barrierDismissible = true,
    this.draggable = true,
    SheetStyle? style,
    super.settings,
  }) : _theme = theme,
       _motion = theme.motion,
       _style = style ?? theme.widgets.sheet.resolve();

  final WidgetBuilder builder;

  /// Which edge the sheet comes in from.
  final SheetSide side;

  /// Whether a bottom sheet can be thrown back down. A side sheet ignores
  /// this — there's nothing to throw it at.
  final bool draggable;

  /// The theme in scope where the sheet was asked for. A route hangs off
  /// the navigator, not off that subtree, so it brings the dressing with
  /// it — see [dressForOverlay].
  final Theme _theme;

  final Motion _motion;
  final SheetStyle _style;

  @override
  final bool barrierDismissible;

  @override
  Color get barrierColor => _style.scrim;

  @override
  String get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => _motion.standard;

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final panel = Builder(builder: builder);

    return dressForOverlay(
      theme: _theme,
      child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (barrierDismissible) Navigator.of(context).maybePop();
        },
      },
        child: Align(
          alignment: switch (side) {
            SheetSide.bottom => Alignment.bottomCenter,
            SheetSide.leading => AlignmentDirectional.centerStart.resolve(
              Directionality.of(context),
            ),
            SheetSide.trailing => AlignmentDirectional.centerEnd.resolve(
              Directionality.of(context),
            ),
          },
          child: LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: side == SheetSide.bottom
                  ? BoxConstraints(
                      maxHeight: constraints.maxHeight * _style.maxFraction,
                    )
                  : BoxConstraints(
                      maxWidth: _style.size,
                      minHeight: constraints.maxHeight,
                    ),
              child: Focus(
                autofocus: true,
                child: side == SheetSide.bottom && draggable
                    ? _Draggable(
                        onDismiss: () => Navigator.of(context).maybePop(),
                        child: panel,
                      )
                    : panel,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: _motion.enter,
      reverseCurve: _motion.exit,
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final from = switch (side) {
      SheetSide.bottom => const Offset(0, 1),
      SheetSide.leading => Offset(rtl ? 1 : -1, 0),
      SheetSide.trailing => Offset(rtl ? -1 : 1, 0),
    };
    return SlideTransition(
      position: Tween(begin: from, end: Offset.zero).animate(eased),
      child: child,
    );
  }
}

/// Follows a downward drag, and lets go when the sheet has been pulled far
/// enough — or flung hard enough — to mean it.
class _Draggable extends StatefulWidget {
  const _Draggable({required this.onDismiss, required this.child});

  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_Draggable> createState() => _DraggableState();
}

class _DraggableState extends State<_Draggable> {
  double _offset = 0;

  /// How far down is far enough, as a share of the sheet's own height, and
  /// how fast is fast enough whatever the distance.
  static const _far = 0.4;
  static const _fast = 700.0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onVerticalDragUpdate: (details) => setState(
      // Down only: dragging a sheet upward is how it would grow, which is
      // a size it doesn't have.
      () => _offset = (_offset + details.delta.dy).clamp(0, double.infinity),
    ),
    onVerticalDragEnd: (details) {
      final height = context.size?.height ?? 0;
      final thrown = details.velocity.pixelsPerSecond.dy > _fast;
      if (thrown || (height > 0 && _offset / height > _far)) {
        widget.onDismiss();
      } else {
        setState(() => _offset = 0);
      }
    },
    child: Transform.translate(
      offset: Offset(0, _offset),
      child: widget.child,
    ),
  );
}

/// Brings a [Sheet] in from an edge until it's dismissed.
///
/// The future completes with whatever popped the route, or null if the
/// scrim, Escape, or a downward throw did.
Future<T?> showSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  SheetSide side = SheetSide.bottom,
  bool barrierDismissible = true,
  bool draggable = true,
  SheetStyle? style,
  RouteSettings? settings,
}) => Navigator.of(context, rootNavigator: true).push(
  SheetRoute<T>(
    builder: builder,
    theme: ThemeProvider.maybeOf(context) ?? const Theme(),
    side: side,
    barrierDismissible: barrierDismissible,
    draggable: draggable,
    style: style,
    settings: settings,
  ),
);
