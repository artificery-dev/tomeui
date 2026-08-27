import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup titleBarStories() =>
    StoryGroup(name: 'TitleBar', stories: [_titleBar()]);

/// The window knobs are off to begin with: on this desktop they work, and
/// a demo that closes the playground would be a poor demonstration.
Story _titleBar() {
  final title = StringKnob('Title', 'Manifest');
  final subtitle = StringKnob('Subtitle', 'Endeavour · outbound');
  final leading = BoolKnob('Leading button', true);
  final actions = BoolKnob('Actions', true);
  final centerTitle = BoolKnob('Centre the title', false);
  final windowControls = BoolKnob('Window buttons', false);
  final drag = BoolKnob('Drag moves the window', false);

  return Story(
    name: 'TitleBar',
    knobs: [
      title,
      subtitle,
      leading,
      actions,
      centerTitle,
      windowControls,
      drag,
    ],
    builder: (context) {
      final icons = ThemeProvider.of(context).icons;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitleBar(
            title: Text(title.value),
            subtitle: subtitle.value.isEmpty ? null : Text(subtitle.value),
            centerTitle: centerTitle.value,
            windowControls: windowControls.value,
            dragToMove: drag.value,
            leading: [
              if (leading.value)
                Button(
                  onPressed: () {},
                  variant: SurfaceVariant.ghost,
                  swatch: SemanticSwatch.neutral,
                  center: Icon(icons.sidebarLeading),
                ),
            ],
            actions: [
              if (actions.value) ...[
                Button(
                  onPressed: () {},
                  variant: SurfaceVariant.ghost,
                  swatch: SemanticSwatch.neutral,
                  center: Icon(icons.search),
                ),
                Button(onPressed: () {}, center: const Text('Sign')),
              ],
            ],
          ),
          const Expanded(
            child: Placeholder(child: BodyText('the page under the bar')),
          ),
        ],
      );
    },
  );
}
