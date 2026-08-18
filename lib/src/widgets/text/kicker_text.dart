import 'package:tomeui/tomeui.dart';

/// The small spaced uppercase line that names a section without being a
/// heading — "ACCOUNT", "DANGER ZONE", the label over a group of fields.
///
/// Uppercasing happens at paint time, not in the caller's string: the words
/// stay sentence case in code and in what a screen reader announces, so a
/// kicker never turns into shouting in the accessibility tree. Pass
/// [semanticsLabel] to say something else entirely.
///
/// Quiet by default — a kicker introduces content rather than competing
/// with it.
class KickerText extends SemanticText {
  const KickerText(
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
  }) : super(role: TextRole.kicker);

  @override
  String transform(String data) => data.toUpperCase();
}
