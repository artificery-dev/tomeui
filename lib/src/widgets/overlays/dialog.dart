import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/overlay_dress.dart';

/// A panel that interrupts: a question to answer, or news that has to be
/// read before anything else happens.
///
/// Three slots, and the middle one is whatever you like:
///
/// ```dart
/// Dialog(
///   title: const Text('Sign the manifest?'),
///   message: const Text('Nothing sails until it is signed.'),
///   actions: [
///     Button(onPressed: cancel, variant: SurfaceVariant.ghost,
///         center: const Text('Not yet')),
///     Button(onPressed: sign, center: const Text('Sign')),
///   ],
/// )
/// ```
///
/// The widget is just the panel — [showDialog] is what puts one over the
/// page, and what most callers want. Built on its own it can sit anywhere,
/// which is how the catalogue shows one without interrupting anything.
class Dialog extends StatelessWidget {
  const Dialog({
    this.title,
    this.message,
    this.content,
    this.actions = const [],
    this.icon,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  });

  /// What's being asked, in a few words.
  final Widget? title;

  /// The longer version, under the title.
  final Widget? message;

  /// Anything else the dialog needs — a field, a list, a picture.
  final Widget? content;

  /// The answers, in reading order: the one to take last on the right,
  /// where the eye finishes.
  final List<Widget> actions;

  /// A glyph above the title, wearing [swatch] — what turns a dialog into
  /// a warning without a word of it being said.
  final IconData? icon;

  /// The meaning [icon] wears.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final DialogStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.dialog.resolve();

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: style.width),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: style.surface.radius,
            boxShadow: style.shadow,
          ),
          child: Surface.custom(
            style: style.surface,
            padding: style.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: theme.sizes.iconLarge,
                    color: theme.widgets.surface
                        .resolve(swatch, SurfaceVariant.solid)
                        .fill,
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
                if (message != null) ...[
                  DefaultTextStyle.merge(
                    style: style.messageStyle,
                    child: message!,
                  ),
                  SizedBox(height: style.gap),
                ],
                if (content != null) ...[
                  Flexible(child: content!),
                  SizedBox(height: style.gap),
                ],
                if (actions.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final (index, action) in actions.indexed) ...[
                        if (index > 0) SizedBox(width: style.actionGap),
                        action,
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The route a [Dialog] arrives on: centred over a scrim, with the page
/// behind it left where it was.
///
/// A route rather than an overlay entry, because that's what buys the
/// things a modal needs and shouldn't reimplement — the keyboard trapped
/// inside it, the focus handed back on the way out, the system's back
/// gesture understood, and a result returned to whoever pushed it.
class DialogRoute<T> extends PopupRoute<T> {
  DialogRoute({
    required this.builder,
    required Theme theme,
    this.barrierDismissible = true,
    DialogStyle? style,
    super.settings,
  }) : _theme = theme,
       _motion = theme.motion,
       _style = style ?? theme.widgets.dialog.resolve();

  final WidgetBuilder builder;

  /// The theme in scope where the dialog was asked for. A route hangs off
  /// the navigator, not off that subtree, so it brings the dressing with
  /// it — see [dressForOverlay].
  final Theme _theme;

  final Motion _motion;
  final DialogStyle _style;

  @override
  final bool barrierDismissible;

  @override
  Color get barrierColor => _style.scrim;

  @override
  String get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => _motion.fast;

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => dressForOverlay(
    theme: _theme,
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (barrierDismissible) Navigator.of(context).maybePop();
        },
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(_style.margin),
          child: Center(
            child: Focus(autofocus: true, child: Builder(builder: builder)),
          ),
        ),
      ),
    ),
  );

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
    // Comes up to meet you rather than dropping in: a short rise, and a
    // scale that starts near enough to full that nothing lurches.
    return FadeTransition(
      opacity: eased,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(eased),
        child: child,
      ),
    );
  }
}

/// Puts a [Dialog] — or anything else — over the page until it's answered.
///
/// The stand-in for Material's function of the same name, and it behaves
/// the way that one taught everyone to expect: the future completes with
/// whatever popped the route, or null if the scrim or Escape did.
///
/// ```dart
/// final signed = await showDialog<bool>(
///   context,
///   builder: (context) => Dialog(
///     title: const Text('Sign the manifest?'),
///     actions: [
///       Button(
///         onPressed: () => Navigator.of(context).pop(false),
///         variant: SurfaceVariant.ghost,
///         center: const Text('Not yet'),
///       ),
///       Button(
///         onPressed: () => Navigator.of(context).pop(true),
///         center: const Text('Sign'),
///       ),
///     ],
///   ),
/// );
/// ```
Future<T?> showDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  DialogStyle? style,
  RouteSettings? settings,
}) => Navigator.of(context, rootNavigator: true).push(
  DialogRoute<T>(
    builder: builder,
    theme: ThemeProvider.maybeOf(context) ?? const Theme(),
    barrierDismissible: barrierDismissible,
    style: style,
    settings: settings,
  ),
);
