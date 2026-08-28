import 'package:tomeui/tomeui.dart';

/// The App tab's state: the global theme the canvas previews under.
///
/// Holds a brightness and a real [Swatch] per [SemanticSwatch] role, and
/// builds the [Theme] the canvas wraps every story in.
class ThemeConfig extends ChangeNotifier {
  Brightness _brightness = Brightness.dark;
  final Map<SemanticSwatch, Swatch> _swatches = {
    for (final role in SemanticSwatch.values) role: const Palette().of(role),
  };

  Brightness get brightness => _brightness;
  set brightness(Brightness value) {
    if (value == _brightness) return;
    _brightness = value;
    notifyListeners();
  }

  Swatch operator [](SemanticSwatch role) => _swatches[role]!;

  void setSwatch(SemanticSwatch role, Swatch swatch) {
    if (_swatches[role] == swatch) return;
    _swatches[role] = swatch;
    notifyListeners();
  }

  Theme get theme => Theme(
    palette: Palette(
      brightness: _brightness,
      primary: this[SemanticSwatch.primary],
      accent: this[SemanticSwatch.accent],
      neutral: this[SemanticSwatch.neutral],
      info: this[SemanticSwatch.info],
      warning: this[SemanticSwatch.warning],
      success: this[SemanticSwatch.success],
      error: this[SemanticSwatch.error],
    ),
  );
}

/// Every named swatch the toolkit ships, for the App tab's pickers.
const namedSwatches = <String, Swatch>{
  'red': Swatch.red,
  'orange': Swatch.orange,
  'amber': Swatch.amber,
  'yellow': Swatch.yellow,
  'lime': Swatch.lime,
  'green': Swatch.green,
  'emerald': Swatch.emerald,
  'teal': Swatch.teal,
  'cyan': Swatch.cyan,
  'sky': Swatch.sky,
  'blue': Swatch.blue,
  'indigo': Swatch.indigo,
  'violet': Swatch.violet,
  'purple': Swatch.purple,
  'fuchsia': Swatch.fuchsia,
  'pink': Swatch.pink,
  'rose': Swatch.rose,
  'slate': Swatch.slate,
  'gray': Swatch.gray,
  'zinc': Swatch.zinc,
  'ash': Swatch.ash,
  'stone': Swatch.stone,
  'mauve': Swatch.mauve,
  'olive': Swatch.olive,
  'mist': Swatch.mist,
  'taupe': Swatch.taupe,
};
