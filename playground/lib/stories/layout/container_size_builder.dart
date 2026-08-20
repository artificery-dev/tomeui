import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup containerSizeBuilderStories() =>
    StoryGroup(name: 'ContainerSizeBuilder', stories: [_containerSize()]);

/// The window stays where it is; the slot is what moves. Narrow the box and
/// the card inside it folds, which is the case a media query can't see.
Story _containerSize() {
  final width = DoubleKnob('Slot width', 520, min: 200, max: 900);

  return Story(
    name: 'ContainerSizeBuilder',
    knobs: [width],
    builder: (context) => Center(
      child: SizedBox(
        width: width.value,
        child: ContainerSizeBuilder(
          builder: (context, size) {
            final tight = size.width < 420;
            final label = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TitleText('${size.width.round()} across'),
                const Spacing(SpaceStep.x1),
                CaptionText('this slot is ${size.breakpoint.name}'),
              ],
            );
            const blurb = BodyText(
              'The window has not moved. Only the room this slot was handed '
              'has, which is the question a media query cannot answer.',
            );

            return Card(
              content: tight
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        label,
                        const Spacing(SpaceStep.x4),
                        blurb,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label,
                        const Spacing(SpaceStep.x6),
                        const Expanded(child: blurb),
                      ],
                    ),
            );
          },
        ),
      ),
    ),
  );
}
