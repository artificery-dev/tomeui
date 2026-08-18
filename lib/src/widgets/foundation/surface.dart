import 'dart:math' as math;

import 'package:tomeui/tomeui.dart';

/// A themed rectangle everything else sits on.
///
/// A surface wears a [SemanticSwatch] — [SemanticSwatch.primary] by default
/// — in one of the [SurfaceVariant] treatments. The theme does the choosing
/// (`theme.widgets.surface.resolve`); the surface paints what it's told and
/// speaks its foreground to everything inside through [DefaultTextStyle] and
/// [IconTheme], which is how text widgets get their colour without ever
/// being told one.
class Surface extends StatelessWidget {
  const Surface({
    this.variant = SurfaceVariant.solid,
    this.swatch = SemanticSwatch.primary,
    this.padding,
    this.child,
    super.key,
  }) : style = null;

  /// Custom everything: paints [style] exactly as given, resolving nothing.
  const Surface.custom({
    required SurfaceStyle this.style,
    this.padding,
    this.child,
    super.key,
  }) : variant = SurfaceVariant.solid,
       swatch = SemanticSwatch.primary;

  final SurfaceVariant variant;

  /// The meaning to wear — the palette says which colour that is.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme — set only by [Surface.custom].
  final SurfaceStyle? style;

  final EdgeInsetsGeometry? padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.surface.resolve(swatch, variant);

    Widget box = Container(
      padding: padding,
      decoration: BoxDecoration(
        // A striped fill is painted, not decorated.
        color: style.striped ? null : style.fill,
        borderRadius: style.radius,
        border: style.border != null && !style.dashed
            ? Border.all(color: style.border!, width: theme.strokes.hairline)
            : null,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: style.foreground),
        child: IconTheme.merge(
          data: IconThemeData(color: style.foreground),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );

    final stripes = style.striped && style.fill != null
        ? _StripedFillPainter(
            color: style.fill!,
            radius: style.radius,
            width: theme.strokes.hairline,
          )
        : null;
    final dashes = style.dashed && style.border != null
        ? _DashedBorderPainter(
            color: style.border!,
            radius: style.radius,
            width: theme.strokes.hairline,
          )
        : null;
    if (stripes != null || dashes != null) {
      box = CustomPaint(painter: stripes, foregroundPainter: dashes, child: box);
    }
    return box;
  }
}

/// The diagonal wash behind a striped fill — hairlines at 45°, clipped to
/// the surface's corners.
class _StripedFillPainter extends CustomPainter {
  const _StripedFillPainter({
    required this.color,
    required this.radius,
    required this.width,
  });

  final Color color;
  final BorderRadius radius;
  final double width;

  /// Horizontal run between stripes; ~6 logical pixels perpendicular.
  static const _step = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    canvas.clipRRect(radius.toRRect(Offset.zero & size));
    // Down-and-right at 45°, starting far enough left to cover the corner.
    for (var x = -size.height; x < size.width; x += _step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripedFillPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.width != width;
}

/// The dashed hairline a [SurfaceVariant.placeholder] wears.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.width,
  });

  final Color color;
  final BorderRadius radius;
  final double width;

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    // Inset by half the stroke so the dashes sit on the edge, not astride it.
    final rect = (Offset.zero & size).deflate(width / 2);
    final path = Path()..addRRect(radius.toRRect(rect));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            math.min(distance + _dash, metric.length),
          ),
          paint,
        );
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.width != width;
}
