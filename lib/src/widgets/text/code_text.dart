import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// Code, in one of two shapes.
///
/// **Inline** is a path, an identifier, a command — monospace on a quiet
/// chip, with the copy affordance beside it. Code in an interface is nearly
/// always code someone is about to paste somewhere, so copying is part of
/// the widget rather than something an app bolts on. The button confirms
/// with the check glyph and goes back to offering the copy a moment later.
///
/// ```dart
/// const CodeText('flutter pub add tomeui'),
/// const CodeText('~/.config/tome.yaml', copyable: false),
/// ```
///
/// **Block** is a listing: a card, a numbered gutter, and syntax coloured
/// in the palette's own voice rather than in a scheme borrowed from an
/// editor. Long lines scroll sideways under a gutter that stays put, unless
/// [wrap] says to fold them instead.
///
/// ```dart
/// CodeText.block(source, language: 'dart', highlightLines: const {12}),
/// ```
///
/// Colour comes from [CodeSyntax], which knows every grammar
/// `re_highlight` ships — so [language] is usually the only thing to say.
/// A block naming one it doesn't know still gets its card, its numbers,
/// and its copy button; only the colour is missing.
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
  }) : style = null,
       block = false,
       language = null,
       lineNumbers = false,
       firstLine = 1,
       highlightLines = const {},
       wrap = false;

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
  }) : swatch = SemanticSwatch.neutral,
       block = false,
       language = null,
       lineNumbers = false,
       firstLine = 1,
       highlightLines = const {},
       wrap = false;

  /// A listing rather than a chip: a card, a gutter, and colour.
  ///
  /// [maxLines] and [overflow] are absent by design — they are questions
  /// about eliding a line, and a block's answer to a long line is to
  /// scroll it or to [wrap] it.
  const CodeText.block(
    this.data, {
    this.language,
    this.lineNumbers = true,
    this.firstLine = 1,
    this.highlightLines = const {},
    this.wrap = false,
    this.copyable = true,
    this.swatch = SemanticSwatch.neutral,
    this.style,
    this.copyLabel,
    this.copiedLabel,
    super.key,
  }) : block = true,
       maxLines = null,
       overflow = null;

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

  /// The style to paint, bypassing the theme — set by [CodeText.custom],
  /// and available directly on [CodeText.block].
  final CodeTextStyle? style;

  /// Whether this is the block shape. Set by [CodeText.block].
  final bool block;

  /// What to colour the code as — a name [CodeSyntax] knows, or one of the
  /// aliases its grammars declare (`js`, `yml`, `sh`). Null, or a name
  /// nobody registered, leaves the code plain.
  final String? language;

  /// Whether the gutter counts the lines.
  final bool lineNumbers;

  /// What the first line is called. A block quoting the middle of a file
  /// numbers from where the excerpt starts rather than from one.
  final int firstLine;

  /// Lines to call out, in the same numbering [firstLine] sets — so the
  /// numbers in the gutter are the numbers to name here.
  final Set<int> highlightLines;

  /// Fold long lines instead of scrolling them. Off by default: code means
  /// something by where it breaks, and folding it says a break is there
  /// that isn't.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.code.resolve(swatch);
    return block ? _block(context, theme, style) : _inline(theme, style);
  }

  Widget _inline(Theme theme, CodeTextStyle style) {
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

  Widget _block(BuildContext context, Theme theme, CodeTextStyle style) {
    // One trailing newline is how a heredoc ends, not a blank last line.
    final source = data.endsWith('\n')
        ? data.substring(0, data.length - 1)
        : data;
    final lines = _lines(source, style);

    // Measured, not guessed: the numbers are right-aligned in a column of
    // one width, and the widest number is the last one.
    final gutterWidth = lineNumbers
        ? _measure(
            '${firstLine + lines.length - 1}',
            style.gutterStyle,
            MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
          )
        : 0.0;

    Widget listing = wrap
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < lines.length; i++)
                _row(
                  style,
                  i,
                  gutterWidth,
                  // Expanded so the fold happens at the card's edge.
                  Expanded(child: _code(lines[i], style)),
                ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lineNumbers)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      _wash(style, i, _gutter(style, i, gutterWidth)),
                  ],
                ),
              // The gutter stays put and only the code slides, which is the
              // whole point of keeping them in separate columns.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // Tight width from the widest line, so a called-out
                  // line's wash runs the full listing rather than stopping
                  // where its own text does.
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < lines.length; i++)
                          _wash(style, i, _code(lines[i], style)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );

    if (copyable) {
      listing = Stack(
        children: [
          listing,
          PositionedDirectional(
            top: 0,
            end: 0,
            child: _CopyButton(
              data: data,
              style: style,
              copyLabel: copyLabel ?? theme.labels.copy,
              copiedLabel: copiedLabel ?? theme.labels.copied,
            ),
          ),
        ],
      );
    }

    return Surface.custom(
      style: style.block,
      padding: style.blockPadding,
      child: listing,
    );
  }

  /// One line of the folding layout: gutter and code in the same row, so
  /// a line that folds to three takes its number with it.
  Widget _row(
    CodeTextStyle style,
    int index,
    double gutterWidth,
    Widget code,
  ) => _wash(
    style,
    index,
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lineNumbers) _gutter(style, index, gutterWidth),
        code,
      ],
    ),
  );

  /// The wash behind a called-out line.
  Widget _wash(CodeTextStyle style, int index, Widget child) =>
      highlightLines.contains(firstLine + index)
      ? ColoredBox(color: style.lineHighlight, child: child)
      : child;

  /// Half the gap on each side of the rule, so the numbers and the code
  /// stand off it equally. The far half is [_code]'s, so that a called-out
  /// line's wash crosses the rule unbroken.
  Widget _gutter(CodeTextStyle style, int index, double width) => Container(
    width: width + style.gutterGap / 2,
    padding: EdgeInsetsDirectional.only(end: style.gutterGap / 2),
    decoration: BoxDecoration(
      border: BorderDirectional(end: BorderSide(color: style.gutterDivider)),
    ),
    alignment: AlignmentDirectional.topEnd,
    child: Text('${firstLine + index}', style: style.gutterStyle),
  );

  Widget _code(TextSpan line, CodeTextStyle style) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: lineNumbers ? style.gutterGap / 2 : 0,
    ),
    child: Text.rich(
      line,
      style: style.textStyle,
      softWrap: wrap,
      // Clipped rather than ellipsised: what's off the right of a listing
      // is reached by scrolling to it, not summarised with a dot.
      overflow: TextOverflow.clip,
    ),
  );

  /// The code as one span per line.
  ///
  /// Highlighted whole and *then* split, never line by line: a block
  /// comment or a triple-quoted string is one construct, and a tokenizer
  /// shown a single line out of it would call the rest of the file code.
  List<TextSpan> _lines(String source, CodeTextStyle style) {
    final base = style.textStyle;
    final highlighted = CodeSyntax.highlight(
      source,
      language: language,
      base: base,
      syntax: style.syntax,
    );
    if (highlighted == null) {
      return [
        for (final line in source.split('\n')) TextSpan(text: line, style: base),
      ];
    }

    final lines = <List<InlineSpan>>[[]];
    void walk(InlineSpan span, TextStyle? inherited) {
      if (span is! TextSpan) return;
      final style = span.style == null
          ? inherited
          : inherited?.merge(span.style) ?? span.style;
      // A span's own text comes before its children — walking them the
      // other way round would reorder the source.
      final text = span.text;
      if (text != null && text.isNotEmpty) {
        final parts = text.split('\n');
        for (var i = 0; i < parts.length; i++) {
          if (i > 0) lines.add([]);
          if (parts[i].isNotEmpty) {
            lines.last.add(TextSpan(text: parts[i], style: style));
          }
        }
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        walk(child, style);
      }
    }

    walk(highlighted, base);
    return [
      for (final line in lines) TextSpan(children: line, style: base),
    ];
  }

  /// How wide [text] lays out — the gutter's width, and the one thing here
  /// that can't be answered by layout alone.
  static double _measure(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    // Never narrower than a digit: a gutter that collapsed would put the
    // rule through the numbers.
    return math.max(width, 0);
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
