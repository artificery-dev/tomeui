import '../src/story.dart';
import 'controls/button.dart';
import 'controls/checkbox.dart';
import 'controls/radio.dart';
import 'controls/segmented_control.dart';
import 'controls/select.dart';
import 'controls/slider.dart';
import 'controls/switch.dart';
import 'controls/text_field.dart';
import 'feedback/badge.dart';
import 'feedback/callout.dart';
import 'feedback/empty_state.dart';
import 'feedback/progress.dart';
import 'feedback/skeleton.dart';
import 'feedback/status_chip.dart';
import 'feedback/toast.dart';
import 'foundation/placeholder.dart';
import 'foundation/scaffold.dart';
import 'foundation/surface.dart';
import 'layout/breakpoint_builder.dart';
import 'layout/button_group.dart';
import 'layout/card.dart';
import 'layout/container_size_builder.dart';
import 'layout/divider.dart';
import 'layout/inset.dart';
import 'layout/spacing.dart';
import 'navigation/back_button.dart';
import 'navigation/breadcrumbs.dart';
import 'navigation/command_palette.dart';
import 'navigation/dock.dart';
import 'navigation/menu_bar.dart';
import 'navigation/nav_list.dart';
import 'navigation/pagination.dart';
import 'navigation/tabs.dart';
import 'navigation/title_bar.dart';
import 'overlays/dialog.dart';
import 'overlays/menu.dart';
import 'overlays/popover.dart';
import 'overlays/sheet.dart';
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
    name: 'Layout',
    groups: [
      breakpointBuilderStories(),
      buttonGroupStories(),
      cardStories(),
      containerSizeBuilderStories(),
      dividerStories(),
      insetStories(),
      spacingStories(),
    ],
  ),
  StoryCategory(
    name: 'Navigation',
    groups: [
      backButtonStories(),
      breadcrumbsStories(),
      commandPaletteStories(),
      dockStories(),
      menuBarStories(),
      navListStories(),
      paginationStories(),
      tabsStories(),
      titleBarStories(),
    ],
  ),
  StoryCategory(
    name: 'Feedback',
    groups: [
      badgeStories(),
      calloutStories(),
      emptyStateStories(),
      progressStories(),
      skeletonStories(),
      statusChipStories(),
      toastStories(),
    ],
  ),
  StoryCategory(
    name: 'Overlays',
    groups: [
      dialogStories(),
      menuStories(),
      popoverStories(),
      sheetStories(),
      tooltipStories(),
    ],
  ),
];
