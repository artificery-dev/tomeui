import 'dart:math' as math;

import 'package:flutter/rendering.dart';
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
    if (style.striped && style.fill != null) {
      box = _StripedFill(
        color: style.fill!,
        radius: style.radius,
        width: theme.strokes.hairline,
        child: box,
      );
    }
    // What everything inside is being drawn on. Text and icons are told
    // through [DefaultTextStyle] and [IconTheme]; anything that paints for
    // itself has to be able to ask.
    return SurfaceDress(style: style, child: box);
  }
}

/// What the nearest [Surface] above is wearing.
///
/// A widget that paints its own colours can be handed a swatch and still
/// end up invisible — a primary spinner on a solid primary button is the
/// button. Asking what it sits on is how it can tell, and [SurfaceStyle]
/// carries both halves of the answer: the [SurfaceStyle.fill] it would be
/// drawn against and the [SurfaceStyle.foreground] that surface speaks in.
class SurfaceDress extends InheritedWidget {
  const SurfaceDress({required this.style, required super.child, super.key});

  final SurfaceStyle style;

  /// What the nearest surface above [context] wears, or null out on the
  /// page where there is no surface at all.
  static SurfaceStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SurfaceDress>()?.style;

  @override
  bool updateShouldNotify(SurfaceDress oldWidget) => oldWidget.style != style;
}

/// Marks the subtree an enclosing striped [Surface] keeps clear: the
/// stripes part around it instead of running behind it.
///
/// [Placeholder] wraps its child in one automatically; reach for it
/// directly only inside a custom striped surface.
class StripeGap extends SingleChildRenderObjectWidget {
  const StripeGap({super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderStripeGap();
}

class _RenderStripeGap extends RenderProxyBox {}

/// The diagonal wash behind a striped fill — hairlines at 45°, clipped to
/// the surface's corners, parting around a descendant [StripeGap].
class _StripedFill extends SingleChildRenderObjectWidget {
  const _StripedFill({
    required this.color,
    required this.radius,
    required this.width,
    super.child,
  });

  final Color color;
  final BorderRadius radius;
  final double width;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStripedFill(color, radius, width);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderStripedFill renderObject,
  ) {
    renderObject
      ..color = color
      ..radius = radius
      ..width = width;
  }
}

class _RenderStripedFill extends RenderProxyBox {
  _RenderStripedFill(this._color, this._radius, this._width);

  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  BorderRadius _radius;
  set radius(BorderRadius value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  double _width;
  set width(double value) {
    if (value == _width) return;
    _width = value;
    markNeedsPaint();
  }

  /// Horizontal run between stripes
  static const _step = 12.0;

  /// How much clear margin the gap gets beyond its own bounds.
  static const _breath = 4.0;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bounds = offset & size;
    canvas.save();
    canvas.clipRRect(_radius.toRRect(bounds));

    final gap = _gapIn(this);
    if (gap != null && gap.hasSize && !gap.size.isEmpty) {
      final hole = MatrixUtils.transformRect(
        gap.getTransformTo(this),
        Offset.zero & gap.size,
      ).shift(offset).inflate(_breath);
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(bounds),
          Path()..addRect(hole),
        ),
      );
    }

    final paint = Paint()
      ..color = _color
      ..strokeWidth = _width;
    // Down-and-right at 45°, starting far enough left to cover the corner.
    for (var x = -size.height; x < size.width; x += _step) {
      canvas.drawLine(
        offset + Offset(x, 0),
        offset + Offset(x + size.height, size.height),
        paint,
      );
    }
    canvas.restore();
    super.paint(context, offset);
  }

  /// The nearest [StripeGap] below [root], not crossing into a nested
  /// striped surface — its gaps are its own.
  static _RenderStripeGap? _gapIn(RenderObject root) {
    _RenderStripeGap? found;
    void visit(RenderObject child) {
      if (found != null || child is _RenderStripedFill) return;
      if (child is _RenderStripeGap) {
        found = child;
        return;
      }
      child.visitChildren(visit);
    }

    root.visitChildren(visit);
    return found;
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
