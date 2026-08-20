import 'package:tomeui/tomeui.dart';

/// The shape of what's coming, while it comes.
///
/// A neutral block with a light travelling across it — the page's layout,
/// held open, so that content arriving doesn't shove everything sideways:
///
/// ```dart
/// Skeleton.text(lines: 3)
/// Skeleton.box(height: 120)
/// Skeleton.circle(size: 40)
/// ```
///
/// The shimmer is the whole point: a still grey box reads as a thing that
/// has loaded and is grey, while one with a light passing over it reads as
/// a thing on its way. Where the reader has asked for less motion
/// ([MediaQuery.disableAnimationsOf]), it holds still and says so through
/// its semantics instead.
class Skeleton extends StatefulWidget {
  /// A block of a given size — an image, a card, a map.
  const Skeleton.box({this.width, this.height, this.radius, this.style, super.key})
    : lines = 0,
      _circle = false;

  /// Stand-in text: [lines] bars at the style's line height, the last one
  /// short, the way a real paragraph ends.
  const Skeleton.text({this.lines = 3, this.width, this.style, super.key})
    : height = null,
      radius = null,
      _circle = false;

  /// A round block — an avatar.
  const Skeleton.circle({double size = 40, this.style, super.key})
    : width = size,
      height = size,
      lines = 0,
      radius = null,
      _circle = true;

  final double? width;
  final double? height;

  /// How many lines of stand-in text. Zero is a block.
  final int lines;

  /// The corners, where the shape's own aren't wanted.
  final BorderRadius? radius;

  /// The style to paint, bypassing the theme.
  final SkeletonStyle? style;

  final bool _circle;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.skeleton.resolve();
    _sheen.duration = style.period;

    // Asked for less motion, it holds still: a shimmer is decoration, and
    // decoration is the first thing that should stop.
    if (MediaQuery.disableAnimationsOf(context)) {
      _sheen.stop();
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.skeleton.resolve();

    return Semantics(
      label: theme.labels.loading,
      child: widget.lines > 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.lines; i++) ...[
                  if (i > 0) SizedBox(height: style.lineGap),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: i == widget.lines - 1
                        ? style.lastLineFraction
                        : 1,
                    child: _shape(
                      style,
                      height: style.lineHeight,
                      radius: BorderRadius.circular(style.lineHeight / 2),
                    ),
                  ),
                ],
              ],
            )
          : _shape(
              style,
              width: widget.width,
              height: widget.height,
              radius: widget._circle
                  ? BorderRadius.circular((widget.width ?? 0) / 2)
                  : widget.radius ?? style.radius,
            ),
    );
  }

  Widget _shape(
    SkeletonStyle style, {
    double? width,
    double? height,
    required BorderRadius radius,
  }) => SizedBox(
    width: width,
    height: height,
    child: AnimatedBuilder(
      animation: _sheen,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: style.fill,
          borderRadius: radius,
          gradient: _sheen.isAnimating
              ? _sweep(style, _sheen.value)
              : null,
        ),
      ),
    ),
  );

  /// The light, part-way across. It travels from off one edge to off the
  /// other, so the shape spends part of every pass at rest — a sheen that
  /// never leaves reads as a pattern rather than a passing light.
  LinearGradient _sweep(SkeletonStyle style, double progress) {
    final centre = progress * 3 - 1;
    return LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [style.fill, style.sheen, style.fill],
      stops: [
        (centre - 0.3).clamp(0.0, 1.0),
        centre.clamp(0.0, 1.0),
        (centre + 0.3).clamp(0.0, 1.0),
      ],
    );
  }
}
