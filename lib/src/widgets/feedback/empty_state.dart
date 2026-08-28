import 'package:tomeui/tomeui.dart';

/// There's nothing here, and here's what to do about it.
///
/// The panel a list shows before it has rows, a search shows when nothing
/// matched, a folder shows when it's empty:
///
/// ```dart
/// EmptyState(
///   icon: icons.folder,
///   title: const Text('No voyages yet'),
///   message: const Text('Log the first one and it will show up here.'),
///   action: Button(onPressed: log, center: const Text('Log a voyage')),
/// )
/// ```
///
/// Quiet all through: nothing has gone wrong, so the loudest thing on
/// screen is the [action]. Its words wrap at a readable measure rather
/// than running the width of the slot, and the whole thing sits centred in
/// the room it's given — an empty state fills the emptiness it's reporting,
/// which is what makes it read as the slot rather than as a note left in
/// the corner of one. Under unbounded room it hugs its words instead.
///
/// It wears a [SurfaceVariant] like anything else, and the default is
/// [SurfaceVariant.subtle]: the faintest panel the palette has, which is
/// what an empty slot looks like — present, and plainly not full. Give it
/// [SurfaceVariant.outline] for the bordered card, or
/// [SurfaceVariant.ghost] for no panel at all, where the empty state is
/// already inside one.
class EmptyState extends StatelessWidget {
  const EmptyState({
    this.title,
    this.message,
    this.icon,
    this.illustration,
    this.action,
    this.swatch = SemanticSwatch.neutral,
    this.variant = SurfaceVariant.subtle,
    this.style,
    super.key,
  }) : assert(
         icon == null || illustration == null,
         'An empty state shows a glyph or a picture, not both.',
       );

  final Widget? title;
  final Widget? message;

  /// A glyph above the words.
  final IconData? icon;

  /// Something more than a glyph, where an app has one.
  final Widget? illustration;

  /// The one thing to do about it.
  final Widget? action;

  /// The meaning to wear — neutral by default: absence is quiet.
  final SemanticSwatch swatch;

  /// The panel it draws for itself — the faintest one by default, and
  /// [SurfaceVariant.ghost] where none is wanted.
  final SurfaceVariant variant;

  /// The style to paint, bypassing the theme.
  final EmptyStateStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style =
        this.style ?? theme.widgets.emptyState.resolve(swatch, variant);

    return Semantics(
      container: true,
      child: Surface.custom(
        style: style.surface,
        padding: style.padding,
        // The panel hugs its words: an empty state is a card the caller
        // centres in the empty room, not a wash over all of it.
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: style.maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (illustration != null) ...[
                illustration!,
                SizedBox(height: style.gap),
              ] else if (icon != null) ...[
                Icon(icon, size: style.iconSize, color: style.glyph),
                SizedBox(height: style.gap),
              ],
              if (title != null) ...[
                DefaultTextStyle.merge(
                  style: style.titleStyle,
                  textAlign: TextAlign.center,
                  child: title!,
                ),
                if (message != null) SizedBox(height: style.gap),
              ],
              if (message != null)
                DefaultTextStyle.merge(
                  style: style.messageStyle,
                  textAlign: TextAlign.center,
                  child: message!,
                ),
              if (action != null) ...[
                SizedBox(height: style.actionGap),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
