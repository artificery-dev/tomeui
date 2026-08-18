import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup radioStories() => StoryGroup(name: 'Radio', stories: [_radio()]);

Story _radio() {
  const options = ['Hardtack', 'Salt pork', 'Grog'];
  final chosen = ListKnob<String>(
    'Chosen',
    options.first,
    options: options,
  );
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
    name: 'Radio',
    knobs: [chosen, variant, swatch, disabled],
    // The knob is the group's value, so the panel and the canvas are two
    // views of one choice.
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return RadioGroup<String>(
        value: chosen.value,
        onChanged: disabled.value ? null : (value) => chosen.value = value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final option in options)
              Padding(
                padding: EdgeInsets.only(bottom: theme.space.x3),
                child: RadioButton(
                  value: option,
                  label: Text(option),
                  variant: variant.value,
                  swatch: swatch.value,
                ),
              ),
          ],
        ),
      );
    },
  );
}
