import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup dockStories() => StoryGroup(name: 'Dock', stories: [_dock()]);

const _sections = ['Home', 'Crew', 'Cargo', 'Charts', 'Log', 'Weather'];

/// Narrow the run and watch the tail fold into *More*: the dock never
/// scrolls, so what doesn't fit goes behind one button.
Story _dock() {
  final chosen = ListKnob<String>('Value', _sections.first, options: _sections);
  final count = DoubleKnob('Destinations', 4, min: 1, max: 6);
  final axis = ListKnob<Axis>(
    'Axis',
    Axis.horizontal,
    options: Axis.values,
    describe: (option) =>
        option == Axis.horizontal ? 'horizontal — bottom bar' : 'vertical — rail',
  );
  final run = DoubleKnob('Room along the run', 480, min: 120, max: 720);
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Dock',
    knobs: [chosen, count, axis, run, swatch, disabled],
    builder: (context) {
      final glyphs = ThemeProvider.of(context).icons;
      final icons = [
        glyphs.home,
        glyphs.group,
        glyphs.folder,
        glyphs.image,
        glyphs.file,
        glyphs.info,
      ];
      final horizontal = axis.value == Axis.horizontal;
      final shown = _sections.take(count.value.round()).toList();

      final dock = Dock<String>(
        value: shown.contains(chosen.value) ? chosen.value : null,
        onChanged: disabled.value ? null : (value) => chosen.value = value,
        axis: axis.value,
        swatch: swatch.value,
        destinations: [
          for (final (index, section) in shown.indexed)
            NavDestination(
              value: section,
              label: Text(section),
              icon: icons[index],
            ),
        ],
      );

      // The dock against the page it navigates: the bar under it, the rail
      // beside it.
      return Center(
        child: SizedBox(
          width: horizontal ? run.value : 520,
          height: horizontal ? 320 : run.value,
          child: Flex(
            direction: horizontal ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!horizontal) dock,
              Expanded(
                child: Placeholder(
                  child: BodyText('${chosen.value} is showing'),
                ),
              ),
              if (horizontal) dock,
            ],
          ),
        ),
      );
    },
  );
}
