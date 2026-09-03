import 'dart:math' as math;

import 'package:tomeui/tomeui.dart';

/// A [Surface] that holds content, in five slots.
///
/// [header], [content], and [footer] stack vertically; [leading] and
/// [trailing] bookend that stack. Every slot is optional, and a card of one
/// slot is just a padded surface.
///
/// ```dart
/// Card(
///   header: TitleText('Manifest'),
///   content: BodyText('Eight bells, wind freshening.'),
///   footer: Button(onPressed: sign, center: const Text('Sign')),
/// )
/// ```
///
/// ## Spacing
///
/// One [spacing] governs the whole card: it's the daylight a slot keeps
/// between itself and its neighbors, *and* between itself and the card's
/// edge — a card has no separate padding, because the two are the same
/// measurement seen from either side.
///
/// Each slot may override it with a step of its own. Where two slots meet,
/// the roomier of the pair wins, so the override never has to be repeated
/// on the other side of a gap. Zero is what makes a slot full bleed: the
/// card's edge is the slot's edge, which is how a header image or a leading
/// video runs to the corners while the text beside it stays inset.
///
/// ```dart
/// Card(
///   header: Image.asset('chart.png'),
///   headerSpacing: SpaceStep.none,   // to the corners
///   content: BodyText('Soundings off the cape.'),
/// )
/// ```
class Card extends StatelessWidget {
  const Card({
    this.header,
    this.content,
    this.footer,
    this.leading,
    this.trailing,
    this.spacing,
    this.headerSpacing,
    this.contentSpacing,
    this.footerSpacing,
    this.leadingSpacing,
    this.trailingSpacing,
    this.variant = SurfaceVariant.outline,
    this.swatch = SemanticSwatch.neutral,
    this.style,
    super.key,
  });

  /// Above the content: a title, a toolbar, an image.
  final Widget? header;

  final Widget? content;

  /// Below the content: actions, a footnote, a status line.
  final Widget? footer;

  /// Beside the stack, on the leading edge — an avatar, a thumbnail, an
  /// icon.
  final Widget? leading;

  /// Beside the stack, on the trailing edge — a chevron, an action, a
  /// timestamp.
  final Widget? trailing;

  /// The daylight every slot keeps, unless it says otherwise. Defaults to
  /// the resolved [CardStyle.spacing].
  final SpaceStep? spacing;

  final SpaceStep? headerSpacing;
  final SpaceStep? contentSpacing;
  final SpaceStep? footerSpacing;
  final SpaceStep? leadingSpacing;
  final SpaceStep? trailingSpacing;

  final SurfaceVariant variant;

  /// The meaning to wear — quietly. A card holds content rather than
  /// asking for a press.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final CardStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.card.resolve(swatch, variant);
    final base = spacing == null
        ? style.spacing
        : theme.space.resolve(spacing!);
    double gap(SpaceStep? own) => own == null ? base : theme.space.resolve(own);

    final start = leading == null ? null : gap(leadingSpacing);
    final end = trailing == null ? null : gap(trailingSpacing);

    // The rows of the stack, in order, each with the daylight it keeps.
    final rows = <(Widget, double)>[
      if (header != null) (header!, gap(headerSpacing)),
      if (content != null) (content!, gap(contentSpacing)),
      if (footer != null) (footer!, gap(footerSpacing)),
    ];

    final stack = <Widget>[
      for (final (index, (child, own)) in rows.indexed)
        Padding(
          padding: EdgeInsetsDirectional.only(
            // Against a neighbor the roomier of the two wins; against the
            // card's edge a slot answers for itself.
            top: index == 0 ? own : _wider(own, rows[index - 1].$2),
            bottom: index == rows.length - 1 ? own : 0,
            start: start == null ? own : _wider(own, start),
            end: end == null ? own : _wider(own, end),
          ),
          child: child,
        ),
    ];

    return Surface.custom(
      style: style.surface,
      // A full-bleed slot runs to the corners, so the corners have to be
      // able to cut it — inside the hairline, where the border leaves it.
      child: ClipRRect(
        borderRadius: _inside(
          style.surface.radius,
          style.surface.border == null ? 0 : theme.strokes.hairline,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: start!,
                  top: start,
                  bottom: start,
                ),
                child: leading,
              ),
            if (stack.isNotEmpty)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: stack,
                ),
              ),
            if (trailing != null)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: end!,
                  top: end,
                  bottom: end,
                ),
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }

  static double _wider(double a, double b) => a > b ? a : b;

  /// [radius] as it reads from inside a border [stroke] thick.
  static BorderRadius _inside(BorderRadius radius, double stroke) {
    if (stroke == 0) return radius;
    Radius tighter(Radius corner) => Radius.elliptical(
      math.max(0, corner.x - stroke),
      math.max(0, corner.y - stroke),
    );
    return BorderRadius.only(
      topLeft: tighter(radius.topLeft),
      topRight: tighter(radius.topRight),
      bottomLeft: tighter(radius.bottomLeft),
      bottomRight: tighter(radius.bottomRight),
    );
  }
}
