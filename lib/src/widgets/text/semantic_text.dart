import 'package:tomeui/tomeui.dart';

/// Text that knows what it is.
///
/// The shared base of the scale widgets — [DisplayText] through
/// [CaptionText]. Each subclass fixes a [TextRole]; everything else about
/// them is here: the tint a [swatch] gives, the grading an [emphasis] gives,
/// and the rule that decides the colour when neither is asked for.
///
/// That rule is the whole point of the category. A text widget with no
/// swatch resolves to a style with **no colour**, so it inherits what the
/// enclosing [Surface] speaks through [DefaultTextStyle] — which is why the
/// same [BodyText] reads dark on the page and light on a solid button
/// without either one being told a colour.
///
/// ```dart
/// const TitleText('Ship’s stores'),
/// const BodyText('Everything aboard, counted.'),
/// const CaptionText('Updated eight bells'),
/// ```
abstract class SemanticText extends StatelessWidget {
  const SemanticText(
    this.data, {
    required this.role,
    this.swatch,
    this.emphasis = TextEmphasis.full,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    super.key,
  });

  /// The words.
  final String data;

  /// Where this sits on the type scale. Fixed by the subclass.
  final TextRole role;

  /// A meaning to wear, for text that is *about* something — an error
  /// message, a success note. Null inherits the surface's foreground.
  final SemanticSwatch? swatch;

  /// How loudly to speak against that colour.
  final TextEmphasis emphasis;

  /// Last word over the resolved style, for the one-off a design needs.
  /// Merged on top, so it overrides only what it names.
  final TextStyle? style;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  /// What a screen reader says instead of [data] — an abbreviation spelled
  /// out, a number read as words.
  final String? semanticsLabel;

  /// Whether this role announces itself as a heading to assistive tech.
  /// True for the roles that structure a page, false for the rest.
  bool get isHeader => false;

  /// The last chance to change the words before they're painted —
  /// [KickerText] uppercases here.
  String transform(String data) => data;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final resolved = theme.widgets.text.resolve(
      role,
      swatch: swatch,
      emphasis: emphasis,
      // What the surrounding surface says, so emphasis grades against the
      // colour actually under the text rather than against the page's.
      on: DefaultTextStyle.of(context).style.color,
    );

    final painted = transform(data);
    final text = Text(
      painted,
      style: style == null ? resolved : resolved.merge(style),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      // A transform is a *visual* change: what's announced stays the words
      // as written, so a kicker doesn't reach the accessibility tree
      // shouting.
      semanticsLabel: semanticsLabel ?? (painted == data ? null : data),
    );
    return isHeader ? Semantics(header: true, child: text) : text;
  }
}

/// The one large statement on a screen: an empty state's headline, a number
/// worth a glance from across the room.
class DisplayText extends SemanticText {
  const DisplayText(
    super.data, {
    super.swatch,
    super.emphasis,
    super.style,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.semanticsLabel,
    super.key,
  }) : super(role: TextRole.display);

  @override
  bool get isHeader => true;
}

/// A screen or section heading.
class HeadlineText extends SemanticText {
  const HeadlineText(
    super.data, {
    super.swatch,
    super.emphasis,
    super.style,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.semanticsLabel,
    super.key,
  }) : super(role: TextRole.headline);

  @override
  bool get isHeader => true;
}

/// A card or dialog title.
class TitleText extends SemanticText {
  const TitleText(
    super.data, {
    super.swatch,
    super.emphasis,
    super.style,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.semanticsLabel,
    super.key,
  }) : super(role: TextRole.title);

  @override
  bool get isHeader => true;
}

/// The line under a title, or a list row's primary line. Not a heading —
/// a subtitle explains the heading above it rather than naming a section,
/// so it stays out of the document outline.
class SubtitleText extends SemanticText {
  const SubtitleText(
    super.data, {
    super.swatch,
    super.emphasis = TextEmphasis.secondary,
    super.style,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.semanticsLabel,
    super.key,
  }) : super(role: TextRole.subtitle);
}

/// Running text — the default for anything that is simply prose.
///
/// [BodyText.small] is the same voice where space is tight: dense lists,
/// table cells, the second line of a row.
class BodyText extends SemanticText {
  const BodyText(
    super.data, {
    super.swatch,
    super.emphasis,
    super.style,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.semanticsLabel,
    super.key,
  }) : super(role: TextRole.body);

  const BodyText.small(
    super.data, {
    super.swatch,
    super.emphasis,
    super.style,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.semanticsLabel,
    super.key,
  }) : super(role: TextRole.bodySmall);
}

/// Text that names a control — a button's word, a tab, a field's label.
class LabelText extends SemanticText {
  const LabelText(
    super.data, {
    super.swatch,
    super.emphasis,
    super.style,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.semanticsLabel,
    super.key,
  }) : super(role: TextRole.label);
}

/// Metadata: timestamps, counts, footnotes, the help line under a field.
///
/// Quiet by default — metadata at full emphasis competes with the thing
/// it's describing. Pass `emphasis: TextEmphasis.full` where it shouldn't.
class CaptionText extends SemanticText {
  const CaptionText(
    super.data, {
    super.swatch,
    super.emphasis = TextEmphasis.secondary,
    super.style,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.semanticsLabel,
    super.key,
  }) : super(role: TextRole.caption);
}
