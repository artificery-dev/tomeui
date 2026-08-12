/// The fixed dimensions the system names.
///
/// Icon sizes, control heights, and the handful of content widths that keep
/// dialogs and reading columns the same shape on every screen.
abstract final class Sizes {
  // Icons, sized to sit beside the type scale.
  static const double iconSmall = 13;
  static const double icon = 16;
  static const double iconLarge = 20;
  static const double iconExtraLarge = 24;

  // Control heights: text fields, buttons, selects.
  static const double controlCompact = 28;
  static const double control = 36;

  /// The minimum hit target on touch screens. A control may *draw* smaller
  /// than this, but what it responds to may not.
  static const double touchTarget = 44;

  // Content widths.
  static const double dialog = 520;

  /// A comfortable single reading column.
  static const double contentNarrow = 640;

  /// The widest a content region grows before it centres instead.
  static const double content = 840;
}
