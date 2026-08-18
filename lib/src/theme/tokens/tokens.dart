/// The design tokens: every value the system names, and nothing that draws.
///
/// Tokens come in two shapes. The scales ([Space], [Radii], [Sizes],
/// [Strokes], [Opacities], [Motion], [Shadows], [Breakpoints], [Swatch]'s
/// palette) are static constants — fixed points a design agrees on. The
/// swappable sets ([Icons], [Typography], [Labels]) are const-constructible
/// classes whose defaults *are* the default theme, so a custom theme states
/// only its differences.
library;

export 'breakpoints.dart';
export 'icons.dart';
export 'labels.dart';
export 'motion.dart';
export 'opacities.dart';
export 'palette.dart';
export 'radii.dart';
export 'shadows.dart';
export 'sizes.dart';
export 'space.dart';
export 'strokes.dart';
export 'swatch.dart';
export 'typography.dart';
