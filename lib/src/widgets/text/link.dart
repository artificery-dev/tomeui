import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// Text that goes somewhere.
///
/// Wears the swatch at its link stop, brightens under the pointer, and takes
/// a focus ring like any other control — a link is a control that happens to
/// be made of words. The underline follows [LinkUnderline]: on hover by
/// default, since colour already marks it and a page of underlines reads as
/// a ransom note.
///
/// [role] is which type it sits in, not how loud it is: a link inside a
/// caption should say `role: TextRole.caption` so it matches the words
/// around it.
///
/// ```dart
/// Link('the manifest', onPressed: () => go('/manifest')),
/// Link('Lloyd’s register', external: true, onPressed: openInBrowser),
/// ```
class Link extends StatelessWidget {
  const Link(
    this.data, {
    required this.onPressed,
    this.role = TextRole.body,
    this.swatch = SemanticSwatch.primary,
    this.external = false,
    this.underline,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
    super.key,
  }) : style = null;

  /// Custom everything: paints [style] exactly as given, resolving nothing.
  const Link.custom(
    this.data, {
    required this.onPressed,
    required LinkStyle this.style,
    this.external = false,
    this.underline,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
    super.key,
  }) : role = TextRole.body,
       swatch = SemanticSwatch.primary;

  /// The words that are the link.
  final String data;

  /// Where following it leads. Null disables the link: it dims, ignores the
  /// pointer, and leaves the focus order.
  final VoidCallback? onPressed;

  /// The type the link sits in — match it to the text around it.
  final TextRole role;

  /// The meaning to wear — the palette says which colour that is.
  final SemanticSwatch swatch;

  /// Marks a link that leaves: the external-link glyph rides the last line,
  /// so wrapping never strands it on its own.
  final bool external;

  /// Overrides the theme's underline rule for this one link.
  final LinkUnderline? underline;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticsLabel;

  /// The style to paint, bypassing the theme — set only by [Link.custom].
  final LinkStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.link.resolve(swatch, role);
    final rule = underline ?? style.underline;

    return Semantics(
      link: true,
      child: Interactive(
        onActivate: onPressed,
        ring: style.ring,
        ringRadius: style.ringRadius,
        disabledOpacity: style.disabledOpacity,
        builder: (context, state) {
          // Focus counts as hover here: a keyboard user gets the same
          // brightening and the same underline the pointer would give.
          final lit = state.hovered || state.focused;
          final base = lit ? style.hovered : style.textStyle;
          final underlined =
              rule == LinkUnderline.always ||
              (rule == LinkUnderline.hover && lit);
          final text = base.copyWith(
            decoration: underlined
                ? TextDecoration.underline
                : TextDecoration.none,
            // Without this the underline inherits the ambient decoration
            // colour, which is the *page's* text, not the link's.
            decorationColor: base.color,
          );

          return Text.rich(
            TextSpan(
              children: [
                TextSpan(text: data),
                if (external)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: style.gap),
                      child: Icon(
                        theme.icons.externalLink,
                        size: style.iconSize,
                        color: text.color,
                      ),
                    ),
                  ),
              ],
            ),
            style: text,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
            semanticsLabel: semanticsLabel,
          );
        },
      ),
    );
  }
}
