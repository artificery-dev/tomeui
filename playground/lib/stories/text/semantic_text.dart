import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup semanticTextStories() =>
    StoryGroup(name: 'SemanticText', stories: [_oneLine()]);

/// One line, every dial: the role it wears, how loudly, and on what.
Story _oneLine() {
  final role = ListKnob<TextRole>(
    'Role',
    TextRole.body,
    options: TextRole.values,
    describe: (option) => option.name,
  );
  final emphasis = ListKnob<TextEmphasis>(
    'Emphasis',
    TextEmphasis.full,
    options: TextEmphasis.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch?>(
    'Swatch',
    null,
    options: [null, ...SemanticSwatch.values],
    describe: (option) => option?.name ?? 'inherit the surface',
  );
  final variant = ListKnob<SurfaceVariant>(
    'On a surface',
    SurfaceVariant.ghost,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final words = StringKnob('Words', 'Everything aboard, counted.');

  return Story(
    name: 'Text',
    knobs: [role, emphasis, swatch, variant, words],
    // Sat on a surface deliberately: the point of the category is that
    // uncolored text takes whatever the surface underneath it speaks.
    builder: (context) => Surface(
      variant: variant.value,
      padding: EdgeInsets.all(ThemeProvider.of(context).space.x4),
      child: _RoleText(
        words.value,
        role: role.value,
        emphasis: emphasis.value,
        swatch: swatch.value,
      ),
    ),
  );
}

/// The knob panel needs one widget that can wear any role; the app-facing
/// API is the named widgets — [BodyText], [TitleText], and the rest.
class _RoleText extends SemanticText {
  const _RoleText(
    super.data, {
    required super.role,
    super.emphasis,
    super.swatch,
  });
}
