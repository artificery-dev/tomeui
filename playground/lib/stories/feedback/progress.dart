import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup progressStories() =>
    StoryGroup(name: 'Progress', stories: [_progress()]);

/// Both shapes at once, and the knob that matters most: a value, or none at
/// all — the difference between measuring and merely waiting.
Story _progress() {
  final known = BoolKnob('Length known', true);
  final value = DoubleKnob('Value', 0.4);
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final width = DoubleKnob('Bar width', 320, min: 80, max: 640);

  return Story(
    name: 'Progress',
    knobs: [known, value, swatch, width],
    builder: (context) {
      final measured = known.value ? value.value : null;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KickerText('Bar'),
            const Spacing(SpaceStep.x3),
            SizedBox(
              width: width.value,
              child: Progress.bar(value: measured, swatch: swatch.value),
            ),
            const Spacing(SpaceStep.x8),
            const KickerText('Spinner'),
            const Spacing(SpaceStep.x3),
            Progress.spinner(value: measured, swatch: swatch.value),
            const Spacing(SpaceStep.x8),
            // Where a spinner earns its keep: inside something else — and
            // where it would drown, since a button wearing the same swatch
            // is the very colour the spinner would paint itself.
            Button(
              onPressed: () {},
              swatch: swatch.value,
              leading: Progress.spinner(value: measured, swatch: swatch.value),
              center: const Text('Signing…'),
            ),
          ],
        ),
      );
    },
  );
}
