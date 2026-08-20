import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup statusChipStories() =>
    StoryGroup(name: 'StatusChip', stories: [_statusChip()]);

Story _statusChip() {
  final label = StringKnob('Label', 'Delivered');
  final mark = ListKnob<String>(
    'Mark',
    'dot',
    options: ['none', 'dot', 'icon'],
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.success,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.soft,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'StatusChip',
    knobs: [label, mark, swatch, variant],
    builder: (context) {
      final icons = ThemeProvider.of(context).icons;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(
              label: Text(label.value),
              dot: mark.value == 'dot',
              icon: mark.value == 'icon' ? icons.confirm : null,
              swatch: swatch.value,
              variant: variant.value,
            ),
            const Spacing(SpaceStep.x8),
            const KickerText('One of each, as a list would use them'),
            const Spacing(SpaceStep.x3),
            // The real test of a chip is a column of them: statuses read
            // against each other, not on their own.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (name, swatch) in [
                  ('Delivered', SemanticSwatch.success),
                  ('In transit', SemanticSwatch.info),
                  ('Held', SemanticSwatch.warning),
                  ('Overdue', SemanticSwatch.error),
                  ('Draft', SemanticSwatch.neutral),
                ]) ...[
                  StatusChip(label: Text(name), dot: true, swatch: swatch),
                  const Spacing(SpaceStep.x2),
                ],
              ],
            ),
          ],
        ),
      );
    },
  );
}
