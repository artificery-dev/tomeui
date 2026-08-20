import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup emptyStateStories() =>
    StoryGroup(name: 'EmptyState', stories: [_emptyState()]);

/// Shown in the slot it would really occupy — a panel with nothing in it —
/// since an empty state centred on a blank canvas proves nothing.
Story _emptyState() {
  final title = StringKnob('Title', 'No voyages yet');
  final message = StringKnob(
    'Message',
    'Log the first one and it will show up here, with its crew and its '
        'cargo.',
  );
  final icon = BoolKnob('Glyph', true);
  final action = BoolKnob('Action', true);
  final inACard = BoolKnob('In a card', true);

  return Story(
    name: 'EmptyState',
    knobs: [title, message, icon, action, inACard],
    builder: (context) {
      final icons = ThemeProvider.of(context).icons;
      final state = EmptyState(
        icon: icon.value ? icons.folder : null,
        title: title.value.isEmpty ? null : Text(title.value),
        message: message.value.isEmpty ? null : Text(message.value),
        action: action.value
            ? Button(onPressed: () {}, center: const Text('Log a voyage'))
            : null,
      );

      return Center(
        child: SizedBox(
          width: 560,
          height: 360,
          child: inACard.value
              ? Card(spacing: SpaceStep.none, content: state)
              : state,
        ),
      );
    },
  );
}
