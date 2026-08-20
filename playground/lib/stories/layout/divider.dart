import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup dividerStories() =>
    StoryGroup(name: 'Divider', stories: [_divider()]);

Story _divider() {
  final axis = ListKnob<Axis>(
    'Axis',
    Axis.horizontal,
    options: Axis.values,
    describe: (option) => option.name,
  );
  final fade = BoolKnob('Fade at the ends', false);
  final indent = ListKnob<SpaceStep>(
    'Indent',
    SpaceStep.none,
    options: SpaceStep.values,
    describe: (option) => option.name,
  );
  final endIndent = ListKnob<SpaceStep>(
    'End indent',
    SpaceStep.none,
    options: SpaceStep.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'Divider',
    knobs: [axis, fade, indent, endIndent],
    builder: (context) {
      final horizontal = axis.value == Axis.horizontal;
      return Center(
        child: SizedBox(
          width: 360,
          height: 160,
          // A horizontal rule separates things stacked; a vertical one
          // separates things side by side. The run turns with it.
          child: Flex(
            direction: horizontal ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BodyText(horizontal ? 'Above' : 'Left'),
              const Spacing(SpaceStep.x4),
              Divider(
                axis: axis.value,
                fade: fade.value,
                indent: indent.value,
                endIndent: endIndent.value,
              ),
              const Spacing(SpaceStep.x4),
              BodyText(horizontal ? 'Below' : 'Right'),
            ],
          ),
        ),
      );
    },
  );
}
