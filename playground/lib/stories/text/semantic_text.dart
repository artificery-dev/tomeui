import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup textStories() =>
    StoryGroup(name: 'Text', stories: [_typeScale(), _oneLine(), _kicker()]);

/// The whole scale at once, in the order it steps down — the fastest way to
/// see whether a swapped [Typography] still reads as one system.
Story _typeScale() => Story(
  name: 'The scale',
  builder: (context) {
    final theme = ThemeProvider.of(context);
    Widget row(String role, Widget sample) => Padding(
      padding: EdgeInsets.only(bottom: theme.space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KickerText(role),
          SizedBox(height: theme.space.x1),
          sample,
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(theme.space.x6),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.sizes.contentNarrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            row('display', const DisplayText('Weigh anchor')),
            row('headline', const HeadlineText('Weigh anchor')),
            row('title', const TitleText('Weigh anchor')),
            row('subtitle', const SubtitleText('Weigh anchor')),
            row('body', const BodyText('Weigh anchor, and make sail.')),
            row(
              'bodySmall',
              const BodyText.small('Weigh anchor, and make sail.'),
            ),
            row('label', const LabelText('Weigh anchor')),
            row('caption', const CaptionText('Logged at eight bells')),
            row('code', const CodeText('flutter pub add tomeui')),
          ],
        ),
      ),
    );
  },
);

/// One line, every dial: the role it wears, how loudly, and on what.
Story _oneLine() {
  final role = ListKnob<TextRole>(
    'Role',
    TextRole.body,
    options: TextRole.values,
    describe: (option) => option.name,
  );
  final emphasis = ListKnob<TextEmphasis>(
    'Emphasis',
    TextEmphasis.full,
    options: TextEmphasis.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch?>(
    'Swatch',
    null,
    options: [null, ...SemanticSwatch.values],
    describe: (option) => option?.name ?? 'inherit the surface',
  );
  final variant = ListKnob<SurfaceVariant>(
    'On a surface',
    SurfaceVariant.ghost,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final words = StringKnob('Words', 'Everything aboard, counted.');

  return Story(
    name: 'One line',
    knobs: [role, emphasis, swatch, variant, words],
    // Sat on a surface deliberately: the point of the category is that
    // uncoloured text takes whatever the surface underneath it speaks.
    builder: (context) => Surface(
      variant: variant.value,
      padding: EdgeInsets.all(ThemeProvider.of(context).space.x4),
      child: _RoleText(
        words.value,
        role: role.value,
        emphasis: emphasis.value,
        swatch: swatch.value,
      ),
    ),
  );
}

/// The knob panel needs one widget that can wear any role; the app-facing
/// API is the named widgets — [BodyText], [TitleText], and the rest.
class _RoleText extends SemanticText {
  const _RoleText(
    super.data, {
    required super.role,
    super.emphasis,
    super.swatch,
  });
}

Story _kicker() {
  final label = StringKnob('Label', 'Danger zone');
  final emphasis = ListKnob<TextEmphasis>(
    'Emphasis',
    TextEmphasis.secondary,
    options: TextEmphasis.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'Kicker',
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
