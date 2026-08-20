import 'package:tomeui/tomeui.dart';

/// The page telling you something, in the colour of what kind of something
/// it is.
///
/// A tinted block with a glyph, a title, and a message — the notice above a
/// form, the warning above a list, the hint beside an empty field:
///
/// ```dart
/// Callout(
///   swatch: SemanticSwatch.warning,
///   title: const Text('The manifest is unsigned'),
///   message: const Text('Nothing sails until it is.'),
///   actions: [Button(onPressed: sign, center: const Text('Sign'))],
/// )
/// ```
///
/// It speaks for the page or the section it sits in; a [StatusChip] speaks
/// for one thing in a list. If it can be dismissed it takes an
/// [onDismiss], and grows a close button to do it with.
class Callout extends StatelessWidget {
  const Callout({
    this.title,
    this.message,
    this.actions = const [],
    this.icon,
    this.onDismiss,
    this.swatch = SemanticSwatch.info,
    this.variant = SurfaceVariant.soft,
    this.style,
    super.key,
  });

  final Widget? title;
  final Widget? message;

  /// What can be done about it, under the words.
  final List<Widget> actions;

  /// The glyph at the leading edge. Null takes the one the swatch implies —
  /// a warning triangle for [SemanticSwatch.warning], and so on — which is
  /// what makes a callout readable before it's read.
  final IconData? icon;

  /// Putting it away. Null means it stays.
  final VoidCallback? onDismiss;

  final SemanticSwatch swatch;
  final SurfaceVariant variant;

  /// The style to paint, bypassing the theme.
  final CalloutStyle? style;

  /// The glyph a meaning implies, when the caller hasn't named one.
  static IconData glyphFor(SemanticSwatch swatch, Icons icons) =>
      switch (swatch) {
        SemanticSwatch.success => icons.success,
        SemanticSwatch.warning => icons.warning,
        SemanticSwatch.error => icons.error,
        _ => icons.info,
      };

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.callout.resolve(swatch, variant);

    return Semantics(
      container: true,
      liveRegion: true,
      child: Surface.custom(
        style: style.surface,
        padding: style.padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon ?? glyphFor(swatch, theme.icons),
              size: style.iconSize,
              color: style.surface.foreground,
            ),
            SizedBox(width: style.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    DefaultTextStyle.merge(
                      style: style.titleStyle,
                      child: title!,
                    ),
                  if (title != null && message != null)
                    SizedBox(height: style.textGap),
                  if (message != null)
                    DefaultTextStyle.merge(
                      style: style.messageStyle,
                      child: message!,
                    ),
                  if (actions.isNotEmpty) ...[
                    SizedBox(height: style.gap),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final (index, action) in actions.indexed) ...[
                          if (index > 0) SizedBox(width: style.textGap),
                          action,
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null) ...[
              SizedBox(width: style.gap),
              Semantics(
                label: theme.labels.dismiss,
                child: Button(
                  onPressed: onDismiss,
                  variant: SurfaceVariant.ghost,
                  swatch: swatch,
                  center: Icon(theme.icons.close, size: style.iconSize),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
