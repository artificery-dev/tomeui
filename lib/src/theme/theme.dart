import 'package:tomeui/tomeui.dart';

export 'theme_provider.dart';
export 'tokens/tokens.dart';

/// Everything a Tome subtree inherits: the three swappable token sets.
///
/// Colour lives in [Palette], glyphs in [Icons], type in [Typography] — the
/// theme is just the bundle a [ThemeProvider] hands down, so each set swaps
/// independently and a custom theme states only its differences.
@immutable
class Theme {
  const Theme({
    this.palette = const Palette(),
    this.icons = const Icons(),
    this.typography = const Typography(),
  });

  final Palette palette;
  final Icons icons;
  final Typography typography;

  Theme copyWith({Palette? palette, Icons? icons, Typography? typography}) =>
      Theme(
        palette: palette ?? this.palette,
        icons: icons ?? this.icons,
        typography: typography ?? this.typography,
      );

  @override
  bool operator ==(Object other) =>
      other is Theme &&
      other.palette == palette &&
      other.icons == icons &&
      other.typography == typography;

  @override
  int get hashCode => Object.hash(palette, icons, typography);
}
