import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup insetStories() => StoryGroup(name: 'Inset', stories: [_inset()]);

/// The padding is the thing on show, so the story draws what it can't
/// otherwise be seen against: a placeholder behind the inset, the content
/// on a surface inside it.
Story _inset() {
  final all = ListKnob<SpaceStep>(
    'All',
    SpaceStep.x4,
    options: SpaceStep.values,
    describe: (option) => option.name,
  );
  final start = ListKnob<SpaceStep?>(
    'Start override',
    null,
    options: [null, ...SpaceStep.values],
    describe: (option) => option?.name ?? 'as all',
  );
  final rtl = BoolKnob('Right to left', false);

  return Story(
    name: 'Inset',
    knobs: [all, start, rtl],
    builder: (context) => Directionality(
      textDirection: rtl.value ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 320,
          child: Placeholder(
            child: Inset.only(
              start: start.value ?? all.value,
              top: all.value,
              end: all.value,
              bottom: all.value,
              child: const Surface(
                variant: SurfaceVariant.soft,
                padding: EdgeInsets.all(12),
                child: BodyText('Inside the inset'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
