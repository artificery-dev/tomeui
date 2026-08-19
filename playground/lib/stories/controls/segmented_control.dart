import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup segmentedControlStories() =>
    StoryGroup(name: 'SegmentedControl', stories: [_segmented()]);

const _views = ['List', 'Grid', 'Columns'];

/// Every segment wears an icon: they are all the widest one's width, so
/// the leading icons widen the row evenly rather than shuffling it about.
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
    builder: (context) {
      final icons = ThemeProvider.of(context).icons;
      final leading = [icons.sort, icons.image, icons.sidebarLeading];
      return SegmentedControl<String>(
        value: chosen.value,
        onChanged: disabled.value ? null : (value) => chosen.value = value,
        variant: variant.value,
        swatch: swatch.value,
        segments: [
          for (final (index, view) in _views.indexed)
            SegmentOption(
              value: view,
              label: Text(view),
              leading: Icon(leading[index]),
              enabled: !(disableOne.value && view == 'Grid'),
            ),
        ],
      );
    },
  );
}

