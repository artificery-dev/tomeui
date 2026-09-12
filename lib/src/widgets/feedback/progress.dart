import 'dart:math' as math;

import 'package:tomeui/tomeui.dart';

/// Something is happening, and here's how far along it is.
///
/// Two shapes, one widget: [Progress.bar] where there's a width to fill,
/// and [Progress.spinner] where there isn't — inside a button, beside a
/// row, anywhere a bar would be a strange thing to put.
///
/// ```dart
/// Progress.bar(value: uploaded / total)   // known
/// const Progress.spinner()                // not known
/// ```
///
/// A null [value] means nobody knows how long: the bar sweeps and the
/// spinner turns, and neither pretends to measure anything. A value between
/// 0 and 1 is a measurement, and the widget stops moving on its own.
class Progress extends StatefulWidget {
  const Progress.bar({
    this.value,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  }) : _spinner = false;

  const Progress.spinner({
    this.value,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  }) : _spinner = true;

  /// How far along, from 0 to 1 — or null for work of unknown length.
  final double? value;

  final SemanticSwatch swatch;

  /// The style to draw, bypassing the theme.
  final ProgressStyle? style;

  final bool _spinner;

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(vsync: this);

  // The theme is a dependency, and dependencies aren't there yet in
  // initState — which is where a controller wanting the period would
  // naturally have gone.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Progress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Only work of unknown length moves on its own. A measured bar that
  /// also swept would be saying two things at once.
  void _sync() {
    final style =
        widget.style ??
        (ThemeProvider.maybeOf(context) ?? const Theme()).widgets.progress
            .resolve(widget.swatch);
    _turn.duration = style.period;
    if (widget.value == null) {
      if (!_turn.isAnimating) _turn.repeat();
    } else {
      _turn
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style =
        widget.style ??
        theme.widgets.progress.resolve(
          widget.swatch,
          // What it's being drawn on, so a spinner inside a button of its
          // own swatch doesn't paint the button onto the button.
          SurfaceDress.maybeOf(context),
        );
    final value = widget.value?.clamp(0.0, 1.0);

    return Semantics(
      label: theme.labels.loading,
      value: value == null ? null : '${(value * 100).round()}%',
      child: widget._spinner
          ? _spinner(style, value)
          : _bar(theme, style, value),
    );
  }

  Widget _bar(Theme theme, ProgressStyle style, double? value) => LayoutBuilder(
    // A bar in an unbounded row still has to be some length; the style
    // says how long. The same rule a `Slider` follows, for the same reason.
    builder: (context, constraints) => SizedBox(
      width: constraints.maxWidth.isFinite ? null : style.minWidth,
      height: style.thickness,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.track,
          borderRadius: style.radius,
        ),
        child: ClipRRect(
          borderRadius: style.radius,
          child: value == null
              ? AnimatedBuilder(
                  animation: _turn,
                  builder: (context, _) => _Sweep(
                    progress: _turn.value,
                    color: style.indicator,
                    radius: style.radius,
                  ),
                )
              // The alignment belongs to the fraction, not to an [Align]
              // around it: an Align loosens what it hands down, and a
              // childless [DecoratedBox] under a loose height is a fill
              // nought pixels tall.
              : FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: style.indicator,
                      borderRadius: style.radius,
                    ),
                  ),
                ),
        ),
      ),
    ),
  );

  Widget _spinner(ProgressStyle style, double? value) => SizedBox.square(
    dimension: style.spinnerSize,
    child: AnimatedBuilder(
      animation: _turn,
      builder: (context, _) => CustomPaint(
        // A picture that changes every frame is one the raster cache should
        // leave alone: cached, it gets blitted through whatever transform
        // is above it — a button's hover lift, say — and an arc drawn once
        // at one size and stretched to another is an arc with steps in it.
        willChange: true,
        isComplex: false,
        painter: _SpinnerPainter(
          track: style.track,
          indicator: style.indicator,
          thickness: style.spinnerThickness,
          // Turning, the arc is a fixed slice chasing its own tail; still,
          // it's the measurement itself.
          turn: _turn.value,
          value: value,
        ),
      ),
    ),
  );
}

/// The travelling segment of an indeterminate bar: from the leading edge
/// to the trailing one and back again, a shuttle rather than a conveyor,
/// so there is never a jump for the eye to catch.
class _Sweep extends StatelessWidget {
  const _Sweep({
    required this.progress,
    required this.color,
    required this.radius,
  });

  final double progress;
  final Color color;
  final BorderRadius radius;

  /// How much of the track the segment covers.
  static const _length = 0.35;

  @override
  Widget build(BuildContext context) {
    // One period is one round trip: out over the first half, back over the
    // second, easing into each end so the turn reads as a turn and not a
    // bounce.
    final there = 1 - (progress * 2 - 1).abs();
    final along = Curves.easeInOut.transform(there);
    return FractionallySizedBox(
      widthFactor: _length,
      // Alignment -1 puts the segment's leading edge on the track's; +1
      // puts its trailing edge on the track's.
      alignment: Alignment(along * 2 - 1, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: radius),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({
    required this.track,
    required this.indicator,
    required this.thickness,
    required this.turn,
    required this.value,
  });

  final Color track;
  final Color indicator;
  final double thickness;

  /// Where in its rotation the spinner is, from 0 to 1.
  final double turn;

  final double? value;

  /// The slice an indeterminate spinner shows — a quarter turn, which reads
  /// as motion without reading as a measurement.
  static const _slice = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bounds = rect.deflate(thickness / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(bounds, 0, math.pi * 2, false, paint..color = track);

    final sweep = (value ?? _slice) * math.pi * 2;
    // Twelve o'clock is where a dial starts; canvas angles start at three.
    final from = -math.pi / 2 + (value == null ? turn * math.pi * 2 : 0);
    canvas.drawArc(bounds, from, sweep, false, paint..color = indicator);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.track != track ||
      oldDelegate.indicator != indicator ||
      oldDelegate.thickness != thickness ||
      oldDelegate.turn != turn ||
      oldDelegate.value != value;
}
