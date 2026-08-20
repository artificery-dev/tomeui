import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup menuBarStories() =>
    StoryGroup(name: 'MenuBar', stories: [_menuBar()]);

/// In the place it belongs: a title bar's leading slot. Click a word, then
/// run the pointer along the rest — the bar stays awake until you leave it.
Story _menuBar() {
  final inTitleBar = BoolKnob('In a title bar', true);
  final disableView = BoolKnob('Disable View', false);
  final chosen = StringKnob('Last chosen', '—');

  return Story(
    name: 'MenuBar',
    knobs: [inTitleBar, disableView, chosen],
    builder: (context) {
      final icons = ThemeProvider.of(context).icons;
      void choose(String what) => chosen.value = what;

      final bar = MenuBar(
        menus: [
          BarMenu(
            label: const Text('File'),
            entries: [
              MenuItem(
                label: const Text('New'),
                leading: Icon(icons.add),
                trailing: const Text('⌘N'),
                onPressed: () => choose('New'),
              ),
              MenuItem(
                label: const Text('Open…'),
                leading: Icon(icons.folder),
                onPressed: () => choose('Open'),
              ),
              const MenuSeparator(),
              MenuItem(
                label: const Text('Close'),
                swatch: SemanticSwatch.error,
                onPressed: () => choose('Close'),
              ),
            ],
          ),
          BarMenu(
            label: const Text('Edit'),
            entries: [
              const MenuSection(Text('History')),
              MenuItem(
                label: const Text('Undo'),
                trailing: const Text('⌘Z'),
                onPressed: () => choose('Undo'),
              ),
              MenuItem(label: const Text('Redo'), onPressed: null),
            ],
          ),
          BarMenu(
            label: const Text('View'),
            enabled: !disableView.value,
            entries: [
              MenuItem(
                label: const Text('Toggle sidebar'),
                leading: Icon(icons.sidebarLeading),
                onPressed: () => choose('Toggle sidebar'),
              ),
            ],
          ),
        ],
      );

      return Column(
        children: [
          if (inTitleBar.value)
            TitleBar(leading: [bar], title: const Text('Endeavour'))
          else
            Surface(
              variant: SurfaceVariant.subtle,
              swatch: SemanticSwatch.neutral,
              padding: const EdgeInsets.all(8),
              child: Align(alignment: Alignment.centerLeft, child: bar),
            ),
          Expanded(
            child: Placeholder(child: BodyText('chose: ${chosen.value}')),
          ),
        ],
      );
    },
  );
}
