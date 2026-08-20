import 'package:tomeui/tomeui.dart';

export 'styles/badge_style.dart';
export 'styles/breadcrumbs_style.dart';
export 'styles/button_style.dart';
export 'styles/callout_style.dart';
export 'styles/card_style.dart';
export 'styles/checkbox_style.dart';
export 'styles/chip_style.dart';
export 'styles/code_text_style.dart';
export 'styles/command_palette_style.dart';
export 'styles/dialog_style.dart';
export 'styles/divider_style.dart';
export 'styles/dock_style.dart';
export 'styles/empty_state_style.dart';
export 'styles/link_style.dart';
export 'styles/menu_bar_style.dart';
export 'styles/menu_style.dart';
export 'styles/nav_list_style.dart';
export 'styles/popover_style.dart';
export 'styles/progress_style.dart';
export 'styles/radio_style.dart';
export 'styles/scaffold_style.dart';
export 'styles/segmented_style.dart';
export 'styles/select_style.dart';
export 'styles/shade.dart';
export 'styles/sheet_style.dart';
export 'styles/skeleton_style.dart';
export 'styles/slider_style.dart';
export 'styles/surface_style.dart';
export 'styles/switch_style.dart';
export 'styles/tabs_style.dart';
export 'styles/text_field_style.dart';
export 'styles/text_style.dart';
export 'styles/title_bar_style.dart';
export 'styles/toast_style.dart';
export 'styles/widget_styles.dart';
export 'theme_provider.dart';
export 'tokens/tokens.dart';
export 'widgets.dart';

/// Everything a Tome subtree inherits: every token set, and the per-widget
/// style configuration that turns them into paint.
///
/// Each set is a const-constructible data class whose defaults are the
/// system's taste, so `const Theme()` is a complete theme and a custom one
/// states only its differences — a palette here, a denser [Space] there,
/// a tone mapping under [styles].
///
/// The theme is also where resolution lives: [widgets] bundles a resolver
/// per widget, so the shade choosing happens beside the brightness and
/// nowhere else:
///
/// ```dart
/// theme.widgets.surface.resolve(SemanticSwatch.error, SurfaceVariant.soft)
/// ```
@immutable
class Theme {
  const Theme({
    this.palette = const Palette(),
    this.icons = const Icons(),
    this.labels = const Labels(),
    this.typography = const Typography(),
    this.styles = const WidgetStyles(),
    this.space = const Space(),
    this.radii = const Radii(),
    this.sizes = const Sizes(),
    this.strokes = const Strokes(),
    this.opacities = const Opacities(),
    this.motion = const Motion(),
    this.shadows = const Shadows(),
    this.breakpoints = const Breakpoints(),
  });

  final Palette palette;
  final Icons icons;

  /// The words the toolkit says on its own account.
  final Labels labels;

  final Typography typography;

  /// The per-widget style configuration [widgets] resolves against.
  final WidgetStyles styles;

  final Space space;
  final Radii radii;
  final Sizes sizes;
  final Strokes strokes;
  final Opacities opacities;
  final Motion motion;
  final Shadows shadows;
  final Breakpoints breakpoints;

  /// The resolvers: `theme.widgets.surface.resolve(...)` and friends.
  Widgets get widgets => Widgets(this);

  Theme copyWith({
    Palette? palette,
    Icons? icons,
    Labels? labels,
    Typography? typography,
    WidgetStyles? styles,
    Space? space,
    Radii? radii,
    Sizes? sizes,
    Strokes? strokes,
    Opacities? opacities,
    Motion? motion,
    Shadows? shadows,
    Breakpoints? breakpoints,
  }) => Theme(
    palette: palette ?? this.palette,
    icons: icons ?? this.icons,
    labels: labels ?? this.labels,
    typography: typography ?? this.typography,
    styles: styles ?? this.styles,
    space: space ?? this.space,
    radii: radii ?? this.radii,
    sizes: sizes ?? this.sizes,
    strokes: strokes ?? this.strokes,
    opacities: opacities ?? this.opacities,
    motion: motion ?? this.motion,
    shadows: shadows ?? this.shadows,
    breakpoints: breakpoints ?? this.breakpoints,
  );

  @override
  bool operator ==(Object other) =>
      other is Theme &&
      other.palette == palette &&
      other.icons == icons &&
      other.labels == labels &&
      other.typography == typography &&
      other.styles == styles &&
      other.space == space &&
      other.radii == radii &&
      other.sizes == sizes &&
      other.strokes == strokes &&
      other.opacities == opacities &&
      other.motion == motion &&
      other.shadows == shadows &&
      other.breakpoints == breakpoints;

  @override
  int get hashCode => Object.hash(
    palette,
    icons,
    labels,
    typography,
    styles,
    space,
    radii,
    sizes,
    strokes,
    opacities,
    motion,
    shadows,
    breakpoints,
  );
}
