import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup dialogStories() => StoryGroup(name: 'Dialog', stories: [_dialog()]);

/// Two ways to look at it: the panel sitting still on the canvas, and the
/// real thing over the page with a scrim, a keyboard it keeps, and an
/// answer it hands back.
Story _dialog() {
  final overThePage = BoolKnob('Over the page', false);
  final title = StringKnob('Title', 'Sign the manifest?');
  final message = StringKnob(
    'Message',
    'Nothing sails until it is signed. The cargo is aboard.',
  );
  final icon = BoolKnob('Icon', false);
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.warning,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final dismissible = BoolKnob('Dismissible', true);
  final answer = StringKnob('Last answer', '—');

  return Story(
    name: 'Dialog',
    knobs: [
      overThePage,
      title,
      message,
      icon,
      swatch,
      dismissible,
      answer,
    ],
    builder: (context) {
      final glyphs = ThemeProvider.of(context).icons;

      Widget panel(BuildContext context, {required bool live}) => Dialog(
        icon: icon.value ? glyphs.warning : null,
        swatch: swatch.value,
        title: Text(title.value),
        message: message.value.isEmpty ? null : Text(message.value),
        actions: [
          Button(
            onPressed: () {
              answer.value = 'not yet';
              if (live) Navigator.of(context).pop('not yet');
            },
            variant: SurfaceVariant.ghost,
            swatch: SemanticSwatch.neutral,
            center: const Text('Not yet'),
          ),
          Button(
            onPressed: () {
              answer.value = 'signed';
              if (live) Navigator.of(context).pop('signed');
            },
            center: const Text('Sign'),
          ),
        ],
      );

      if (!overThePage.value) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              panel(context, live: false),
              const Spacing(SpaceStep.x6),
              CaptionText('answered: ${answer.value}'),
            ],
          ),
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: Placeholder(
              child: BodyText('answered: ${answer.value}'),
            ),
          ),
          Center(
            child: Builder(
              builder: (context) => Button(
                onPressed: () => showDialog<String>(
                  context,
                  barrierDismissible: dismissible.value,
                  builder: (context) => panel(context, live: true),
                ),
                center: const Text('Ask'),
              ),
            ),
          ),
        ],
      );
    },
  );
}
