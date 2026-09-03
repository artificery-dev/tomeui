import 'dart:async';

import 'package:tomeui/tomeui.dart';

import '../foundation/overlay_dress.dart';

/// A short message that takes itself away.
///
/// The widget is only the card; [Toaster] is what shows one, and
/// [showToast] is the way in:
///
/// ```dart
/// showToast(context, message: const Text('Manifest signed'),
///     swatch: SemanticSwatch.success)
/// ```
///
/// A toast reports something that already happened, so it never asks a
/// question — an [action] undoes or opens, and anything more belongs in a
/// [Dialog].
class Toast extends StatelessWidget {
  const Toast({
    required this.message,
    this.icon,
    this.action,
    this.onDismiss,
    this.swatch = SemanticSwatch.neutral,
    this.style,
    super.key,
  });

  final Widget message;

  /// The glyph at the leading edge. Null takes the one [swatch] implies,
  /// the way a [Callout]'s does — and a neutral toast has none at all.
  final IconData? icon;

  /// One thing to do about it: Undo, View, Retry.
  final Widget? action;

  /// Putting it away early. [Toaster] passes its own.
  final VoidCallback? onDismiss;

  /// What kind of news this is. It colors the glyph, not the card.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final ToastStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.toast.resolve();
    final glyph =
        icon ??
        (swatch == SemanticSwatch.neutral
            ? null
            : Callout.glyphFor(swatch, theme.icons));

    return Semantics(
      container: true,
      liveRegion: true,
      child: SizedBox(
        width: style.width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: style.surface.radius,
            boxShadow: style.shadow,
          ),
          child: Surface.custom(
            style: style.surface,
            padding: style.padding,
            child: Row(
              children: [
                if (glyph != null) ...[
                  Icon(
                    glyph,
                    size: style.iconSize,
                    // The one thing wearing the meaning: a whole card in
                    // red is an emergency, and most toasts aren't.
                    color: theme.widgets.surface
                        .resolve(swatch, SurfaceVariant.solid)
                        .fill,
                  ),
                  SizedBox(width: style.gap),
                ],
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: style.messageStyle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    child: message,
                  ),
                ),
                if (action != null) ...[SizedBox(width: style.gap), action!],
                if (onDismiss != null) ...[
                  SizedBox(width: style.gap),
                  Semantics(
                    label: theme.labels.dismiss,
                    child: Button(
                      onPressed: onDismiss,
                      variant: SurfaceVariant.ghost,
                      swatch: SemanticSwatch.neutral,
                      center: Icon(theme.icons.close, size: style.iconSize),
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

/// One toast the [Toaster] is holding: what to show, and for how long.
class ToastEntry {
  ToastEntry({
    required this.message,
    this.icon,
    this.action,
    this.swatch = SemanticSwatch.neutral,
    this.duration,
    this.dismissible = true,
  });

  final Widget message;
  final IconData? icon;

  /// One thing to do about it. Building it is handed the way to put the
  /// toast away, since an action almost always wants to.
  final Widget Function(BuildContext context, VoidCallback dismiss)? action;

  final SemanticSwatch swatch;

  /// How long it stays. Null takes [ToastStyle.life] — doubled when the
  /// toast has an action, since an action nobody had time to press is an
  /// action that wasn't offered.
  final Duration? duration;

  /// Whether it grows a close button of its own.
  final bool dismissible;
}

/// Shows toasts, and takes them away again.
///
/// One of these lives high in the app, above whatever might want to speak:
///
/// ```dart
/// TomeApp(builder: (context, child) => Toaster(child: child!), home: ...)
/// ```
///
/// It holds the queue: [ToastStyle.maxVisible] show at once, the rest wait
/// their turn, each takes itself away when its time is up, and pointing at
/// one keeps it — a message that vanished while it was being read may as
/// well not have been shown.
class Toaster extends StatefulWidget {
  const Toaster({required this.child, this.style, super.key});

  final Widget child;

  /// The style its toasts wear, and the geometry it stacks them by.
  final ToastStyle? style;

  /// The nearest toaster, for anything that has something to say.
  static ToasterState of(BuildContext context) {
    final state = context.findAncestorStateOfType<ToasterState>();
    assert(state != null, 'No Toaster above this widget.');
    return state!;
  }

  static ToasterState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<ToasterState>();

  @override
  State<Toaster> createState() => ToasterState();
}

/// A [Toaster]'s queue, and the handle for adding to it.
class ToasterState extends State<Toaster> {
  final List<_Held> _held = [];

  @override
  void dispose() {
    for (final held in _held) {
      held.timer?.cancel();
    }
    super.dispose();
  }

  ToastStyle _style(BuildContext context) =>
      widget.style ??
      (ThemeProvider.maybeOf(context) ?? const Theme()).widgets.toast.resolve();

  /// Says something. Returns the way to take it back early.
  VoidCallback show(ToastEntry entry) {
    final held = _Held(entry);
    setState(() => _held.add(held));
    _wind();
    return () => dismiss(held);
  }

  void dismiss(Object handle) {
    final held = handle is _Held ? handle : null;
    if (held == null || !_held.contains(held)) return;
    held.timer?.cancel();
    setState(() => _held.remove(held));
    _wind();
  }

  /// Every toast that's showing gets a running clock; the ones still
  /// queued don't, since their time hasn't started.
  void _wind() {
    final style = _style(context);
    for (final held in _held.take(style.maxVisible)) {
      if (held.timer != null || held.held) continue;
      held.timer = Timer(
        held.entry.duration ??
            (held.entry.action == null ? style.life : style.life * 2),
        () => dismiss(held),
      );
    }
  }

  /// The pointer resting on a toast stops its clock; leaving starts a fresh
  /// one, so a message being read stays put.
  void _hold(_Held held, {required bool holding}) {
    held.held = holding;
    if (holding) {
      held.timer?.cancel();
      held.timer = null;
    } else {
      _wind();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = _style(context);
    final showing = _held.take(style.maxVisible).toList();
    final top = style.position.isTop;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Padding(
            padding: style.margin,
            child: Align(
              alignment: switch (style.position) {
                ToastPosition.topLeading => AlignmentDirectional.topStart,
                ToastPosition.topCenter => AlignmentDirectional.topCenter,
                ToastPosition.topTrailing => AlignmentDirectional.topEnd,
                ToastPosition.bottomLeading => AlignmentDirectional.bottomStart,
                ToastPosition.bottomCenter => AlignmentDirectional.bottomCenter,
                ToastPosition.bottomTrailing => AlignmentDirectional.bottomEnd,
              },
              // The stack takes no more room than its toasts, so the page
              // underneath stays clickable everywhere else.
              child: IgnorePointer(
                ignoring: showing.isEmpty,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  // Newest nearest the edge it came from.
                  verticalDirection: top
                      ? VerticalDirection.down
                      : VerticalDirection.up,
                  children: [
                    for (final held in showing)
                      Padding(
                        key: ObjectKey(held),
                        padding: EdgeInsets.only(bottom: style.stackGap),
                        child: MouseRegion(
                          onEnter: (_) => _hold(held, holding: true),
                          onExit: (_) => _hold(held, holding: false),
                          child: _Arriving(
                            fromTop: top,
                            motion: theme.motion,
                            child: dressForOverlay(
                              theme: theme,
                              child: Toast(
                                message: held.entry.message,
                                icon: held.entry.icon,
                                swatch: held.entry.swatch,
                                style: style,
                                action: held.entry.action?.call(
                                  context,
                                  () => dismiss(held),
                                ),
                                onDismiss: held.entry.dismissible
                                    ? () => dismiss(held)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One toast the toaster is holding, and the clock running on it.
class _Held {
  _Held(this.entry);

  final ToastEntry entry;
  Timer? timer;

  /// Whether the pointer is resting on it.
  bool held = false;
}

/// Slides in from the edge it belongs to, and fades as it comes.
class _Arriving extends StatefulWidget {
  const _Arriving({
    required this.fromTop,
    required this.motion,
    required this.child,
  });

  final bool fromTop;
  final Motion motion;
  final Widget child;

  @override
  State<_Arriving> createState() => _ArrivingState();
}

class _ArrivingState extends State<_Arriving>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: widget.motion.standard,
  )..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eased = CurvedAnimation(parent: _in, curve: widget.motion.enter);
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween(
          begin: Offset(0, widget.fromTop ? -0.5 : 0.5),
          end: Offset.zero,
        ).animate(eased),
        child: widget.child,
      ),
    );
  }
}

/// Says something through the nearest [Toaster].
///
/// Returns the way to take it back early — for a toast reporting work that
/// finishes before anyone reads about it.
VoidCallback showToast(
  BuildContext context, {
  required Widget message,
  IconData? icon,
  Widget Function(BuildContext context, VoidCallback dismiss)? action,
  SemanticSwatch swatch = SemanticSwatch.neutral,
  Duration? duration,
  bool dismissible = true,
}) => Toaster.of(context).show(
  ToastEntry(
    message: message,
    icon: icon,
    action: action,
    swatch: swatch,
    duration: duration,
    dismissible: dismissible,
  ),
);
