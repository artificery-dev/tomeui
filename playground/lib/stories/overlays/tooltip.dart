import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup tooltipStories() =>
    StoryGroup(name: 'Tooltip', stories: [_tooltip()]);

Story _tooltip() {
  final side = ListKnob<PopoverSide>(
    'Side',
    PopoverSide.top,
    options: PopoverSide.values,
    describe: (option) => option.name,
  );
  final align = ListKnob<PopoverAlign>(
    'Align',
    PopoverAlign.center,
    options: PopoverAlign.values,
    describe: (option) => option.name,
  );
  final message = StringKnob('Message', 'Weigh anchor and make sail');

  return Story(
    name: 'Tooltip',
    knobs: [side, align, message],
    builder: (context) => Tooltip(
      side: side.value,
      align: align.value,
      message: Text(message.value),
      child: Button(onPressed: () {}, center: const Text('Hover me')),
    ),
  );
}
