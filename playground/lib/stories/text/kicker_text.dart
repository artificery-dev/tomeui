import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

/// A component, not a token: the kicker is the label style wearing extra
/// tracking and uppercased at paint time, which is a widget's doing. The
/// scale it sits on is in Tokens.
StoryGroup kickerTextStories() =>
    StoryGroup(name: 'KickerText', stories: [_kicker()]);

Story _kicker() {
  final label = StringKnob('Label', 'Danger zone');
  final emphasis = ListKnob<TextEmphasis>(
    'Emphasis',
    TextEmphasis.secondary,
    options: TextEmphasis.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'KickerText',
    knobs: [label, emphasis],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KickerText(label.value, emphasis: emphasis.value),
          SizedBox(height: theme.space.x2),
          const BodyText('What the kicker introduces.'),
        ],
      );
    },
  );
}
