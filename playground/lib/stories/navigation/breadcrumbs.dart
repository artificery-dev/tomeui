import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup breadcrumbsStories() =>
    StoryGroup(name: 'Breadcrumbs', stories: [_breadcrumbs()]);

const _trail = ['Fleet', 'Endeavour', 'Voyages', '1789', 'Manifest'];

Story _breadcrumbs() {
  final depth = DoubleKnob('Depth', 3, min: 1, max: 5);
  final icons = BoolKnob('Icon on the root', true);
  final separator = ListKnob<String>(
    'Separator',
    'chevron',
    options: ['chevron', 'slash', 'dot'],
  );
  final narrow = BoolKnob('Narrow the trail', false);

  return Story(
    name: 'Breadcrumbs',
    knobs: [depth, icons, separator, narrow],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      final crumbs = _trail.take(depth.value.round()).toList();

      return Center(
        child: SizedBox(
          width: narrow.value ? 200 : 520,
          child: Surface(
            variant: SurfaceVariant.subtle,
            swatch: SemanticSwatch.neutral,
            padding: const EdgeInsets.all(12),
            child: Breadcrumbs(
              separator: switch (separator.value) {
                'slash' => const CaptionText('/'),
                'dot' => const CaptionText('·'),
                _ => null,
              },
              crumbs: [
                for (final (index, crumb) in crumbs.indexed)
                  Crumb(
                    label: Text(crumb),
                    icon: index == 0 && icons.value ? theme.icons.home : null,
                    onPressed: () {},
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
