import 'package:tomeui/tomeui.dart';

/// What state a thing is in, in one word.
///
/// A small stadium wearing a [SemanticSwatch] softly: `Delivered` in
/// success, `Overdue` in error, `Draft` in neutral. It marks a *thing* —
/// a row, a card, a heading — rather than the page, which is what
/// separates it from a [Callout].
///
/// ```dart
/// StatusChip(label: const Text('Delivered'), swatch: SemanticSwatch.success)
/// ```
///
/// [dot] gives it a round mark in the swatch's full voice, for a status
/// whose meaning is the colour. [icon] gives it a glyph instead. It isn't
/// pressable: a chip that did something would be a [Button] shaped like a
/// chip, and should say so.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    this.icon,
    this.dot = false,
    this.swatch = SemanticSwatch.neutral,
    this.variant = SurfaceVariant.soft,
    this.style,
    super.key,
  }) : assert(
         icon == null || !dot,
         'A chip carries a glyph or a dot, not both.',
       );

  final Widget label;

  /// A glyph before the words.
  final IconData? icon;

  /// A round mark before the words, in the swatch at full voice.
  final bool dot;

  final SemanticSwatch swatch;
  final SurfaceVariant variant;

  /// The style to paint, bypassing the theme.
  final ChipStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.chip.resolve(swatch, variant);

    return Semantics(
      container: true,
      child: SizedBox(
        height: style.height,
        child: Surface.custom(
          style: style.surface,
          padding: style.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot) ...[
                SizedBox.square(
                  dimension: style.dotSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // The full voice against the soft fill: the dot is
                      // the loudest thing on a quiet chip.
                      color:
                          theme.widgets.surface
                              .resolve(swatch, SurfaceVariant.solid)
                              .fill ??
                          style.surface.foreground,
                    ),
                  ),
                ),
                SizedBox(width: style.gap),
              ],
              if (icon != null) ...[
                Icon(icon, size: style.iconSize),
                SizedBox(width: style.gap),
              ],
              DefaultTextStyle.merge(
                style: style.textStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                child: label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
