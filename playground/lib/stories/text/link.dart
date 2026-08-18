import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup linkStories() => StoryGroup(name: 'Link', stories: [_link()]);

Story _link() {
  final role = ListKnob<TextRole>(
    'Role',
    TextRole.body,
    options: TextRole.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final underline = ListKnob<LinkUnderline>(
    'Underline',
    LinkUnderline.hover,
    options: LinkUnderline.values,
    describe: (option) => option.name,
  );
  final external = BoolKnob('External', false);
  final disabled = BoolKnob('Disabled', false);
  final words = StringKnob('Words', 'the manifest');

  return Story(
    name: 'Link',
    knobs: [role, swatch, underline, external, disabled, words],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Link(
            words.value,
            role: role.value,
            swatch: swatch.value,
            underline: underline.value,
            external: external.value,
            onPressed: disabled.value ? null : () {},
          ),
          SizedBox(height: theme.space.x4),
          // Beside its own size of body text, to check it sits on the line.
          const BodyText('A link takes the type of the words around it.'),
        ],
      );
    },
  );
}
