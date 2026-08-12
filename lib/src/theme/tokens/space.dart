/// The spacing scale, on a 4px base.
///
/// Named the Tailwind way — `x4` is four units, not four pixels — so a gap
/// reads as a step on the scale rather than a number someone mixed by hand.
/// Off-scale spacing is a design decision, not a default; reach past these
/// only on purpose.
abstract final class Space {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;
}
