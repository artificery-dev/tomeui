import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup selectStories() =>
    StoryGroup(name: 'Select', stories: [_select(), _scrolling()]);

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

/// Proof the open list follows its trigger: scroll the canvas with the list
/// down, and the panel rides along until the trigger leaves the view.
Story _scrolling() {
  final chosen = ListKnob<String?>(
    'Value',
    _watches.first,
    options: [null, ..._watches],
    describe: (option) => option ?? 'nothing',
  );

  return Story(
    name: 'In a scroll view',
    knobs: [chosen],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      // Placeholders hug their child under a ListView's loose constraints,
      // so the fillers say how tall they are — enough of them to actually
      // push the select up and off the top.
      Widget filler(int n) => Padding(
        padding: EdgeInsets.only(bottom: theme.space.x4),
        child: SizedBox(
          height: 180,
          child: Placeholder(child: Text('Filler $n')),
        ),
      );

      return ListView(
        padding: EdgeInsets.all(theme.space.x6),
        children: [
          for (var i = 1; i <= 3; i++) filler(i),
          Select<String>(
            value: chosen.value,
            placeholder: const Text('Pick a watch'),
            onChanged: (String value) => chosen.value = value,
            options: [
              for (final watch in _watches)
                SelectOption(value: watch, label: Text(watch)),
            ],
          ),
          SizedBox(height: theme.space.x4),
          for (var i = 4; i <= 9; i++) filler(i),
        ],
      );
    },
  );
}
