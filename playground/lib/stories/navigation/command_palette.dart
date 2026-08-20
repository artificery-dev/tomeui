import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup commandPaletteStories() =>
    StoryGroup(name: 'CommandPalette', stories: [_commandPalette()]);

/// Both ways in: the panel sitting on the canvas so its rows can be read,
/// and the real thing over the page behind a scrim.
Story _commandPalette() {
  final ran = StringKnob('Last run', '—');
  final modal = BoolKnob('Over the page', false);

  return Story(
    name: 'CommandPalette',
    knobs: [ran, modal],
    builder: (context) {
      final icons = ThemeProvider.of(context).icons;
      List<Command> commands() => [
        Command(
          name: 'Save',
          section: 'File',
          hint: '⌘S',
          icon: icons.download,
          onInvoke: () => ran.value = 'Save',
        ),
        Command(
          name: 'Save as…',
          section: 'File',
          icon: icons.copy,
          onInvoke: () => ran.value = 'Save as…',
        ),
        Command(
          name: 'Toggle sidebar',
          section: 'View',
          hint: '⌘\\',
          icon: icons.sidebarLeading,
          keywords: const ['panel', 'drawer'],
          onInvoke: () => ran.value = 'Toggle sidebar',
        ),
        Command(
          name: 'Go to line…',
          section: 'Go',
          icon: icons.forward,
          keywords: const ['jump'],
          onInvoke: () => ran.value = 'Go to line',
        ),
        Command(
          name: 'Close window',
          section: 'Window',
          icon: icons.close,
          enabled: false,
          onInvoke: () => ran.value = 'Close window',
        ),
      ];

      if (!modal.value) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommandPalette(commands: commands()),
              const Spacing(SpaceStep.x6),
              CaptionText('ran: ${ran.value}'),
            ],
          ),
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: Placeholder(child: BodyText('ran: ${ran.value}')),
          ),
          Center(
            child: Builder(
              builder: (context) => Button(
                onPressed: () =>
                    showCommandPalette(context, commands: commands()),
                center: const Text('Open the palette'),
              ),
            ),
          ),
        ],
      );
    },
  );
}
