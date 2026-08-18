import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup popoverStories() =>
    StoryGroup(name: 'Popover', stories: [_popover()]);

Story _popover() {
  final open = BoolKnob('Open', true);
  final side = ListKnob<PopoverSide>(
    'Side',
    PopoverSide.bottom,
    options: PopoverSide.values,
    describe: (option) => option.name,
  );
  final align = ListKnob<PopoverAlign>(
    'Align',
    PopoverAlign.center,
    options: PopoverAlign.values,
    describe: (option) => option.name,
  );
  final barrier = BoolKnob('Barrier', true);

  return Story(
    name: 'Popover',
    knobs: [open, side, align, barrier],
    // Drag the canvas story near an edge to watch it flip and slide.
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return Popover(
        open: open.value,
        side: side.value,
        align: align.value,
        barrier: barrier.value,
        onDismiss: () => open.value = false,
        anchor: Button(
          onPressed: () => open.value = !open.value,
          center: const Text('Options'),
        ),
        content: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anchored, and kept on screen.'),
            SizedBox(height: theme.space.x2),
            Text(
              'Escape or a tap outside asks to close.',
              style: theme.typography.bodySmall,
            ),
          ],
        ),
      );
    },
  );
}
