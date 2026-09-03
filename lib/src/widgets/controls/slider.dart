import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/focus_ring.dart';

/// A value picked off a line: a thumb dragged along a track.
///
/// Controlled, like every other Tome control — [value] is where the thumb
/// is, [onChanged] reports where it's been asked to go, and the caller
/// decides:
///
/// ```dart
/// Slider(
///   value: volume,
///   onChanged: (value) => setState(() => volume = value),
/// )
/// ```
///
/// [divisions] turns the line into stops: the thumb snaps to them, the
/// arrow keys step one at a time, and the track shows where they are.
/// Without it the value is continuous and the arrows move a hundredth of
/// the range.
///
/// The track fills the length it's given — a slider is a measurement, and
/// how long it is says how finely it can be read. In a slot that doesn't
/// say, it takes [SliderStyle.minWidth].
///
/// [Axis.vertical] stands the line up: the thumb travels bottom to top,
/// and more is up, the way a fader or a volume rocker reads.
class Slider extends StatefulWidget {
  const Slider({
    required this.value,
    required this.onChanged,
    this.axis = Axis.horizontal,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticFormatter,
    this.variant = SurfaceVariant.solid,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  }) : assert(min < max, 'A slider needs a range: min must be below max.'),
       assert(
         divisions == null || divisions > 0,
         'A divided slider needs at least one division.',
       );

  /// Where the thumb is. Clamped to [min]..[max] on the way in, so a value
  /// off the end draws at the end rather than off the track.
  final double value;

  /// Called as the thumb moves — on every frame of a drag, not only when
  /// it's let go. Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Which way the line runs. Vertical reads bottom-to-top.
  final Axis axis;

  final double min;
  final double max;

  /// How many stops the track has. Null is a continuous line.
  final int? divisions;

  /// The beginning and end of a drag, for callers that want to commit once
  /// rather than on every frame — a save, a network write.
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  /// What assistive tech reads the value as. Null says the number.
  final String Function(double value)? semanticFormatter;

  final SurfaceVariant variant;

  /// The meaning the travelled part of the track wears.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final SliderStyle? style;

  @override
  State<Slider> createState() => _SliderState();
}

class _SliderState extends State<Slider> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;

  double get _range => widget.max - widget.min;

  /// Where the thumb sits, 0 at [Slider.min] and 1 at [Slider.max].
  double get _fraction =>
      ((widget.value - widget.min) / _range).clamp(0.0, 1.0);

  /// One arrow press: a division if the track has them, a hundredth of the
  /// range if it doesn't — fine enough to tune with, coarse enough to
  /// cross the track without holding the key down all day.
  double get _step =>
      widget.divisions == null ? _range / 100 : _range / widget.divisions!;

  /// The nearest legal value: any real number on a continuous slider, the
  /// nearest stop on a divided one.
  double _snap(double value) {
    final clamped = value.clamp(widget.min, widget.max);
    final divisions = widget.divisions;
    if (divisions == null) return clamped;
    final step = _range / divisions;
    return (widget.min + ((clamped - widget.min) / step).round() * step).clamp(
      widget.min,
      widget.max,
    );
  }

  void _report(double value) {
    final snapped = _snap(value);
    if (snapped != widget.value) widget.onChanged!(snapped);
  }

  void _nudge(double by) {
    if (_enabled) _report(widget.value + by);
  }

  /// How a value reads aloud. Divided sliders count in whole stops, so
  /// they say whole numbers.
  String _say(double value) =>
      widget.semanticFormatter?.call(value) ??
      value.toStringAsFixed(widget.divisions == null ? 2 : 0);

  bool get _vertical => widget.axis == Axis.vertical;

  /// The value under a point, measured along the track's own axis.
  ///
  /// The thumb's *center* travels a shorter distance than the track is
  /// long — half a thumb is parked at each end — so the mapping runs
  /// between those centers, not between the edges. Vertical counts from
  /// the bottom: more is up.
  double _valueAt(double position, double extent, SliderStyle style) {
    final travel = extent - style.thumbSize;
    if (travel <= 0) return widget.min;
    final along = _vertical ? extent - position : position;
    final fraction = ((along - style.thumbSize / 2) / travel).clamp(0.0, 1.0);
    return widget.min + fraction * _range;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style =
        widget.style ??
        theme.widgets.slider.resolve(widget.swatch, widget.variant);

    return Semantics(
      slider: true,
      enabled: _enabled,
      value: _say(widget.value),
      // A node offering to increase has to say what it would become —
      // otherwise the reader announces an action with no outcome.
      increasedValue: _say(_snap(widget.value + _step)),
      decreasedValue: _say(_snap(widget.value - _step)),
      onIncrease: _enabled ? () => _nudge(_step) : null,
      onDecrease: _enabled ? () => _nudge(-_step) : null,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _nudge(-_step),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _nudge(-_step),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _nudge(_step),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _nudge(_step),
          const SingleActivator(LogicalKeyboardKey.home): () =>
              _enabled ? _report(widget.min) : null,
          const SingleActivator(LogicalKeyboardKey.end): () =>
              _enabled ? _report(widget.max) : null,
        },
        child: FocusableActionDetector(
          enabled: _enabled,
          mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          child: AnimatedOpacity(
            opacity: _enabled ? 1 : style.disabledOpacity,
            duration: theme.motion.fast,
            curve: theme.motion.move,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // A slider in an unbounded slot still has to be some
                // length; the style says how long.
                final limit = _vertical
                    ? constraints.maxHeight
                    : constraints.maxWidth;
                final extent = limit.isFinite ? limit : style.minWidth;
                double along(Offset position) =>
                    _vertical ? position.dy : position.dx;
                void dragStart(DragStartDetails details) {
                  setState(() => _pressed = true);
                  widget.onChangeStart?.call(widget.value);
                  _report(
                    _valueAt(along(details.localPosition), extent, style),
                  );
                }

                void dragUpdate(DragUpdateDetails details) => _report(
                  _valueAt(along(details.localPosition), extent, style),
                );
                void dragEnd(DragEndDetails details) {
                  setState(() => _pressed = false);
                  widget.onChangeEnd?.call(widget.value);
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _enabled
                      ? (details) {
                          setState(() => _pressed = true);
                          // A tap anywhere on the band takes the thumb
                          // there — a slider you can only drag is a slider
                          // you have to aim at.
                          _report(
                            _valueAt(
                              along(details.localPosition),
                              extent,
                              style,
                            ),
                          );
                        }
                      : null,
                  onTapUp: _enabled
                      ? (_) => setState(() => _pressed = false)
                      : null,
                  onTapCancel: _enabled
                      ? () => setState(() => _pressed = false)
                      : null,
                  onHorizontalDragStart: _enabled && !_vertical
                      ? dragStart
                      : null,
                  onHorizontalDragUpdate: _enabled && !_vertical
                      ? dragUpdate
                      : null,
                  onHorizontalDragEnd: _enabled && !_vertical ? dragEnd : null,
                  onVerticalDragStart: _enabled && _vertical ? dragStart : null,
                  onVerticalDragUpdate: _enabled && _vertical
                      ? dragUpdate
                      : null,
                  onVerticalDragEnd: _enabled && _vertical ? dragEnd : null,
                  child: SizedBox(
                    width: _vertical
                        ? style.height
                        : (constraints.maxWidth.isFinite ? null : extent),
                    height: _vertical
                        ? (constraints.maxHeight.isFinite ? null : extent)
                        : style.height,
                    child: _track(theme, style, extent),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _track(Theme theme, SliderStyle style, double extent) {
    final travel = extent - style.thumbSize;
    final divisions = widget.divisions;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: _fraction),
      // Dragging is already continuous; the glide is for the arrow keys
      // and for a value the caller moved on its own.
      duration: _pressed ? Duration.zero : theme.motion.instant,
      curve: theme.motion.move,
      builder: (context, fraction, _) {
        final center = style.thumbSize / 2 + fraction * travel;
        return Stack(
          // The travelled part grows from the start of the line: the left
          // end, or the bottom when the line stands up.
          alignment: _vertical ? Alignment.bottomCenter : Alignment.centerLeft,
          children: [
            // The whole track, then the travelled part over it: two boxes
            // rather than a row, so the join can't show a seam.
            SizedBox(
              width: _vertical ? style.trackHeight : null,
              height: _vertical ? null : style.trackHeight,
              child: Surface.custom(style: style.inactive),
            ),
            SizedBox(
              width: _vertical ? style.trackHeight : center,
              height: _vertical ? center : style.trackHeight,
              child: Surface.custom(style: style.active),
            ),
            if (divisions != null && style.tick != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _TickPainter(
                    axis: widget.axis,
                    divisions: divisions,
                    inset: style.thumbSize / 2,
                    size: style.tickSize,
                    color: style.tick!,
                  ),
                ),
              ),
            Positioned(
              left: _vertical ? null : center - style.thumbSize / 2,
              bottom: _vertical ? center - style.thumbSize / 2 : null,
              child: _thumb(theme, style),
            ),
          ],
        );
      },
    );
  }

  Widget _thumb(Theme theme, SliderStyle style) {
    final wash = _pressed
        ? style.pressed
        : _hovered
        ? style.hover
        : null;
    return AnimatedScale(
      scale: !_enabled
          ? 1
          : _pressed
          ? 1 - style.lift
          : _hovered
          ? 1 + style.lift
          : 1,
      duration: theme.motion.instant,
      curve: theme.motion.move,
      child: FocusRing(
        visible: _focused && _enabled,
        color: style.ring,
        radius: style.thumb.radius,
        child: SizedBox.square(
          dimension: style.thumbSize,
          child: Surface.custom(
            style: SurfaceStyle(
              foreground: style.thumb.foreground,
              fill: wash == null
                  ? style.thumb.fill
                  : style.thumb.fill == null
                  ? wash
                  : Color.alphaBlend(wash, style.thumb.fill!),
              border: style.thumb.border,
              radius: style.thumb.radius,
            ),
          ),
        ),
      ),
    );
  }
}

/// The stops a divided track shows, drawn between the thumb's two extremes
/// so a mark always sits under the thumb that can reach it.
class _TickPainter extends CustomPainter {
  const _TickPainter({
    required this.axis,
    required this.divisions,
    required this.inset,
    required this.size,
    required this.color,
  });

  final Axis axis;
  final int divisions;
  final double inset;
  final double size;
  final Color color;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final vertical = axis == Axis.vertical;
    final length = vertical ? canvasSize.height : canvasSize.width;
    final travel = length - inset * 2;
    if (travel <= 0) return;
    final paint = Paint()..color = color;
    for (var i = 0; i <= divisions; i++) {
      final at = inset + travel * i / divisions;
      canvas.drawCircle(
        vertical
            ? Offset(canvasSize.width / 2, canvasSize.height - at)
            : Offset(at, canvasSize.height / 2),
        size / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) =>
      oldDelegate.axis != axis ||
      oldDelegate.divisions != divisions ||
      oldDelegate.inset != inset ||
      oldDelegate.size != size ||
      oldDelegate.color != color;
}
