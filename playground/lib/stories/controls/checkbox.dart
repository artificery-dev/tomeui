import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup checkboxStories() =>
    StoryGroup(name: 'Checkbox', stories: [_checkbox()]);

Story _checkbox() {
  final checked = BoolKnob('Checked', true);
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
    name: 'Checkbox',
    knobs: [checked, variant, swatch, disabled],
    // The value knob is two-way: clicking the canvas checkbox moves the
    // switch in the panel, and vice versa.
    builder: (_) => Checkbox(
      value: checked.value,
      onChanged: disabled.value ? null : (value) => checked.value = value,
      label: const Text('Ship the biscuit ration'),
      variant: variant.value,
      swatch: swatch.value,
    ),
  );
}
