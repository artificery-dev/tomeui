import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup segmentedControlStories() => StoryGroup(
  name: 'SegmentedControl',
  stories: [_segmented(), _withIcons()],
);

const _views = ['List', 'Grid', 'Columns'];

Story _segmented() {
  final chosen = ListKnob<String?>(
    'Value',
    _views.first,
    options: [null, ..._views],
    describe: (option) => option ?? 'nothing',
  );
  final disableOne = BoolKnob('Disable Grid', false);
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
    name: 'SegmentedControl',
    knobs: [chosen, disableOne, variant, swatch, disabled],
    builder: (_) => SegmentedControl<String>(
      value: chosen.value,
      onChanged: disabled.value ? null : (value) => chosen.value = value,
      variant: variant.value,
      swatch: swatch.value,
      segments: [
        for (final view in _views)
          SegmentOption(
            value: view,
            label: Text(view),
            enabled: !(disableOne.value && view == 'Grid'),
          ),
      ],
    ),
  );
}

/// Segments are the widest one's width, so an icon in one of them widens
/// all three rather than shuffling the row about.
Story _withIcons() {
  final chosen = ListKnob<String>('Value', _views.first, options: _views);

  return Story(
    name: 'With icons',
    knobs: [chosen],
    builder: (context) {
      final icons = ThemeProvider.of(context).icons;
      return SegmentedControl<String>(
        value: chosen.value,
        onChanged: (value) => chosen.value = value,
        segments: [
          SegmentOption(
            value: _views[0],
            label: Text(_views[0]),
            leading: Icon(icons.sort),
          ),
          SegmentOption(
            value: _views[1],
            label: Text(_views[1]),
            leading: Icon(icons.image),
          ),
          SegmentOption(
            value: _views[2],
            label: Text(_views[2]),
            leading: Icon(icons.sidebarLeading),
          ),
        ],
      );
    },
  );
}
