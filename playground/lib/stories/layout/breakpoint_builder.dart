import 'package:tomeui/tomeui.dart';

import '../../src/story.dart';

StoryGroup breakpointBuilderStories() =>
    StoryGroup(name: 'BreakpointBuilder', stories: [_breakpointBuilder()]);

/// The one story with no knobs worth having: the window is the input, so
/// drag the playground's own edge and watch the band change.
Story _breakpointBuilder() => Story(
  name: 'BreakpointBuilder',
  builder: (context) {
    final breakpoints = ThemeProvider.of(context).breakpoints;
    final width = MediaQuery.sizeOf(context).width;

    return BreakpointBuilder(
      builder: (context, band) => Center(
        child: SizedBox(
          width: 420,
          child: Card(
            header: const KickerText('The window says'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DisplayText(band.name),
                const Spacing(SpaceStep.x2),
                BodyText('${width.round()} across'),
                const Spacing(SpaceStep.x4),
                const Divider(fade: true),
                const Spacing(SpaceStep.x4),
                for (final other in Breakpoint.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: BodyText(
                      '${other.name}${band == other ? '  ←' : ''}',
                      emphasis: band == other
                          ? TextEmphasis.full
                          : TextEmphasis.tertiary,
                    ),
                  ),
                const Spacing(SpaceStep.x2),
                CaptionText(
                  'thresholds ${breakpoints.compact.round()} / '
                  '${breakpoints.medium.round()} / '
                  '${breakpoints.expanded.round()}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
