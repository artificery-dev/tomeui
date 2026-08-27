import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup tabsStories() => StoryGroup(name: 'Tabs', stories: [_tabs()]);

const _panes = ['Log', 'Crew', 'Cargo', 'Charts', 'Soundings', 'Weather'];

Story _tabs() {
  final chosen = ListKnob<String>('Value', _panes.first, options: _panes);
  final count = DoubleKnob('Tabs', 3, min: 1, max: 6);
  final icons = BoolKnob('Leading icons', true);
  final closable = BoolKnob('Closable', true);
  final shut = ListKnob<String>('Shut', '—', options: ['—', ..._panes]);
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
    knobs: [
      chosen,
      count,
      icons,
      closable,
      shut,
      disableOne,
      narrow,
      swatch,
      disabled,
    ],
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
      final shown = _panes
          .take(count.value.round())
          .where((pane) => pane != shut.value)
          .toList();

      return Center(
        child: SizedBox(
          width: narrow.value ? 260 : 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tabs<String>(
                value: shown.contains(chosen.value) ? chosen.value : null,
                onChanged: disabled.value
                    ? null
                    : (value) => chosen.value = value,
                swatch: swatch.value,
                tabs: [
                  for (final pane in shown)
                    TabOption(
                      value: pane,
                      label: Text(pane),
                      icon: icons.value ? leading[_panes.indexOf(pane)] : null,
                      // The knob stands in for a list the app would keep:
                      // shutting a tab takes it off the strip.
                      onClose: closable.value ? () => shut.value = pane : null,
                      enabled: !(disableOne.value && pane == 'Crew'),
                    ),
                ],
              ),
              // Hard against the strip: a tab is the top edge of the pane
              // it opens onto, and daylight between the two makes it a row
              // of buttons instead.
              Expanded(
                child: Placeholder(
                  child: BodyText('${chosen.value} is showing'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
