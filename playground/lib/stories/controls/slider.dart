import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup sliderStories() =>
    StoryGroup(name: 'Slider', stories: [_slider()]);

Story _slider() {
  final value = DoubleKnob('Value', 40, max: 100);
  final divisions = DoubleKnob('Divisions (0 is continuous)', 0, max: 10);
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.solid,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Slider',
    knobs: [value, divisions, variant, swatch, disabled],
    // The value knob is two-way: dragging the thumb moves the panel's own
    // slider, and vice versa.
    builder: (context) {
      final stops = divisions.value.round();
      return SizedBox(
        width: 320,
        child: Slider(
          value: value.value,
          max: 100,
          divisions: stops == 0 ? null : stops,
          onChanged: disabled.value ? null : (next) => value.value = next,
          variant: variant.value,
          swatch: swatch.value,
          semanticFormatter: (v) => '${v.round()} per cent',
        ),
      );
    },
  );
}
