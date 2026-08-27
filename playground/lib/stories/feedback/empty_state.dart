import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup emptyStateStories() =>
    StoryGroup(name: 'EmptyState', stories: [_emptyState()]);

/// Shown in the slot it would really occupy — a panel with nothing in it —
/// since an empty state centred on a blank canvas proves nothing. The panel
/// is the empty state's own: [SurfaceVariant.outline] makes it the card.
Story _emptyState() {
  final title = StringKnob('Title', 'No voyages yet');
  final message = StringKnob(
    'Message',
    'Log the first one and it will show up here, with its crew and its '
        'cargo.',
  );
  final icon = BoolKnob('Glyph', true);
  final action = BoolKnob('Action', true);
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.neutral,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.outline,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'EmptyState',
    knobs: [title, message, icon, action, swatch, variant],
    builder: (context) {
      final icons = ThemeProvider.of(context).icons;

      return Center(
        child: SizedBox(
          width: 560,
          height: 360,
          child: EmptyState(
            swatch: swatch.value,
            variant: variant.value,
            icon: icon.value ? icons.folder : null,
            title: title.value.isEmpty ? null : Text(title.value),
            message: message.value.isEmpty ? null : Text(message.value),
            action: action.value
                ? Button(onPressed: () {}, center: const Text('Log a voyage'))
                : null,
          ),
        ),
      );
    },
  );
}
