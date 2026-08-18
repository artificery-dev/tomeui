import 'package:tomeui/tomeui.dart';

/// The ring that marks what has the keyboard: an outset rounded stroke,
/// concentric with the control's own corners, standing a hairline off its
/// edge.
///
/// Painted rather than laid out, so focus never shifts anything, and faded
/// in and out rather than popped. [Interactive] wears one for the controls
/// it drives; `TextField` wears one directly, since a field's focus comes
/// from its editor rather than from a tap it handled itself.
///
/// Toolkit-internal: not exported by the barrel.
class FocusRing extends StatelessWidget {
  const FocusRing({
    required this.visible,
    required this.color,
    required this.radius,
    required this.child,
    super.key,
  });

  final bool visible;
  final Color color;

  /// The control's corners. The ring grows them with it, so the two stay
  /// concentric.
  final BorderRadius radius;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    return TweenAnimationBuilder<double>(
      tween: Tween(end: visible ? 1.0 : 0.0),
      duration: theme.motion.instant,
      curve: theme.motion.move,
      builder: (context, presence, child) => CustomPaint(
        foregroundPainter: presence == 0
            ? null
            : _FocusRingPainter(
                color: color.withValues(alpha: color.a * presence),
                radius: radius,
                gap: theme.strokes.hairline,
                width: theme.strokes.focus,
              ),
        child: child,
      ),
      child: child,
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.color,
    required this.radius,
    required this.gap,
    required this.width,
  });

  final Color color;
  final BorderRadius radius;
  final double gap;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    // Inflating the RRect grows its radii with it, keeping the ring
    // concentric with the control's corners.
    final ring = radius.toRRect(Offset.zero & size).inflate(gap + width / 2);
    canvas.drawRRect(
      ring,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.gap != gap ||
      oldDelegate.width != width;
}
