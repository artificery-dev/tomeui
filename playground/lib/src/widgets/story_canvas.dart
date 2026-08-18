import 'package:tomeui/tomeui.dart';

import '../story.dart';
import '../theme_config.dart';

/// The middle column: one story, dressed the way [TomeApp] would dress it —
/// theme provided, page background painted, text and icons speaking the
/// palette — and rebuilt whenever a knob or the App tab changes.
class StoryCanvas extends StatelessWidget {
  const StoryCanvas({required this.story, required this.config, super.key});

  final Story story;
  final ThemeConfig config;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([config, story.listenable]),
    builder: (context, _) {
      final theme = config.theme;
      return ThemeProvider(
        theme: theme,
        child: ColoredBox(
          color: theme.palette.background,
          child: DefaultTextStyle(
            style: theme.typography.body.copyWith(color: theme.palette.text),
            child: IconTheme(
              data: IconThemeData(
                color: theme.palette.text,
                size: theme.sizes.icon,
              ),
              child: SizedBox.expand(
                child: Center(child: Builder(builder: story.builder)),
              ),
            ),
          ),
        ),
      );
    },
  );
}
