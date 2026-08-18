import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup codeTextStories() =>
    StoryGroup(name: 'CodeText', stories: [_codeText()]);

Story _codeText() {
  final code = StringKnob('Code', 'flutter pub add tomeui');
  final copyable = BoolKnob('Copyable', true);
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.neutral,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'CodeText',
    knobs: [code, copyable, swatch],
    builder: (_) => CodeText(
      code.value,
      copyable: copyable.value,
      swatch: swatch.value,
    ),
  );
}
