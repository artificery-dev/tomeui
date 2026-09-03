import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/focus_ring.dart';

/// One choice a [SegmentedControl] offers.
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.leading,
    this.enabled = true,
  });

  /// What choosing this segment means.
  final T value;

  final Widget label;

  /// An icon ahead of the label.
  final Widget? leading;

  final bool enabled;
}

/// One of a few, all of them on screen at once.
///
/// A radio group with its options laid side by side in a single trough,
/// and an indicator that slides to the answer — which is the switch's
/// track-and-thumb idea widened until the thumb has words on it. Reach for
/// it over a [Select] when the choices are few and worth reading at a
/// glance, and over a [RadioGroup] when they're alternatives to one
/// setting rather than a list to work down.
///
/// ```dart
/// SegmentedControl<Watch>(
///   value: watch,
///   onChanged: (value) => setState(() => watch = value),
///   segments: [
///     for (final w in Watch.values)
///       SegmentOption(value: w, label: Text(w.name)),
///   ],
/// )
/// ```
///
/// The segments are equal width — the widest one sets it — so the
/// indicator has one distance to travel and the control doesn't reflow as
/// the answer changes. A null [value] is nothing chosen, and the indicator
/// stays away until there's something to point at.
///
/// The whole control is one focus stop, the way a radio group is: the
/// arrows move the answer, Home and End take the ends, and disabled
/// segments are stepped over rather than landed on.
class SegmentedControl<T> extends StatefulWidget {
  const SegmentedControl({
    required this.value,
    required this.onChanged,
    required this.segments,
    this.variant = SurfaceVariant.solid,
    this.swatch = SemanticSwatch.primary,
    this.style,
    this.stretch = false,
    super.key,
  }) : assert(segments.length > 0, 'A segmented control needs segments.');

  /// The current answer, or null when there isn't one.
  final T? value;

  /// Called with a segment's value when it's chosen. Null disables the
  /// whole control.
  final ValueChanged<T>? onChanged;

  final List<SegmentOption<T>> segments;

  final SurfaceVariant variant;

  /// The meaning the indicator wears.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final SegmentedControlStyle? style;

  /// Whether the track fills the width it is given rather than hugging its
  /// segments.
  ///
  /// Hugging is right on a page, where a control that spanned the column
  /// would read as a toolbar. It is wrong in a row that *is* the control -
  /// a settings tile, where the track is the row's own line - and there
  /// the segments should divide the whole width between them.
  final bool stretch;

  @override
  State<SegmentedControl<T>> createState() => _SegmentedControlState<T>();
}

class _SegmentedControlState<T> extends State<SegmentedControl<T>> {
  int? _hovered;
  int? _pressed;
  bool _focused = false;

  /// Where the indicator last had something to point at, so it fades out
  /// in place rather than travelling to nowhere.
  double _parked = 0;

  bool get _enabled => widget.onChanged != null;

  int get _selected =>
      widget.segments.indexWhere((segment) => segment.value == widget.value);

  bool _canLandOn(int index) =>
      index >= 0 &&
      index < widget.segments.length &&
      widget.segments[index].enabled;

  /// Leaving only clears the hover if this segment is still the one
  /// holding it — the pointer reaches the next segment before it leaves
  /// the last, and the stale exit would undo the fresh enter.
  void _leave(int index) {
    if (_hovered == index) setState(() => _hovered = null);
  }

  void _choose(int index) {
    if (!_enabled || !_canLandOn(index)) return;
    final segment = widget.segments[index];
    if (segment.value != widget.value) widget.onChanged!(segment.value);
  }

  /// Moves the answer [by] segments, stepping over disabled ones and
  /// stopping at the ends rather than wrapping — a segmented control is a
  /// short row you can see all of, so falling off it would only surprise.
  void _step(int by) {
    if (!_enabled) return;
    final count = widget.segments.length;
    // Nothing chosen yet: the first press lands on the near end.
    var index = _selected < 0 ? (by > 0 ? -1 : count) : _selected;
    for (index += by; index >= 0 && index < count; index += by) {
      if (widget.segments[index].enabled) {
        _choose(index);
        return;
      }
    }
  }

  /// Home and End, which mean the first and last segment anyone can land
  /// on rather than the first and last segment.
  void _toEnd({required bool last}) {
    if (!_enabled) return;
    final index = last
        ? widget.segments.lastIndexWhere((segment) => segment.enabled)
        : widget.segments.indexWhere((segment) => segment.enabled);
    if (index >= 0) _choose(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style =
        widget.style ??
        theme.widgets.segmented.resolve(widget.swatch, widget.variant);
    final count = widget.segments.length;
    final selected = _selected;

    return Semantics(
      container: true,
      enabled: _enabled,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(-1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(1),
          const SingleActivator(LogicalKeyboardKey.home): () =>
              _toEnd(last: false),
          const SingleActivator(LogicalKeyboardKey.end): () =>
              _toEnd(last: true),
        },
        child: FocusableActionDetector(
          enabled: _enabled,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          child: AnimatedOpacity(
            opacity: _enabled ? 1 : style.disabledOpacity,
            duration: theme.motion.fast,
            curve: theme.motion.move,
            child: FocusRing(
              visible: _focused && _enabled,
              color: style.ring,
              radius: style.track.radius,
              // A control keeps its own size in a slot that would stretch
              // it vertically; the width it takes, it fills.
              child: Center(
                heightFactor: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) => SizedBox(
                    height: style.height,
                    // Stretched, the track takes the width it was given -
                    // and only where there is one to take: in an unbounded
                    // row it still has to size itself.
                    width: widget.stretch && constraints.hasBoundedWidth
                        ? constraints.maxWidth
                        : null,
                    child: Surface.custom(
                      style: style.track,
                      padding: EdgeInsets.all(style.inset),
                      // Every segment flexes, so the row's intrinsic width
                      // is the widest segment times the count — which is
                      // what makes them equal without anything being
                      // measured.
                      child: IntrinsicWidth(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _indicator(theme, style, count, selected),
                            ),
                            Row(
                              children: [
                                for (var i = 0; i < count; i++)
                                  Expanded(
                                    child: _segment(theme, style, i, selected),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The dress that slides to the answer.
  ///
  /// A [FractionallySizedBox] one segment wide, aligned along the track:
  /// alignment -1 is flush left and +1 flush right, so segment *i* of *n*
  /// sits at `-1 + 2i/(n-1)` and the arithmetic falls out of the geometry
  /// rather than out of a measurement.
  Widget _indicator(
    Theme theme,
    SegmentedControlStyle style,
    int count,
    int selected,
  ) {
    final showing = selected >= 0;
    // Held where it was while it fades out, so a control that loses its
    // answer doesn't slide back to the start on the way out.
    if (showing) _parked = selected.toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(end: showing ? selected.toDouble() : _parked),
      duration: theme.motion.fast,
      curve: theme.motion.move,
      builder: (context, position, child) => TweenAnimationBuilder<double>(
        tween: Tween(end: showing ? 1.0 : 0.0),
        duration: theme.motion.fast,
        curve: showing ? theme.motion.enter : theme.motion.exit,
        builder: (context, presence, _) => presence == 0
            ? const SizedBox.shrink()
            : Opacity(
                opacity: presence,
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  alignment: Alignment(
                    count == 1 ? 0 : -1 + 2 * position / (count - 1),
                    0,
                  ),
                  child: child,
                ),
              ),
      ),
      child: Surface.custom(style: style.indicator),
    );
  }

  Widget _segment(
    Theme theme,
    SegmentedControlStyle style,
    int index,
    int selected,
  ) {
    final segment = widget.segments[index];
    final live = _enabled && segment.enabled;
    final chosen = index == selected;
    final wash = !live || chosen
        ? null
        : _pressed == index
        ? style.pressed
        : _hovered == index
        ? style.hover
        : null;

    final content = AnimatedDefaultTextStyle(
      style: chosen ? style.selectedStyle : style.unselectedStyle,
      duration: theme.motion.fast,
      curve: theme.motion.move,
      child: IconTheme.merge(
        data: IconThemeData(
          color: (chosen ? style.selectedStyle : style.unselectedStyle).color,
          size: style.iconSize,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (segment.leading != null) ...[
              segment.leading!,
              SizedBox(width: style.gap),
            ],
            Flexible(child: segment.label),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: chosen,
      enabled: live,
      child: MouseRegion(
        cursor: live ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: live ? (_) => setState(() => _hovered = index) : null,
        onExit: live ? (_) => _leave(index) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: live ? (_) => setState(() => _pressed = index) : null,
          onTapUp: live ? (_) => setState(() => _pressed = null) : null,
          onTapCancel: live ? () => setState(() => _pressed = null) : null,
          onTap: live ? () => _choose(index) : null,
          child: Opacity(
            // A disabled segment dims on its own; the whole control dims
            // together when nobody can use it.
            opacity: segment.enabled ? 1 : style.disabledOpacity,
            child: Surface.custom(
              style: SurfaceStyle(
                foreground: style.track.foreground,
                fill: wash,
                radius: style.indicator.radius,
              ),
              padding: style.segmentPadding,
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
