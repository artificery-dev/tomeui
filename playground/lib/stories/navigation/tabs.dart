import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup tabsStories() => StoryGroup(name: 'Tabs', stories: [_tabs()]);

const _panes = ['Log', 'Crew', 'Cargo', 'Charts', 'Soundings', 'Weather'];

Story _tabs() {
  final chosen = ListKnob<String>('Value', _panes.first, options: _panes);
  final count = DoubleKnob('Tabs', 3, min: 1, max: 6);
  final icons = BoolKnob('Leading icons', false);
  final disableOne = BoolKnob('Disable Crew', false);
  final narrow = BoolKnob('Narrow the strip', false);
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Tabs',
    knobs: [chosen, count, icons, disableOne, narrow, swatch, disabled],
    builder: (context) {
      final glyphs = ThemeProvider.of(context).icons;
      final leading = [
        glyphs.file,
        glyphs.group,
        glyphs.folder,
        glyphs.image,
        glyphs.sort,
        glyphs.info,
      ];
      final shown = _panes.take(count.value.round()).toList();

      return Center(
        child: SizedBox(
          width: narrow.value ? 260 : 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tabs<String>(
                value: shown.contains(chosen.value) ? chosen.value : null,
                onChanged: disabled.value
                    ? null
                    : (value) => chosen.value = value,
                swatch: swatch.value,
                tabs: [
                  for (final (index, pane) in shown.indexed)
                    TabOption(
                      value: pane,
                      label: Text(pane),
                      icon: icons.value ? leading[index] : null,
                      enabled: !(disableOne.value && pane == 'Crew'),
                    ),
                ],
              ),
              const Spacing(SpaceStep.x6),
              // What tabs are for: the page stays, its contents change.
              Placeholder(
                child: SizedBox(
                  height: 120,
                  child: Center(child: BodyText('${chosen.value} is showing')),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
