import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup buttonStories() => StoryGroup(name: 'Button', stories: [_button()]);

Story _button() {
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
  final label = StringKnob('Label', 'Save changes');
  final leading = BoolKnob('Leading icon', false);
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Button',
    knobs: [variant, swatch, label, leading, disabled],
    builder: (context) => Button(
      onPressed: disabled.value ? null : () {},
      variant: variant.value,
      swatch: swatch.value,
      leading: leading.value
          ? Icon(ThemeProvider.of(context).icons.info)
          : null,
      center: Text(label.value),
    ),
  );
}
