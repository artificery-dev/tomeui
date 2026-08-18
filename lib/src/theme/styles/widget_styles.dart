import 'package:tomeui/tomeui.dart';

/// The per-widget style configuration a [Theme] carries: pure data, one
/// field per widget the system knows how to dress.
///
/// This is the *input* side of the style system — tone mappings and, later,
/// per-widget geometry. The output side is [Widgets], the resolver bundle
/// at `theme.widgets`, which reads this configuration against the palette.
@immutable
class WidgetStyles {
  const WidgetStyles({
    this.surface = const SurfaceStyles(),
    this.text = const TextStyles(),
  });

  final SurfaceStyles surface;

  final TextStyles text;

  WidgetStyles copyWith({SurfaceStyles? surface, TextStyles? text}) =>
      WidgetStyles(surface: surface ?? this.surface, text: text ?? this.text);

  @override
  bool operator ==(Object other) =>
      other is WidgetStyles && other.surface == surface && other.text == text;

  @override
  int get hashCode => Object.hash(surface, text);
}
