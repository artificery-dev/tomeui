import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

/// The striped stand-in, bounded and unbounded.
StoryGroup placeholderStories() =>
    StoryGroup(name: 'Placeholder', stories: [_placeholder()]);

Story _placeholder() {
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.neutral,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final label = StringKnob('Label', 'Drop here');
  final bounded = BoolKnob('Fill a 320×200 box', true);
  final padding = DoubleKnob('Padding', 12, max: 48);

  return Story(
    name: 'Placeholder',
    knobs: [swatch, label, bounded, padding],
    builder: (_) {
      final placeholder = Placeholder(
        swatch: swatch.value,
        padding: EdgeInsets.all(padding.value),
        child: Text(label.value),
      );
      // Bounded shows the tight-constraints fill; unbounded shows the hug.
      return bounded.value
          ? SizedBox(width: 320, height: 200, child: placeholder)
          : placeholder;
    },
  );
}
