import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup skeletonStories() =>
    StoryGroup(name: 'Skeleton', stories: [_skeleton()]);

/// The point of a skeleton is the shape of the thing it stands in for, so
/// the story builds a card twice: once as bones, once as the real thing.
Story _skeleton() {
  final loading = BoolKnob('Loading', true);
  final lines = DoubleKnob('Message lines', 3, min: 1, max: 6);
  final stillness = BoolKnob('Less motion', false);

  return Story(
    name: 'Skeleton',
    knobs: [loading, lines, stillness],
    builder: (context) {
      final theme = ThemeProvider.of(context);

      return MediaQuery(
        // What a reader who has asked for less motion sees: a shape, held
        // still.
        data: MediaQuery.of(context).copyWith(
          disableAnimations: stillness.value,
        ),
        child: Center(
          child: SizedBox(
            width: 420,
            child: Card(
              leading: loading.value
                  ? const Skeleton.circle(size: 40)
                  : Surface(
                      variant: SurfaceVariant.soft,
                      swatch: SemanticSwatch.accent,
                      padding: const EdgeInsets.all(10),
                      child: Icon(theme.icons.user),
                    ),
              header: loading.value
                  ? const Skeleton.box(width: 160, height: 16)
                  : const TitleText('Endeavour'),
              content: loading.value
                  ? Skeleton.text(lines: lines.value.round())
                  : const BodyText(
                      'Eight bells, wind freshening from the south-west. '
                      'Cargo dry, crew accounted for, and the glass steady '
                      'since the forenoon watch.',
                    ),
              footer: loading.value
                  ? const Skeleton.box(width: 96, height: 32)
                  : Button(onPressed: () {}, center: const Text('Open')),
            ),
          ),
        ),
      );
    },
  );
}
