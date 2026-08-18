import '../src/story.dart';
import 'controls/button.dart';
import 'controls/checkbox.dart';
import 'controls/radio.dart';
import 'controls/select.dart';
import 'controls/switch.dart';
import 'controls/text_field.dart';
import 'foundation/placeholder.dart';
import 'foundation/scaffold.dart';
import 'foundation/surface.dart';
import 'overlays/menu.dart';
import 'overlays/popover.dart';
import 'overlays/tooltip.dart';
import 'text/code_text.dart';
import 'text/link.dart';
import 'text/semantic_text.dart';
import 'tokens.dart';

/// Everything the playground knows how to preview. One file per widget,
/// laid out the way `package:tomeui` lays out the widgets themselves.
List<StoryGroup> buildStories() => [
  tokenStories(),
  surfaceStories(),
  scaffoldStories(),
  buttonStories(),
  checkboxStories(),
  radioStories(),
  switchStories(),
  popoverStories(),
  selectStories(),
  textFieldStories(),
  textStories(),
  linkStories(),
  codeTextStories(),
  menuStories(),
  tooltipStories(),
  placeholderStories(),
];
