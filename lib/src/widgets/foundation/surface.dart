import 'dart:math' as math;

import 'package:tomeui/tomeui.dart';

/// A themed rectangle everything else sits on.
///
/// A surface wears any [Swatch] — the theme's accent by default — in one of
/// the [SurfaceVariant] treatments. The theme does the choosing
/// (`theme.widgets.surface.resolve`); the surface paints what it's told and
/// speaks its foreground to everything inside through [DefaultTextStyle] and
/// [IconTheme], which is how text widgets get their colour without ever
/// being told one.
class Surface extends StatelessWidget {
  const Surface({
    this.variant = SurfaceVariant.solid,
    this.swatch,
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
       swatch = null;

  final SurfaceVariant variant;

  /// The colour to wear. Null wears the theme's accent.
  final Swatch? swatch;

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
        color: style.fill,
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

    if (style.dashed && style.border != null) {
      box = CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: style.border!,
          radius: style.radius,
          width: theme.strokes.hairline,
        ),
        child: box,
      );
    }
    return box;
  }
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
