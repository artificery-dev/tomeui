import 'package:tomeui/tomeui.dart';

/// A count, or the bare fact that something happened.
///
/// Rides on whatever it's given — an icon, a button, a tab — sitting past
/// its top trailing corner:
///
/// ```dart
/// Badge.count(3, child: Icon(icons.info))
/// Badge.dot(child: Icon(icons.info))
/// ```
///
/// Without a [child] it's just the badge, for a row that has somewhere of
/// its own to put one. A count past [max] reads as `9+` rather than
/// growing: the difference between 9 and 40 unread is not worth the width.
///
/// A badge is a mark on something; a [StatusChip] is a word about
/// something. If it needs a word, it's a chip.
class Badge extends StatelessWidget {
  const Badge.count(
    this.count, {
    this.child,
    this.max = 9,
    this.swatch = SemanticSwatch.error,
    this.style,
    super.key,
  }) : label = null;

  /// No number, only the fact: something is waiting.
  const Badge.dot({
    this.child,
    this.swatch = SemanticSwatch.error,
    this.style,
    super.key,
  }) : count = null,
       label = null,
       max = 0;

  /// Something else entirely — `NEW`, a single letter, a tiny glyph.
  const Badge.label(
    this.label, {
    this.child,
    this.swatch = SemanticSwatch.error,
    this.style,
    super.key,
  }) : count = null,
       max = 0;

  /// How many. Zero draws nothing at all — a badge saying nothing has
  /// happened is a badge that shouldn't be there.
  final int? count;

  /// What the badge says, where that isn't a number.
  final Widget? label;

  /// The most the count says before it gives up counting.
  final int max;

  /// What the badge rides on. Null is the badge alone.
  final Widget? child;

  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final BadgeStyle? style;

  bool get _dot => count == null && label == null;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.badge.resolve(swatch);

    if (count != null && count! <= 0) {
      return child ?? const SizedBox.shrink();
    }

    final mark = _dot
        ? SizedBox.square(
            dimension: style.dotSize,
            child: Surface.custom(style: style.surface),
          )
        : Semantics(
            container: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: style.size,
                minHeight: style.size,
              ),
              child: Surface.custom(
                style: style.surface,
                padding: style.padding,
                child: Center(
                  widthFactor: 1,
                  child: DefaultTextStyle.merge(
                    style: style.textStyle,
                    maxLines: 1,
                    child:
                        label ??
                        Text(count! > max ? '$max+' : '$count'),
                  ),
                ),
              ),
            ),
          );

    if (child == null) return mark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        // Out past the corner rather than over it: a badge that covered
        // what it marks would be marking nothing.
        PositionedDirectional(
          top: style.offset.dy,
          end: -style.offset.dx,
          child: mark,
        ),
      ],
    );
  }
}
