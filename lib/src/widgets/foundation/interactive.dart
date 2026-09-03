import 'package:tomeui/tomeui.dart';

import 'focus_ring.dart';

/// The interaction core every control shares: hover, press, and focus
/// tracking; pointer and keyboard activation; and the animated dressing
/// those states wear — the wash, the lift, the outset focus ring, the
/// disabled dim.
///
/// The control brings the paint: [builder] receives the current
/// [Interaction] — the animated wash, plus whether the control is hovered,
/// pressed, focused, or disabled — and draws itself accordingly. Most
/// controls need only the wash; a link needs the flags, because an
/// underline can't fade in as a tint. Toolkit-internal: imported by the
/// controls, not exported by the barrel.
class Interactive extends StatefulWidget {
  const Interactive({
    required this.onActivate,
    required this.builder,
    required this.ring,
    required this.ringRadius,
    this.hover,
    this.pressed,
    this.lift = 0,
    this.disabledOpacity = 0.38,
    this.label,
    this.labelGap = 8,
    super.key,
  });

  /// What activation — tap, Enter, Space — does. Null disables the control:
  /// it dims, ignores the pointer, and leaves the focus order.
  final VoidCallback? onActivate;

  /// Draws the control in the state it's currently in — the animated wash
  /// plus the raw flags, for controls whose dressing is more than a tint.
  final Widget Function(BuildContext context, Interaction state) builder;

  /// The focus ring's color, and the corners it runs concentric to.
  final Color ring;
  final BorderRadius ringRadius;

  /// The interaction washes. Both null skips the wash machinery entirely.
  final Color? hover;
  final Color? pressed;

  /// Hover scales to `1 + lift`, pressing sinks to `1 - lift`.
  final double lift;

  final double disabledOpacity;

  /// Words beside the control, and part of it: the whole row hovers,
  /// focuses, and activates as one. The label itself stays still and
  /// unringed — it's the control that lifts and wears the focus ring —
  /// and keeps the ambient text style, since a label is page text.
  final Widget? label;

  /// The space between the control and its [label].
  final double labelGap;

  @override
  State<Interactive> createState() => _InteractiveState();
}

/// What a control is being subjected to, the instant it draws.
///
/// [wash] is animated — it glides between rest, hover, and pressed — while
/// the flags snap, so a control tints smoothly and swaps a glyph or an
/// underline the moment the state changes.
@immutable
class Interaction {
  const Interaction({
    required this.wash,
    required this.hovered,
    required this.pressed,
    required this.focused,
    required this.enabled,
  });

  /// The foreground-tinted overlay to lay over the fill: null when the
  /// control asked for no washes, transparent at rest when it did.
  final Color? wash;

  /// All false while disabled — a control that can't be used isn't being.
  final bool hovered;
  final bool pressed;
  final bool focused;

  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is Interaction &&
      other.wash == wash &&
      other.hovered == hovered &&
      other.pressed == pressed &&
      other.focused == focused &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(wash, hovered, pressed, focused, enabled);
}

class _InteractiveState extends State<Interactive> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final enabled = widget.onActivate != null;

    Interaction stateWith(Color? wash) => Interaction(
      wash: wash,
      hovered: _hovered && enabled,
      pressed: _pressed && enabled,
      focused: _focused && enabled,
      enabled: enabled,
    );

    Widget box;
    final restWash = (widget.hover ?? widget.pressed)?.withValues(alpha: 0);
    if (restWash == null) {
      box = widget.builder(context, stateWith(null));
    } else {
      // The wash fades rather than snaps, and the tween retargets
      // mid-flight, so hover → pressed → rest glide through each other.
      final wash = !enabled
          ? restWash
          : _pressed
          ? widget.pressed ?? restWash
          : _hovered
          ? widget.hover ?? restWash
          : restWash;
      box = TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: wash),
        duration: theme.motion.instant,
        curve: theme.motion.move,
        builder: (context, value, _) =>
            widget.builder(context, stateWith(value)),
      );
    }

    // The ring stands outside the edge, painted rather than laid out, so
    // focus never shifts anything.
    box = FocusRing(
      visible: _focused && enabled,
      color: widget.ring,
      radius: widget.ringRadius,
      child: box,
    );

    // The lift: rise slightly to meet the pointer, sink below rest while
    // pressed — the wash says "touched", the scale says "moved".
    box = AnimatedScale(
      scale: !enabled
          ? 1
          : _pressed
          ? 1 - widget.lift
          : _hovered
          ? 1 + widget.lift
          : 1,
      duration: theme.motion.instant,
      curve: theme.motion.move,
      child: box,
    );

    // The label joins the row inside the detector but outside the lift and
    // the ring: clicking the words works, without the words moving.
    if (widget.label != null) {
      box = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          box,
          SizedBox(width: widget.labelGap),
          Flexible(child: widget.label!),
        ],
      );
    }

    box = FocusableActionDetector(
      enabled: enabled,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onActivate?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        // The whole row answers, gaps and transparent fills included.
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onActivate,
        child: box,
      ),
    );

    // Disabling dims gently in both directions.
    return AnimatedOpacity(
      opacity: enabled ? 1 : widget.disabledOpacity,
      duration: theme.motion.fast,
      curve: theme.motion.move,
      child: box,
    );
  }
}
