import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup switchStories() =>
    StoryGroup(name: 'Switch', stories: [_standalone(), _grouped()]);

Story _standalone() {
  final on = BoolKnob('On', true);
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
    name: 'Standalone',
    knobs: [on, variant, swatch, disabled],
    // The lambda's type is spelled out because a ternary gives inference
    // nothing to read T from on the null branch.
    builder: (_) => Switch(
      value: on.value,
      onChanged: disabled.value ? null : (bool value) => on.value = value,
      label: const Text('Light the lantern'),
      variant: variant.value,
      swatch: swatch.value,
    ),
  );
}

/// The same widget, exclusive: a SwitchGroup above makes each switch one of
/// several rather than its own yes or no.
Story _grouped() {
  const watches = ['Morning', 'Forenoon', 'Dog'];
  final chosen = ListKnob<String>('On watch', watches.first, options: watches);
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
    name: 'In a group',
    knobs: [chosen, variant, swatch, disabled],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return SwitchGroup<String>(
        value: chosen.value,
        onChanged: disabled.value ? null : (value) => chosen.value = value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final watch in watches)
              Padding(
                padding: EdgeInsets.only(bottom: theme.space.x3),
                child: Switch(
                  value: watch,
                  label: Text(watch),
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
