import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup switchStories() => StoryGroup(name: 'Switch', stories: [_switch()]);

const _watches = ['Morning', 'Forenoon', 'Dog'];

/// Three switches, `Grouped` saying what they mean: on their own each is its
/// own yes or no and all three can be lit, and under a SwitchGroup they
/// become one choice of several, only ever one of them on.
Story _switch() {
  final grouped = BoolKnob('Grouped', false);
  final lit = [
    for (final watch in _watches) BoolKnob(watch, watch == _watches.first),
  ];
  final chosen = ListKnob<String>('On watch', _watches.first, options: _watches);
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
    name: 'Switch',
    knobs: [grouped, ...lit, chosen, variant, swatch, disabled],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      final column = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, watch) in _watches.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: theme.space.x3),
              child: grouped.value
                  // Grouped, the value is what turning this one on means,
                  // and the group above hears about the flip.
                  ? Switch(
                      value: watch,
                      label: Text(watch),
                      variant: variant.value,
                      swatch: swatch.value,
                    )
                  // The lambda's type is spelled out because a ternary gives
                  // inference nothing to read T from on the null branch.
                  : Switch(
                      value: lit[index].value,
                      onChanged: disabled.value
                          ? null
                          : (bool value) => lit[index].value = value,
                      label: Text(watch),
                      variant: variant.value,
                      swatch: swatch.value,
                    ),
            ),
        ],
      );

      if (!grouped.value) return column;
      return SwitchGroup<String>(
        value: chosen.value,
        onChanged: disabled.value ? null : (value) => chosen.value = value,
        child: column,
      );
    },
  );
}
