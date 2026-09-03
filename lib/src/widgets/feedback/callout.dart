import 'dart:math' as math;

import 'package:tomeui/tomeui.dart';

/// The page telling you something, in the color of what kind of something
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

    // The glyph, the heading and the close button are one line across the
    // top of the block. A callout with no title heads with its message
    // instead, so the glyph never sits beside nothing.
    final head = title ?? message;
    final headStyle = title != null ? style.titleStyle : style.messageStyle;
    final rest = title != null ? message : null;

    // What the head's first line measures, which is what the glyph and the
    // close button are centerd in: aligned to the words rather than to the
    // paragraph, so a title that wraps doesn't drag them down with it.
    final line = math.max(
      style.iconSize,
      (headStyle.fontSize ?? 16) * (headStyle.height ?? 1.4),
    );

    // The close button is square and flush to the edge — a notice's
    // quietest affordance shouldn't be its widest.
    final dismissStyle = theme.widgets.button
        .resolve(swatch, SurfaceVariant.ghost)
        .copyWith(
          height: line,
          padding: EdgeInsets.symmetric(
            horizontal: math.max(0, (line - style.dismissIconSize) / 2),
          ),
        );

    return Semantics(
      container: true,
      liveRegion: true,
      child: Surface.custom(
        style: style.surface,
        padding: style.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: line,
                  child: Center(
                    child: Icon(
                      icon ?? glyphFor(swatch, theme.icons),
                      size: style.iconSize,
                      color: style.surface.foreground,
                    ),
                  ),
                ),
                SizedBox(width: style.gap),
                Expanded(
                  child: head == null
                      ? const SizedBox.shrink()
                      : DefaultTextStyle.merge(style: headStyle, child: head),
                ),
                if (onDismiss != null) ...[
                  SizedBox(width: style.gap),
                  Semantics(
                    label: theme.labels.dismiss,
                    child: Button.custom(
                      onPressed: onDismiss,
                      style: dismissStyle,
                      child: Icon(
                        theme.icons.close,
                        size: style.dismissIconSize,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (rest != null) ...[
              SizedBox(height: style.textGap),
              // Hanging off the glyph: the message reads as the title's
              // own second line rather than as something beside the icon.
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: style.iconSize + style.gap,
                ),
                child: DefaultTextStyle.merge(
                  style: style.messageStyle,
                  child: rest,
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              SizedBox(height: style.gap),
              // Finishing on the trailing edge, where a block's answers go
              // — the same row a [Dialog] ends with.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final (index, action) in actions.indexed) ...[
                    if (index > 0) SizedBox(width: style.actionGap),
                    action,
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
