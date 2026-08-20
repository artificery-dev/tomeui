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
/// screen is the [action]. Centred in whatever it's given, and its words
/// wrap at a readable measure rather than running the width of the slot.
class EmptyState extends StatelessWidget {
  const EmptyState({
    this.title,
    this.message,
    this.icon,
    this.illustration,
    this.action,
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

  /// The style to paint, bypassing the theme.
  final EmptyStateStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.emptyState.resolve();

    return Semantics(
      container: true,
      child: Center(
        child: Padding(
          padding: style.padding,
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
      ),
    );
  }
}
