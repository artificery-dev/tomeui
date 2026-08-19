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
/// The track fills the width it's given — a slider is a measurement, and
/// how long it is says how finely it can be read. In a slot that doesn't
/// say, it takes [SliderStyle.minWidth].
class Slider extends StatefulWidget {
  const Slider({
    required this.value,
    required this.onChanged,
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

  /// The value under a point, measured in the track's own coordinates.
  ///
  /// The thumb's *centre* travels a shorter distance than the track is
  /// wide — half a thumb is parked at each end — so the mapping runs
  /// between those centres, not between the edges.
  double _valueAt(double dx, double width, SliderStyle style) {
    final travel = width - style.thumbSize;
    if (travel <= 0) return widget.min;
    final fraction = ((dx - style.thumbSize / 2) / travel).clamp(0.0, 1.0);
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
                // A slider in an unbounded row still has to be some
                // length; the style says how long.
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : style.minWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _enabled
                      ? (details) {
                          setState(() => _pressed = true);
                          // A tap anywhere on the band takes the thumb
                          // there — a slider you can only drag is a slider
                          // you have to aim at.
                          _report(
                            _valueAt(details.localPosition.dx, width, style),
                          );
                        }
                      : null,
                  onTapUp: _enabled
                      ? (_) => setState(() => _pressed = false)
                      : null,
                  onTapCancel: _enabled
                      ? () => setState(() => _pressed = false)
                      : null,
                  onHorizontalDragStart: _enabled
                      ? (details) {
                          setState(() => _pressed = true);
                          widget.onChangeStart?.call(widget.value);
                          _report(
                            _valueAt(details.localPosition.dx, width, style),
                          );
                        }
                      : null,
                  onHorizontalDragUpdate: _enabled
                      ? (details) => _report(
                          _valueAt(details.localPosition.dx, width, style),
                        )
                      : null,
                  onHorizontalDragEnd: _enabled
                      ? (_) {
                          setState(() => _pressed = false);
                          widget.onChangeEnd?.call(widget.value);
                        }
                      : null,
                  child: SizedBox(
                    width: constraints.maxWidth.isFinite ? null : width,
                    height: style.height,
                    child: _track(theme, style, width),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _track(Theme theme, SliderStyle style, double width) {
    final travel = width - style.thumbSize;
    final divisions = widget.divisions;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: _fraction),
      // Dragging is already continuous; the glide is for the arrow keys
      // and for a value the caller moved on its own.
      duration: _pressed ? Duration.zero : theme.motion.instant,
      curve: theme.motion.move,
      builder: (context, fraction, _) {
        final centre = style.thumbSize / 2 + fraction * travel;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // The whole track, then the travelled part over it: two boxes
            // rather than a row, so the join can't show a seam.
            SizedBox(
              height: style.trackHeight,
              child: Surface.custom(style: style.inactive),
            ),
            SizedBox(
              width: centre,
              height: style.trackHeight,
              child: Surface.custom(style: style.active),
            ),
            if (divisions != null && style.tick != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _TickPainter(
                    divisions: divisions,
                    inset: style.thumbSize / 2,
                    size: style.tickSize,
                    color: style.tick!,
                  ),
                ),
              ),
            Positioned(
              left: centre - style.thumbSize / 2,
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
    required this.divisions,
    required this.inset,
    required this.size,
    required this.color,
  });

  final int divisions;
  final double inset;
  final double size;
  final Color color;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final travel = canvasSize.width - inset * 2;
    if (travel <= 0) return;
    final paint = Paint()..color = color;
    for (var i = 0; i <= divisions; i++) {
      canvas.drawCircle(
        Offset(inset + travel * i / divisions, canvasSize.height / 2),
        size / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) =>
      oldDelegate.divisions != divisions ||
      oldDelegate.inset != inset ||
      oldDelegate.size != size ||
      oldDelegate.color != color;
}
