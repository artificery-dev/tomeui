import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup cardStories() => StoryGroup(name: 'Card', stories: [_card()]);

/// Every slot filled, and the spacing knobs to prove the rule: one step
/// governs the whole card, a slot may say otherwise, and zero on a slot is
/// full bleed.
Story _card() {
  final spacing = ListKnob<SpaceStep>(
    'Spacing',
    SpaceStep.x4,
    options: SpaceStep.values,
    describe: (option) => option.name,
  );
  final header = BoolKnob('Header', true);
  final bleed = BoolKnob('Full-bleed header', false);
  final footer = BoolKnob('Footer', true);
  final leading = BoolKnob('Leading', false);
  final trailing = BoolKnob('Trailing', false);
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.outline,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.neutral,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'Card',
    knobs: [
      spacing,
      header,
      bleed,
      footer,
      leading,
      trailing,
      variant,
      swatch,
    ],
    builder: (context) => Center(
      child: SizedBox(
        width: 420,
        child: Card(
          spacing: spacing.value,
          variant: variant.value,
          swatch: swatch.value,
          // The stand-in for the photograph a real card would carry: with
          // its spacing at zero it runs to the corners, and the rounding
          // cuts it there.
          header: header.value
              ? (bleed.value
                    ? const Surface(
                        variant: SurfaceVariant.soft,
                        swatch: SemanticSwatch.accent,
                        child: SizedBox(height: 96, width: double.infinity),
                      )
                    : const TitleText('Manifest'))
              : null,
          headerSpacing: bleed.value ? SpaceStep.none : null,
          content: const BodyText(
            'Eight bells, wind freshening from the south-west. Cargo dry, '
            'crew accounted for.',
          ),
          footer: footer.value
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Button(
                      onPressed: () {},
                      variant: SurfaceVariant.ghost,
                      center: const Text('Discard'),
                    ),
                    const Spacing(SpaceStep.x2),
                    Button(onPressed: () {}, center: const Text('Sign')),
                  ],
                )
              : null,
          leading: leading.value
              ? Icon(ThemeProvider.of(context).icons.info)
              : null,
          trailing: trailing.value ? const CaptionText('08:00') : null,
        ),
      ),
    ),
  );
}
