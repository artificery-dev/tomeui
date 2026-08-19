import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup scaffoldStories() =>
    StoryGroup(name: 'Scaffold', stories: [_scaffold()]);

/// Every slot filled, with knobs for the ones a shell can do without.
///
/// One story covers both presentations: drag the canvas narrow and the
/// sidebars change character — trailing gives up its column first, then
/// leading, and what was beside the body comes back as a drawer over it.
/// The body says which is which as it happens.
Story _scaffold() {
  final toolbars = DoubleKnob('Toolbars', 1, max: 3);
  final statusbars = DoubleKnob('Status bars', 1, max: 3);
  final leading = BoolKnob('Leading sidebar', true);
  final trailing = BoolKnob('Trailing sidebar', true);
  final leadingOpen = BoolKnob('Leading starts open', true);

  return Story(
    name: 'Scaffold',
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
      body: const _Body(),
    ),
  );
}

/// Reads the scaffold it sits in, so narrowing the canvas is legible as
/// well as visible.
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final scaffold = ScaffoldStateProvider.of(context);
    String where(ScaffoldSidebar sidebar) => !sidebar.present
        ? 'not there'
        : sidebar.drawer
        ? 'a drawer'
        : 'beside the body';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BodyText('The body'),
          SizedBox(height: ThemeProvider.of(context).space.x4),
          CaptionText('Leading is ${where(scaffold.leading)}.'),
          CaptionText('Trailing is ${where(scaffold.trailing)}.'),
        ],
      ),
    );
  }
}

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
