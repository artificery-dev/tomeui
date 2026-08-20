import 'package:tomeui/tomeui.dart';

/// The resolved values a [Card] paints and lays out by. The choosing
/// happened in [CardResolver], at `theme.widgets.card`.
@immutable
class CardStyle {
  const CardStyle({required this.surface, this.spacing = 16});

  /// The card itself: fill, border, corners, and the foreground its
  /// contents speak.
  final SurfaceStyle surface;

  /// The daylight a slot keeps around itself — between it and its
  /// neighbours, and between it and the card's edge. A slot overrides it
  /// with a step of its own, zero meaning full bleed.
  final double spacing;

  CardStyle copyWith({SurfaceStyle? surface, double? spacing}) => CardStyle(
    surface: surface ?? this.surface,
    spacing: spacing ?? this.spacing,
  );

  @override
  bool operator ==(Object other) =>
      other is CardStyle &&
      other.surface == surface &&
      other.spacing == spacing;

  @override
  int get hashCode => Object.hash(surface, spacing);
}
