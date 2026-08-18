/// Tome UI: a Flutter UI toolkit built directly on the widgets layer.
///
/// Standalone from material and cupertino: the only Flutter surface this
/// package touches is `flutter/widgets.dart`, re-exported here so that a
/// single `import 'package:tomeui/tomeui.dart';` covers both the toolkit and
/// the widgets layer beneath it.
library;

// Ours shadows Flutter's Placeholder — see the rulings in PLANNING.md.
export 'package:flutter/widgets.dart' hide Placeholder;

export 'src/routing/routing.dart';
export 'src/theme/theme.dart';
export 'src/widgets/widgets.dart';
