/// Tome UI: a Flutter UI toolkit built directly on the widgets layer.
///
/// Standalone from material and cupertino: the only Flutter surface this
/// package touches is `flutter/widgets.dart`, re-exported here so that a
/// single `import 'package:tomeui/tomeui.dart';` covers both the toolkit and
/// the widgets layer beneath it.
library;

// Ours shadow Flutter's — see the rulings in PLANNING.md.
export 'package:flutter/widgets.dart' hide Placeholder, RadioGroup;

// The default glyph set behind the [Icons] tokens, exported whole so an app
// can reach glyphs beyond the semantic tokens ([LucideIcons.music]) without
// taking on a second dependency.
export 'package:lucide_icons_flutter/lucide_icons.dart';

export 'src/routing/routing.dart';
export 'src/theme/theme.dart';
export 'src/widgets/widgets.dart';
