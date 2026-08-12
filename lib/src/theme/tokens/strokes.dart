/// The stroke widths.
///
/// Nearly everything drawn with a line uses [hairline]; a wider stroke is a
/// meaning, not a style — [focus] marks the focused control and nothing else.
abstract final class Strokes {
  /// Borders, dividers, outlines.
  static const double hairline = 1;

  /// The ring around whatever has keyboard focus.
  static const double focus = 2;
}
