import 'dart:async';

import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// A path, an identifier, a command — monospace on a quiet chip, with the
/// copy affordance beside it.
///
/// Code in an interface is nearly always code someone is about to paste
/// somewhere, so copying is part of the widget rather than something an app
/// bolts on. The button confirms with the check glyph and goes back to
/// offering the copy a moment later.
///
/// ```dart
/// const CodeText('flutter pub add tomeui'),
/// const CodeText('~/.config/tome.yaml', copyable: false),
/// ```
class CodeText extends StatelessWidget {
  const CodeText(
    this.data, {
    this.copyable = true,
    this.swatch = SemanticSwatch.neutral,
    this.maxLines,
    this.overflow,
    this.copyLabel,
    this.copiedLabel,
    super.key,
  }) : style = null;

  /// Custom everything: paints [style] exactly as given, resolving nothing.
  const CodeText.custom(
    this.data, {
    required CodeTextStyle this.style,
    this.copyable = true,
    this.maxLines,
    this.overflow,
    this.copyLabel,
    this.copiedLabel,
    super.key,
  }) : swatch = SemanticSwatch.neutral;

  /// The code, verbatim — and exactly what lands on the clipboard.
  final String data;

  /// Whether the copy button is there at all. Off for code that's shown to
  /// be read rather than taken.
  final bool copyable;

  /// The meaning to wear — neutral by default: a path is not a status.
  final SemanticSwatch swatch;

  final int? maxLines;
  final TextOverflow? overflow;

  /// What assistive tech calls the copy button, before and after the copy.
  /// Null takes the theme's [Labels] — which is where an app that speaks
  /// another language changes them once for the whole toolkit.
  final String? copyLabel;
  final String? copiedLabel;

  /// The style to paint, bypassing the theme — set by [CodeText.custom].
  final CodeTextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.code.resolve(swatch);

    return Surface.custom(
      style: style.surface,
      padding: style.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flexible, not Expanded: the chip hugs short code and lets long
          // code elide inside whatever width it's given.
          Flexible(
            child: Text(
              data,
              style: style.textStyle,
              maxLines: maxLines,
              overflow: overflow,
            ),
          ),
          if (copyable) ...[
            SizedBox(width: style.gap),
            _CopyButton(
              data: data,
              style: style,
              copyLabel: copyLabel ?? theme.labels.copy,
              copiedLabel: copiedLabel ?? theme.labels.copied,
            ),
          ],
        ],
      ),
    );
  }
}

/// The copy affordance: one glyph that becomes a check for a moment.
class _CopyButton extends StatefulWidget {
  const _CopyButton({
    required this.data,
    required this.style,
    required this.copyLabel,
    required this.copiedLabel,
  });

  final String data;
  final CodeTextStyle style;
  final String copyLabel;
  final String copiedLabel;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;
  Timer? _confirming;

  @override
  void dispose() {
    _confirming?.cancel();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.data));
    setState(() => _copied = true);
    // Copying again while the check is up restarts the moment rather than
    // letting the first timer cut the second confirmation short.
    _confirming?.cancel();
    _confirming = Timer(widget.style.confirmFor, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style;

    return Semantics(
      button: true,
      label: _copied ? widget.copiedLabel : widget.copyLabel,
      child: Interactive(
        onActivate: _copy,
        ring: style.ring,
        ringRadius: theme.radii.small,
        hover: style.hover,
        pressed: style.pressed,
        disabledOpacity: style.disabledOpacity,
        builder: (context, state) => Surface.custom(
          style: SurfaceStyle(
            foreground: style.surface.foreground,
            fill: state.wash,
            radius: theme.radii.small,
          ),
          padding: EdgeInsets.all(theme.space.x1 / 2),
          child: Icon(
            _copied ? theme.icons.confirm : theme.icons.copy,
            size: style.iconSize,
          ),
        ),
      ),
    );
  }
}
