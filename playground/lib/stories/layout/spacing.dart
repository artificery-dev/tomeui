import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup spacingStories() =>
    StoryGroup(name: 'Spacing', stories: [_spacing()]);

/// The same gap in three surroundings: a column, a row, and a list — the
/// last being the one with no `spacing` parameter of its own, which is
/// what the widget exists for.
Story _spacing() {
  final step = ListKnob<SpaceStep>(
    'Step',
    SpaceStep.x4,
    options: SpaceStep.values,
    describe: (option) => option.name,
  );
  final axis = ListKnob<Axis?>(
    'Axis',
    null,
    options: [null, ...Axis.values],
    describe: (option) => option?.name ?? 'from the surroundings',
  );

  return Story(
    name: 'Spacing',
    knobs: [step, axis],
    builder: (context) {
      Widget block(String label) => Surface(
        variant: SurfaceVariant.soft,
        padding: const EdgeInsets.all(12),
        child: LabelText(label),
      );
      final gap = Spacing(step.value, axis: axis.value);

      return Inset.all(
        SpaceStep.x6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KickerText('In a row'),
            const Spacing(SpaceStep.x2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [block('a'), gap, block('b')],
            ),
            const Spacing(SpaceStep.x6),
            const KickerText('In a column'),
            const Spacing(SpaceStep.x2),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [block('a'), gap, block('b')],
            ),
            const Spacing(SpaceStep.x6),
            const KickerText('In a list, which has no spacing of its own'),
            const Spacing(SpaceStep.x2),
            SizedBox(
              height: 120,
              child: ListView(
                children: [block('a'), gap, block('b'), gap, block('c')],
              ),
            ),
          ],
        ),
      );
    },
  );
}
