import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup selectStories() => StoryGroup(name: 'Select', stories: [_select()]);

const _watches = ['Morning', 'Forenoon', 'Afternoon', 'Dog', 'First'];

Story _select() {
  final chosen = ListKnob<String?>(
    'Value',
    null,
    options: [null, ..._watches],
    describe: (option) => option ?? 'nothing',
  );
  final side = ListKnob<PopoverSide>(
    'Side',
    PopoverSide.bottom,
    options: PopoverSide.values,
    describe: (option) => option.name,
  );
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.outline,
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
    name: 'Select',
    knobs: [chosen, side, variant, swatch, disabled],
    builder: (_) => Select<String>(
      value: chosen.value,
      side: side.value,
      variant: variant.value,
      swatch: swatch.value,
      placeholder: const Text('Pick a watch'),
      onChanged: disabled.value
          ? null
          : (String value) => chosen.value = value,
      options: [
        for (final watch in _watches)
          SelectOption(value: watch, label: Text(watch)),
      ],
    ),
  );
}

