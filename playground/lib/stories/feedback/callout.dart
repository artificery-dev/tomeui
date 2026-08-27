import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup calloutStories() =>
    StoryGroup(name: 'Callout', stories: [_callout()]);

Story _callout() {
  final title = StringKnob('Title', 'The manifest is unsigned');
  final message = StringKnob(
    'Message',
    'Nothing sails until it is. The cargo is aboard and the tide turns at '
        'eight bells.',
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.warning,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.soft,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final actions = BoolKnob('Actions', true);
  final dismissible = BoolKnob('Dismissible', true);
  final gone = BoolKnob('Dismissed', false);

  return Story(
    name: 'Callout',
    knobs: [title, message, swatch, variant, actions, dismissible, gone],
    builder: (context) => Center(
      child: SizedBox(
        width: 520,
        child: gone.value
            ? Button(
                onPressed: () => gone.value = false,
                variant: SurfaceVariant.ghost,
                center: const Text('Put it back'),
              )
            : Callout(
                swatch: swatch.value,
                variant: variant.value,
                title: title.value.isEmpty ? null : Text(title.value),
                message: message.value.isEmpty ? null : Text(message.value),
                onDismiss: dismissible.value ? () => gone.value = true : null,
                actions: [
                  if (actions.value) ...[
                    Button(
                      onPressed: () {},
                      variant: SurfaceVariant.ghost,
                      swatch: swatch.value,
                      center: const Text('Read it first'),
                    ),
                    Button(
                      onPressed: () {},
                      swatch: swatch.value,
                      center: const Text('Sign'),
                    ),
                  ],
                ],
              ),
      ),
    ),
  );
}
