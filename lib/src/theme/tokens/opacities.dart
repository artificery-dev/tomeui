/// The opacity steps.
///
/// Two families in one scale. The emphasis steps ([secondary], [tertiary],
/// [disabled]) grade text and icons against their surface; the overlay steps
/// ([hover] through [scrim]) are laid *over* a surface in its own foreground
/// colour to show interaction state, so the same numbers work on any palette.
abstract final class Opacities {
  // Emphasis, applied to a foreground colour.
  static const double secondary = 0.72;
  static const double tertiary = 0.55;
  static const double disabled = 0.38;

  // Interaction overlays, foreground over surface.
  static const double hover = 0.06;
  static const double pressed = 0.10;
  static const double focus = 0.12;
  static const double dragged = 0.16;

  /// A divider drawn in the foreground colour rather than a dedicated hue.
  static const double divider = 0.12;

  /// The veil behind a dialog or sheet.
  static const double scrim = 0.5;
}
