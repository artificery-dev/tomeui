import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup scaffoldStories() => StoryGroup(
  name: 'Scaffold',
  stories: [_shell(), _adaptive()],
);

/// Every slot filled, with knobs for the ones a shell can do without —
/// the fastest way to see what the hairlines and the sidebars do to a
/// page's shape.
Story _shell() {
  final toolbars = DoubleKnob('Toolbars', 1, max: 3);
  final statusbars = DoubleKnob('Status bars', 1, max: 3);
  final leading = BoolKnob('Leading sidebar', true);
  final trailing = BoolKnob('Trailing sidebar', true);
  final leadingOpen = BoolKnob('Leading starts open', true);

  return Story(
    name: 'The slots',
    knobs: [toolbars, statusbars, leading, trailing, leadingOpen],
    // Keyed on the slots so flipping one rebuilds the scaffold from
    // scratch: the open/shut state is the scaffold's own, and a story that
    // changes what the slots *are* is a different page.
    builder: (context) => Scaffold(
      key: ValueKey('$leading$trailing$leadingOpen'),
      initialLeadingOpen: leadingOpen.value,
      toolbars: [
        for (var i = 0; i < toolbars.value.round(); i++)
          _bar(
            context,
            i == 0
                ? const [
                    ScaffoldSidebarToggle(ScaffoldSide.leading),
                    Spacer(),
                    ScaffoldSidebarToggle(ScaffoldSide.trailing),
                  ]
                : [Text('Toolbar ${i + 1}')],
          ),
      ],
      statusbars: [
        for (var i = 0; i < statusbars.value.round(); i++)
          _bar(context, [Text('Status bar ${i + 1}')]),
      ],
      leading: leading.value ? _sidebar(context, 'Navigation') : null,
      trailing: trailing.value ? _sidebar(context, 'Inspector') : null,
      body: const Center(child: BodyText('The body')),
    ),
  );
}

/// Drag the canvas narrow and watch the sidebars change character: trailing
/// gives up its column first, then leading, and what was beside the body
/// comes back as a drawer over it.
Story _adaptive() => Story(
  name: 'Narrowing',
  builder: (context) => Scaffold(
    toolbars: [
      _bar(context, const [
        ScaffoldSidebarToggle(ScaffoldSide.leading),
        Spacer(),
        ScaffoldSidebarToggle(ScaffoldSide.trailing),
      ]),
    ],
    leading: _sidebar(context, 'Navigation'),
    trailing: _sidebar(context, 'Inspector'),
    body: Builder(
      builder: (context) {
        final scaffold = ScaffoldStateProvider.of(context);
        String where(ScaffoldSidebar sidebar) =>
            sidebar.drawer ? 'a drawer' : 'beside the body';
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BodyText('Leading is ${where(scaffold.leading)}.'),
              BodyText('Trailing is ${where(scaffold.trailing)}.'),
            ],
          ),
        );
      },
    ),
  ),
);

/// A bar's contents: the scaffold gives the band its dress and its gutters,
/// so a bar is only ever a row of things.
Widget _bar(BuildContext context, List<Widget> children) => SizedBox(
  height: ThemeProvider.of(context).sizes.touchTarget,
  child: Row(children: children),
);

Widget _sidebar(BuildContext context, String title) {
  final theme = ThemeProvider.of(context);
  return ListView(
    padding: EdgeInsets.all(theme.space.x3),
    children: [
      KickerText(title),
      SizedBox(height: theme.space.x2),
      for (final row in ['Manifest', 'Cargo', 'Crew', 'Log'])
        Padding(
          padding: EdgeInsets.only(bottom: theme.space.x1),
          child: BodyText(row),
        ),
    ],
  );
}
