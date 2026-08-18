import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup textFieldStories() =>
    StoryGroup(name: 'TextField', stories: [_textField(), _multiLine()]);

Story _textField() {
  final label = StringKnob('Label', 'Port of call');
  final placeholder = StringKnob('Placeholder', 'Valparaíso');
  final helper = StringKnob('Helper', 'Where the cargo leaves the ship.');
  final error = StringKnob('Error', '');
  final leading = BoolKnob('Leading icon', false);
  final obscure = BoolKnob('Obscured', false);
  final disabled = BoolKnob('Disabled', false);
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.outline,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'TextField',
    knobs: [
      label,
      placeholder,
      helper,
      error,
      leading,
      obscure,
      disabled,
      variant,
      swatch,
    ],
    // Type in it: the field owns its own text unless handed a controller.
    builder: (context) => SizedBox(
      width: 320,
      child: TextField(
        label: label.value.isEmpty ? null : Text(label.value),
        placeholder: placeholder.value.isEmpty
            ? null
            : Text(placeholder.value),
        helper: helper.value.isEmpty ? null : Text(helper.value),
        // Anything in the error knob turns the whole field, box and all.
        error: error.value.isEmpty ? null : Text(error.value),
        leading: leading.value
            ? Icon(ThemeProvider.of(context).icons.search)
            : null,
        obscureText: obscure.value,
        enabled: !disabled.value,
        variant: variant.value,
        swatch: swatch.value,
      ),
    ),
  );
}

/// The multi-line shape: the box grows with the text instead of scrolling
/// it past a fixed height.
Story _multiLine() {
  final lines = DoubleKnob('Min lines', 3, min: 1, max: 8);

  return Story(
    name: 'Multi-line',
    knobs: [lines],
    builder: (_) => SizedBox(
      width: 360,
      child: TextField(
        label: const Text('Log entry'),
        placeholder: const Text('Eight bells, wind freshening…'),
        minLines: lines.value.round(),
        maxLines: null,
      ),
    ),
  );
}
