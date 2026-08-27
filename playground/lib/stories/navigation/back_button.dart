import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup backButtonStories() =>
    StoryGroup(name: 'BackButton', stories: [_backButton()]);

/// The button's whole point is that it knows whether there's a way back, so
/// the story gives it a real stack to ask about: the first page draws
/// nothing, the pushed one draws the button.
Story _backButton() {
  final label = BoolKnob('Words beside the glyph', false);

  return Story(
    name: 'BackButton',
    knobs: [label],
    builder: (context) => Navigator(
      onGenerateRoute: (settings) => TomePageRoute<void>(
        settings: settings,
        builder: (context) => _Page(
          title: 'Fleet',
          label: label.value,
          child: Builder(
            builder: (context) => Button(
              onPressed: () => Navigator.of(context).push(
                TomePageRoute<void>(
                  builder: (context) => _Page(
                    title: 'Endeavour',
                    label: label.value,
                    child: const BodyText('Pushed. Now there is a way back.'),
                  ),
                ),
              ),
              center: const Text('Push a page'),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.label,
    required this.child,
  });

  final String title;
  final bool label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    // Stretched, so the page under the bar is the width of the window
    // rather than the width of the words in it.
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TitleBar(
        leading: [BackButton(label: label ? const Text('Back') : null)],
        title: Text(title),
      ),
      Expanded(child: Placeholder(child: child)),
    ],
  );
}
