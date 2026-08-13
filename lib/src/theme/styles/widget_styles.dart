import 'package:tomeui/tomeui.dart';

/// The per-widget style configuration a [Theme] carries: pure data, one
/// field per widget the system knows how to dress.
///
/// This is the *input* side of the style system — tone mappings and, later,
/// per-widget geometry. The output side is [Widgets], the resolver bundle
/// at `theme.widgets`, which reads this configuration against the palette.
@immutable
class WidgetStyles {
  const WidgetStyles({this.surface = const SurfaceStyles()});

  final SurfaceStyles surface;

  WidgetStyles copyWith({SurfaceStyles? surface}) =>
      WidgetStyles(surface: surface ?? this.surface);

  @override
  bool operator ==(Object other) =>
      other is WidgetStyles && other.surface == surface;

  @override
  int get hashCode => surface.hashCode;
}
