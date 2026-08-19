import '../src/story.dart';
import 'controls/button.dart';
import 'controls/checkbox.dart';
import 'controls/radio.dart';
import 'controls/segmented_control.dart';
import 'controls/select.dart';
import 'controls/slider.dart';
import 'controls/switch.dart';
import 'controls/text_field.dart';
import 'foundation/placeholder.dart';
import 'foundation/scaffold.dart';
import 'foundation/surface.dart';
import 'overlays/menu.dart';
import 'overlays/popover.dart';
import 'overlays/tooltip.dart';
import 'text/code_text.dart';
import 'text/kicker_text.dart';
import 'text/link.dart';
import 'text/semantic_text.dart';
import 'tokens.dart';

/// Everything the playground knows how to preview. One file per widget,
/// laid out the way `package:tomeui` lays out the widgets themselves:
/// categories in the order you meet them, widgets alphabetical within one.
List<StoryCategory> buildStories() => [
  StoryCategory(name: 'Theme', stories: tokenStories()),
  StoryCategory(
    name: 'Foundation',
    groups: [placeholderStories(), scaffoldStories(), surfaceStories()],
  ),
  StoryCategory(
    name: 'Controls',
    groups: [
      buttonStories(),
      checkboxStories(),
      radioStories(),
      segmentedControlStories(),
      selectStories(),
      sliderStories(),
      switchStories(),
      textFieldStories(),
    ],
  ),
  StoryCategory(
    name: 'Text',
    groups: [
      codeTextStories(),
      kickerTextStories(),
      linkStories(),
      semanticTextStories(),
    ],
  ),
  StoryCategory(
    name: 'Overlays',
    groups: [menuStories(), popoverStories(), tooltipStories()],
  ),
];
