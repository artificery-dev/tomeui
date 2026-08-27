import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup navListStories() =>
    StoryGroup(name: 'NavList', stories: [_navList()]);

const _places = ['Log', 'Crew', 'Charts', 'Manifest', 'Soundings'];

/// The whole vocabulary in one sidebar: a heading, destinations, a group
/// that folds, a rule, and a count riding along on a row.
Story _navList() {
  final chosen = ListKnob<String>('Value', _places.first, options: _places);
  final headings = BoolKnob('Headings', true);
  final group = BoolKnob('Group', true);
  final openGroup = BoolKnob('Group starts open', true);
  final counts = BoolKnob('Counts', true);
  final icons = BoolKnob('Icons', true);
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'NavList',
    knobs: [chosen, headings, group, openGroup, counts, icons, swatch, disabled],
    builder: (context) {
      final glyphs = ThemeProvider.of(context).icons;

      NavDestination<String> place(String name, IconData glyph, {String? count}) =>
          NavDestination(
            value: name,
            label: Text(name),
            icon: icons.value ? glyph : null,
            trailing: counts.value && count != null ? Text(count) : null,
          );

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The sidebar it would really live in.
          Surface(
            variant: SurfaceVariant.subtle,
            swatch: SemanticSwatch.neutral,
            child: SizedBox(
              width: 240,
              height: double.infinity,
              child: Inset.all(
                SpaceStep.x2,
                child: NavList<String>(
                  value: chosen.value,
                  onChanged: disabled.value
                      ? null
                      : (value) => chosen.value = value,
                  swatch: swatch.value,
                  entries: [
                    if (headings.value) const NavHeading(Text('SHIP')),
                    place('Log', glyphs.file, count: '12'),
                    place('Crew', glyphs.group),
                    const NavSeparator(),
                    if (headings.value) const NavHeading(Text('VOYAGE')),
                    place('Charts', glyphs.image),
                    if (group.value)
                      NavGroup(
                        label: const Text('Cargo'),
                        icon: icons.value ? glyphs.folder : null,
                        initiallyOpen: openGroup.value,
                        destinations: [
                          place('Manifest', glyphs.file, count: '3'),
                          place('Soundings', glyphs.info),
                        ],
                      )
                    else ...[
                      place('Manifest', glyphs.file, count: '3'),
                      place('Soundings', glyphs.info),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Placeholder(child: BodyText('${chosen.value} is showing')),
          ),
        ],
      );
    },
  );
}
