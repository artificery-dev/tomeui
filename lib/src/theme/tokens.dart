/// The design tokens: every value the system names, and nothing that draws.
///
/// Tokens come in two shapes. The scales ([Space], [Radii], [Sizes],
/// [Strokes], [Opacities], [Motion], [Shadows], [Breakpoints], [Swatch]'s
/// palette) are static constants — fixed points a design agrees on. The
/// swappable sets ([TomeIcons], [TomeTypography]) are const-constructible
/// classes whose defaults *are* the default theme, so a custom theme states
/// only its differences.
library;

export 'tokens/breakpoints.dart';
export 'tokens/icons.dart';
export 'tokens/motion.dart';
export 'tokens/opacities.dart';
export 'tokens/radii.dart';
export 'tokens/shadows.dart';
export 'tokens/sizes.dart';
export 'tokens/space.dart';
export 'tokens/strokes.dart';
export 'tokens/swatch.dart';
export 'tokens/typography.dart';
