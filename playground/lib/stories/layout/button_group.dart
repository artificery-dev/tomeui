import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup buttonGroupStories() =>
    StoryGroup(name: 'ButtonGroup', stories: [_buttonGroup()]);

const _actions = ['Cut', 'Copy', 'Paste', 'Delete'];

/// The seams are the point: outline is where a doubled hairline would show
/// if the run didn't share its edges, so the story opens on it.
Story _buttonGroup() {
  final count = DoubleKnob('Buttons', 3, min: 1, max: 4);
  final axis = ListKnob<Axis>(
    'Axis',
    Axis.horizontal,
    options: Axis.values,
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
  final icons = BoolKnob('Leading icons', false);
  final disableOne = BoolKnob('Disable Copy', false);
  final rtl = BoolKnob('Right to left', false);

  return Story(
    name: 'ButtonGroup',
    knobs: [count, axis, variant, swatch, icons, disableOne, rtl],
    builder: (context) {
      final glyphs = ThemeProvider.of(context).icons;
      final leading = [glyphs.edit, glyphs.copy, glyphs.paste, glyphs.delete];

      return Directionality(
        textDirection: rtl.value ? TextDirection.rtl : TextDirection.ltr,
        child: Center(
          child: ButtonGroup(
            axis: axis.value,
            children: [
              for (var i = 0; i < count.value.round(); i++)
                Button(
                  onPressed: disableOne.value && _actions[i] == 'Copy'
                      ? null
                      : () {},
                  variant: variant.value,
                  swatch: swatch.value,
                  leading: icons.value ? Icon(leading[i]) : null,
                  center: Text(_actions[i]),
                ),
            ],
          ),
        ),
      );
    },
  );
}
