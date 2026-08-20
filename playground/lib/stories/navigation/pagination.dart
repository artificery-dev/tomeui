import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup paginationStories() =>
    StoryGroup(name: 'Pagination', stories: [_pagination()]);

Story _pagination() {
  final pageCount = DoubleKnob('Pages', 42, min: 1, max: 200);
  final page = DoubleKnob('Page', 20, min: 1, max: 200);
  final siblings = DoubleKnob('Siblings', 1, min: 0, max: 3);
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.ghost,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Pagination',
    knobs: [pageCount, page, siblings, variant, swatch, disabled],
    builder: (context) {
      final count = pageCount.value.round();
      // The knobs are two dials on one number line: keep the page inside
      // the run however they're turned.
      final current = page.value.round().clamp(1, count);

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Pagination(
              page: current,
              pageCount: count,
              siblings: siblings.value.round(),
              variant: variant.value,
              swatch: swatch.value,
              onChanged: disabled.value
                  ? null
                  : (value) => page.value = value.toDouble(),
            ),
            const Spacing(SpaceStep.x6),
            CaptionText('page $current of $count'),
          ],
        ),
      );
    },
  );
}
