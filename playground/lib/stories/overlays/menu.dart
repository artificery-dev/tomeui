import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup menuStories() =>
    StoryGroup(name: 'Menu', stories: [_menu(), _contextMenu()]);

/// The entries a menu is made of, in one list: a section label, items with
/// icons and shortcut hints, a separator, a disabled row, and a dangerous
/// one wearing the error swatch.
List<MenuEntry> _menuEntries(BuildContext context, {required bool disabled}) {
  final icons = ThemeProvider.of(context).icons;
  return [
    const MenuSection(Text('Manifest')),
    MenuItem(
      label: const Text('Duplicate'),
      leading: Icon(icons.copy),
      trailing: const Text('⌘D'),
      onPressed: () {},
    ),
    MenuItem(
      label: const Text('Rename'),
      leading: Icon(icons.edit),
      onPressed: disabled ? null : () {},
    ),
    const MenuSeparator(),
    MenuItem(
      label: const Text('Delete'),
      leading: Icon(icons.delete),
      trailing: const Text('⌫'),
      swatch: SemanticSwatch.error,
      onPressed: () {},
    ),
  ];
}

Story _menu() {
  final open = BoolKnob('Open', true);
  final side = ListKnob<PopoverSide>(
    'Side',
    PopoverSide.bottom,
    options: PopoverSide.values,
    describe: (option) => option.name,
  );
  final align = ListKnob<PopoverAlign>(
    'Align',
    PopoverAlign.start,
    options: PopoverAlign.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disable Rename', false);

  return Story(
    name: 'Menu',
    knobs: [open, side, align, disabled],
    // The arrows walk it, Enter takes the row, Escape leaves — with the
    // canvas focused, none of that needs the mouse.
    builder: (context) => Menu(
      open: open.value,
      side: side.value,
      align: align.value,
      onDismiss: () => open.value = false,
      entries: _menuEntries(context, disabled: disabled.value),
      anchor: Button(
        onPressed: () => open.value = !open.value,
        center: const Text('Actions'),
      ),
    ),
  );
}

/// Right-click the panel — or long-press it on a touch screen — and the
/// menu opens at the pointer rather than at the panel's edge.
Story _contextMenu() => Story(
  name: 'On right-click',
  builder: (context) => SizedBox(
    width: 360,
    height: 220,
    child: ContextMenu(
      entries: _menuEntries(context, disabled: false),
      child: const Placeholder(child: Text('Right-click me')),
    ),
  ),
);
