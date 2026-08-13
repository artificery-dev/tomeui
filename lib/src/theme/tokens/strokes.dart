import 'package:flutter/widgets.dart';

/// The stroke widths.
///
/// Nearly everything drawn with a line uses [hairline]; a wider stroke is a
/// meaning, not a style — [focus] marks the focused control and nothing else.
@immutable
class Strokes {
  const Strokes({this.hairline = 1, this.focus = 2});

  /// Borders, dividers, outlines.
  final double hairline;

  /// The ring around whatever has keyboard focus.
  final double focus;

  Strokes copyWith({double? hairline, double? focus}) =>
      Strokes(hairline: hairline ?? this.hairline, focus: focus ?? this.focus);

  @override
  bool operator ==(Object other) =>
      other is Strokes && other.hairline == hairline && other.focus == focus;

  @override
  int get hashCode => Object.hash(hairline, focus);
}
