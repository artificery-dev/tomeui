import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup codeTextStories() =>
    StoryGroup(name: 'CodeText', stories: [_codeText(), _block()]);

Story _codeText() {
  final code = StringKnob('Code', 'flutter pub add tomeui');
  final copyable = BoolKnob('Copyable', true);
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.neutral,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'CodeText',
    knobs: [code, copyable, swatch],
    builder: (_) => CodeText(
      code.value,
      copyable: copyable.value,
      swatch: swatch.value,
    ),
  );
}

/// One sample per language the story offers, each written to put a few
/// different scopes on screen at once.
const _samples = {
  'dart': r"""/// What the resolver hands a widget to paint.
class SurfaceStyle {
  const SurfaceStyle({required this.foreground, this.fill});

  final Color foreground;
  final Color? fill;

  /* The palette decides which colour a meaning is;
     the widget only ever asks for the meaning. */
  Color inkOn(Color background) =>
      fill == null ? foreground : foreground.withValues(alpha: 0.9);
}

void main() => runApp(const TomeApp(home: Page()));""",
  'yaml': r"""name: tomeui
description: A Flutter UI toolkit built on the widgets layer.
version: 0.1.0

environment:
  sdk: ^3.12.2

dependencies:
  flutter: { sdk: flutter }   # the widgets layer, and nothing above it
  lucide_icons_flutter: ^3.0.0
  re_highlight: ^0.0.3""",
  'json': r"""{
  "palette": { "brightness": "dark", "primary": "sky" },
  "space": [4, 8, 12, 16, 24],
  "motion": { "standard": 240, "curve": "easeOutCubic" }
}""",
};

/// The listing shape: a card, a numbered gutter, and colour that comes out
/// of the palette rather than out of an editor's theme.
Story _block() {
  final language = ListKnob<String>(
    'Language',
    'dart',
    options: _samples.keys.toList(),
  );
  final lineNumbers = BoolKnob('Line numbers', true);
  final firstLine = DoubleKnob('First line', 1, min: 1, max: 200);
  final callOut = BoolKnob('Call out two lines', false);
  final wrap = BoolKnob('Fold long lines', false);
  final copyable = BoolKnob('Copyable', true);
  final coloured = BoolKnob('Known language', true);

  return Story(
    name: 'Block',
    knobs: [
      language,
      lineNumbers,
      firstLine,
      callOut,
      wrap,
      copyable,
      coloured,
    ],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      final start = firstLine.value.round();
      return SingleChildScrollView(
        padding: EdgeInsets.all(theme.space.x6),
        child: CodeText.block(
          _samples[language.value]!,
          // Naming a language the registry doesn't know is the graceful
          // case worth seeing: the card, the numbers, and the copy button
          // all stay, and only the colour goes.
          language: coloured.value ? language.value : 'not-a-language',
          lineNumbers: lineNumbers.value,
          firstLine: start,
          highlightLines: callOut.value ? {start + 2, start + 3} : const {},
          wrap: wrap.value,
          copyable: copyable.value,
        ),
      );
    },
  );
}
