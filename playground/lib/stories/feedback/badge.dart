import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup badgeStories() => StoryGroup(name: 'Badge', stories: [_badge()]);

Story _badge() {
  final count = DoubleKnob('Count', 3, max: 200);
  final max = DoubleKnob('Counts up to', 9, min: 1, max: 99);
  final shape = ListKnob<String>(
    'Shape',
    'count',
    options: ['count', 'dot', 'label'],
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.error,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'Badge',
    knobs: [count, max, shape, swatch],
    builder: (context) {
      final icons = ThemeProvider.of(context).icons;

      Widget badge({Widget? child}) => switch (shape.value) {
        'dot' => Badge.dot(swatch: swatch.value, child: child),
        'label' => Badge.label(
          const Text('NEW'),
          swatch: swatch.value,
          child: child,
        ),
        _ => Badge.count(
          count.value.round(),
          max: max.value.round(),
          swatch: swatch.value,
          child: child,
        ),
      };

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KickerText('Riding on things'),
            const Spacing(SpaceStep.x4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                badge(child: Icon(icons.info, size: 24)),
                const Spacing(SpaceStep.x8),
                badge(
                  child: Button(
                    onPressed: () {},
                    variant: SurfaceVariant.outline,
                    swatch: SemanticSwatch.neutral,
                    center: const Text('Inbox'),
                  ),
                ),
                const Spacing(SpaceStep.x8),
                badge(child: const Text('Messages')),
              ],
            ),
            const Spacing(SpaceStep.x8),
            const KickerText('On its own'),
            const Spacing(SpaceStep.x4),
            badge(),
          ],
        ),
      );
    },
  );
}
