import 'package:flutter/widgets.dart';

/// The semantic swatch a [Surface] or other widget wears.
enum SemanticSwatch {
  /// The brand at full voice — primary actions, focus, selection. The
  /// default when a surface doesn't say otherwise.
  primary,

  /// The brand's second voice — highlights and flourishes where [primary]
  /// would shout.
  accent,

  /// The grays — chrome, containers, anything that shouldn't compete with
  /// the content it holds.
  neutral,

  /// Something worth knowing — notices, hints, the calm end of feedback.
  info,

  /// Something worth pausing over — caution, before it becomes [error].
  warning,

  /// Something that went right — confirmations, completions, the all-clear.
  success,

  /// Something that went wrong — validation faults, failures, destructive
  /// actions.
  error,
}

/// A Tailwind-style ramp of colors from lightest to darkest.
///
/// `s50`..`s950` follow Tailwind's own scale. `s0` and `s1000` are bookends
/// we add beyond it: true black/white, versus the slightly tinted `s50`/
/// `s950`.
///
/// The full Tailwind CSS default palette is available as static constants
/// (`Swatch.red`, `Swatch.slate`, ...); build your own with [Swatch.custom].
@immutable
class Swatch {
  const Swatch.custom({
    this.s0 = const Color(0xFFFFFFFF),
    required this.s50,
    required this.s100,
    required this.s200,
    required this.s300,
    required this.s400,
    required this.s500,
    required this.s600,
    required this.s700,
    required this.s800,
    required this.s900,
    required this.s950,
    this.s1000 = const Color(0xFF000000),
  });

  final Color s0;
  final Color s50;
  final Color s100;
  final Color s200;
  final Color s300;
  final Color s400;
  final Color s500;
  final Color s600;
  final Color s700;
  final Color s800;
  final Color s900;
  final Color s950;
  final Color s1000;

  static const List<double> _stops = [
    0,
    50,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    950,
    1000,
  ];

  List<Color> get _colors => [
    s0,
    s50,
    s100,
    s200,
    s300,
    s400,
    s500,
    s600,
    s700,
    s800,
    s900,
    s950,
    s1000,
  ];

  /// Returns the color at [stop], interpolating between the two nearest
  /// defined stops when [stop] doesn't land exactly on one (e.g. `s[137.5]`
  /// sits between `s100` and `s200`). Values outside 0-1000 clamp to
  /// [s0]/[s1000].
  Color operator [](num stop) {
    final value = stop.clamp(0, 1000).toDouble();
    final colors = _colors;
    for (var i = 0; i < _stops.length - 1; i++) {
      final lower = _stops[i];
      final upper = _stops[i + 1];
      if (value >= lower && value <= upper) {
        final t = upper == lower ? 0.0 : (value - lower) / (upper - lower);
        return Color.lerp(colors[i], colors[i + 1], t)!;
      }
    }
    return s1000;
  }

  /// WCAG AA contrast ratio for normal text (4.5:1).
  static const double _minTextContrast = 4.5;

  /// A readable foreground color for content drawn on top of this swatch's
  /// color at [stop] -- [s50] or [s950], never the pure-black/white [s0]/
  /// [s1000] bookends.
  ///
  /// Prefers [s50] (light text reads better than dark on saturated brand
  /// colors, e.g. a `primary` button) and only falls back to [s950] when
  /// [s50] doesn't clear [minContrast] against the background -- e.g. a
  /// light color like `amber` or `yellow` at typical button-fill stops.
  ///
  /// `SurfaceTheme` doesn't actually use this for the `solid` variant --
  /// it fixes light/dark text per theme mode instead and picks a
  /// `variantBaseStop` known to keep that readable across every palette
  /// (see `SurfaceTheme`'s class doc). This stays around as a general
  /// per-instance contrast pick for arbitrary swatch/stop combinations.
  Color contrastFor(num stop, {double minContrast = _minTextContrast}) {
    final background = this[stop];
    if (contrastRatio(background, s50) >= minContrast) {
      return s50;
    }
    return s950;
  }

  // The Tailwind CSS default palette, converted from the OKLCH values in
  // https://tailwindcss.com/docs/colors (v4.3) to sRGB.

  static const red = Swatch.custom(
    s50: Color(0xFFFEF2F2),
    s100: Color(0xFFFFE2E2),
    s200: Color(0xFFFFC9C9),
    s300: Color(0xFFFFA2A2),
    s400: Color(0xFFFF6467),
    s500: Color(0xFFFB2C36),
    s600: Color(0xFFE7000B),
    s700: Color(0xFFC10007),
    s800: Color(0xFF9F0712),
    s900: Color(0xFF82181A),
    s950: Color(0xFF460809),
  );

  static const orange = Swatch.custom(
    s50: Color(0xFFFFF7ED),
    s100: Color(0xFFFFEDD4),
    s200: Color(0xFFFFD6A7),
    s300: Color(0xFFFFB86A),
    s400: Color(0xFFFF8904),
    s500: Color(0xFFFF6900),
    s600: Color(0xFFF54900),
    s700: Color(0xFFCA3500),
    s800: Color(0xFF9F2D00),
    s900: Color(0xFF7E2A0C),
    s950: Color(0xFF441306),
  );

  static const amber = Swatch.custom(
    s50: Color(0xFFFFFBEB),
    s100: Color(0xFFFEF3C6),
    s200: Color(0xFFFEE685),
    s300: Color(0xFFFFD230),
    s400: Color(0xFFFFB900),
    s500: Color(0xFFFE9A00),
    s600: Color(0xFFE17100),
    s700: Color(0xFFBB4D00),
    s800: Color(0xFF973C00),
    s900: Color(0xFF7B3306),
    s950: Color(0xFF461901),
  );

  static const yellow = Swatch.custom(
    s50: Color(0xFFFEFCE8),
    s100: Color(0xFFFEF9C2),
    s200: Color(0xFFFFF085),
    s300: Color(0xFFFFDF20),
    s400: Color(0xFFFDC700),
    s500: Color(0xFFF0B100),
    s600: Color(0xFFD08700),
    s700: Color(0xFFA65F00),
    s800: Color(0xFF894B00),
    s900: Color(0xFF733E0A),
    s950: Color(0xFF432004),
  );

  static const lime = Swatch.custom(
    s50: Color(0xFFF7FEE7),
    s100: Color(0xFFECFCCA),
    s200: Color(0xFFD8F999),
    s300: Color(0xFFBBF451),
    s400: Color(0xFF9AE600),
    s500: Color(0xFF7CCF00),
    s600: Color(0xFF5EA500),
    s700: Color(0xFF497D00),
    s800: Color(0xFF3C6300),
    s900: Color(0xFF35530E),
    s950: Color(0xFF192E03),
  );

  static const green = Swatch.custom(
    s50: Color(0xFFF0FDF4),
    s100: Color(0xFFDCFCE7),
    s200: Color(0xFFB9F8CF),
    s300: Color(0xFF7BF1A8),
    s400: Color(0xFF05DF72),
    s500: Color(0xFF00C950),
    s600: Color(0xFF00A63E),
    s700: Color(0xFF008236),
    s800: Color(0xFF016630),
    s900: Color(0xFF0D542B),
    s950: Color(0xFF032E15),
  );

  static const emerald = Swatch.custom(
    s50: Color(0xFFECFDF5),
    s100: Color(0xFFD0FAE5),
    s200: Color(0xFFA4F4CF),
    s300: Color(0xFF5EE9B5),
    s400: Color(0xFF00D492),
    s500: Color(0xFF00BC7D),
    s600: Color(0xFF009966),
    s700: Color(0xFF007A55),
    s800: Color(0xFF006045),
    s900: Color(0xFF004F3B),
    s950: Color(0xFF002C22),
  );

  static const teal = Swatch.custom(
    s50: Color(0xFFF0FDFA),
    s100: Color(0xFFCBFBF1),
    s200: Color(0xFF96F7E4),
    s300: Color(0xFF46ECD5),
    s400: Color(0xFF00D5BE),
    s500: Color(0xFF00BBA7),
    s600: Color(0xFF009689),
    s700: Color(0xFF00786F),
    s800: Color(0xFF005F5A),
    s900: Color(0xFF0B4F4A),
    s950: Color(0xFF022F2E),
  );

  static const cyan = Swatch.custom(
    s50: Color(0xFFECFEFF),
    s100: Color(0xFFCEFAFE),
    s200: Color(0xFFA2F4FD),
    s300: Color(0xFF53EAFD),
    s400: Color(0xFF00D3F2),
    s500: Color(0xFF00B8DB),
    s600: Color(0xFF0092B8),
    s700: Color(0xFF007595),
    s800: Color(0xFF005F78),
    s900: Color(0xFF104E64),
    s950: Color(0xFF053345),
  );

  static const sky = Swatch.custom(
    s50: Color(0xFFF0F9FF),
    s100: Color(0xFFDFF2FE),
    s200: Color(0xFFB8E6FE),
    s300: Color(0xFF74D4FF),
    s400: Color(0xFF00BCFF),
    s500: Color(0xFF00A6F4),
    s600: Color(0xFF0084D1),
    s700: Color(0xFF0069A8),
    s800: Color(0xFF00598A),
    s900: Color(0xFF024A70),
    s950: Color(0xFF052F4A),
  );

  static const blue = Swatch.custom(
    s50: Color(0xFFEFF6FF),
    s100: Color(0xFFDBEAFE),
    s200: Color(0xFFBEDBFF),
    s300: Color(0xFF8EC5FF),
    s400: Color(0xFF51A2FF),
    s500: Color(0xFF2B7FFF),
    s600: Color(0xFF155DFC),
    s700: Color(0xFF1447E6),
    s800: Color(0xFF193CB8),
    s900: Color(0xFF1C398E),
    s950: Color(0xFF162456),
  );

  static const indigo = Swatch.custom(
    s50: Color(0xFFEEF2FF),
    s100: Color(0xFFE0E7FF),
    s200: Color(0xFFC6D2FF),
    s300: Color(0xFFA3B3FF),
    s400: Color(0xFF7C86FF),
    s500: Color(0xFF615FFF),
    s600: Color(0xFF4F39F6),
    s700: Color(0xFF432DD7),
    s800: Color(0xFF372AAC),
    s900: Color(0xFF312C85),
    s950: Color(0xFF1E1A4D),
  );

  static const violet = Swatch.custom(
    s50: Color(0xFFF5F3FF),
    s100: Color(0xFFEDE9FE),
    s200: Color(0xFFDDD6FF),
    s300: Color(0xFFC4B4FF),
    s400: Color(0xFFA684FF),
    s500: Color(0xFF8E51FF),
    s600: Color(0xFF7F22FE),
    s700: Color(0xFF7008E7),
    s800: Color(0xFF5D0EC0),
    s900: Color(0xFF4D179A),
    s950: Color(0xFF2F0D68),
  );

  static const purple = Swatch.custom(
    s50: Color(0xFFFAF5FF),
    s100: Color(0xFFF3E8FF),
    s200: Color(0xFFE9D4FF),
    s300: Color(0xFFDAB2FF),
    s400: Color(0xFFC27AFF),
    s500: Color(0xFFAD46FF),
    s600: Color(0xFF9810FA),
    s700: Color(0xFF8200DB),
    s800: Color(0xFF6E11B0),
    s900: Color(0xFF59168B),
    s950: Color(0xFF3C0366),
  );

  static const fuchsia = Swatch.custom(
    s50: Color(0xFFFDF4FF),
    s100: Color(0xFFFAE8FF),
    s200: Color(0xFFF6CFFF),
    s300: Color(0xFFF4A8FF),
    s400: Color(0xFFED6AFF),
    s500: Color(0xFFE12AFB),
    s600: Color(0xFFC800DE),
    s700: Color(0xFFA800B7),
    s800: Color(0xFF8A0194),
    s900: Color(0xFF721378),
    s950: Color(0xFF4B004F),
  );

  static const pink = Swatch.custom(
    s50: Color(0xFFFDF2F8),
    s100: Color(0xFFFCE7F3),
    s200: Color(0xFFFCCEE8),
    s300: Color(0xFFFDA5D5),
    s400: Color(0xFFFB64B6),
    s500: Color(0xFFF6339A),
    s600: Color(0xFFE60076),
    s700: Color(0xFFC6005C),
    s800: Color(0xFFA3004C),
    s900: Color(0xFF861043),
    s950: Color(0xFF510424),
  );

  static const rose = Swatch.custom(
    s50: Color(0xFFFFF1F2),
    s100: Color(0xFFFFE4E6),
    s200: Color(0xFFFFCCD3),
    s300: Color(0xFFFFA1AD),
    s400: Color(0xFFFF637E),
    s500: Color(0xFFFF2056),
    s600: Color(0xFFEC003F),
    s700: Color(0xFFC70036),
    s800: Color(0xFFA50036),
    s900: Color(0xFF8B0836),
    s950: Color(0xFF4D0218),
  );

  static const slate = Swatch.custom(
    s50: Color(0xFFF8FAFC),
    s100: Color(0xFFF1F5F9),
    s200: Color(0xFFE2E8F0),
    s300: Color(0xFFCAD5E2),
    s400: Color(0xFF90A1B9),
    s500: Color(0xFF62748E),
    s600: Color(0xFF45556C),
    s700: Color(0xFF314158),
    s800: Color(0xFF1D293D),
    s900: Color(0xFF0F172B),
    s950: Color(0xFF020618),
  );

  static const gray = Swatch.custom(
    s50: Color(0xFFF9FAFB),
    s100: Color(0xFFF3F4F6),
    s200: Color(0xFFE5E7EB),
    s300: Color(0xFFD1D5DC),
    s400: Color(0xFF99A1AF),
    s500: Color(0xFF6A7282),
    s600: Color(0xFF4A5565),
    s700: Color(0xFF364153),
    s800: Color(0xFF1E2939),
    s900: Color(0xFF101828),
    s950: Color(0xFF030712),
  );

  static const zinc = Swatch.custom(
    s50: Color(0xFFFAFAFA),
    s100: Color(0xFFF4F4F5),
    s200: Color(0xFFE4E4E7),
    s300: Color(0xFFD4D4D8),
    s400: Color(0xFF9F9FA9),
    s500: Color(0xFF71717B),
    s600: Color(0xFF52525C),
    s700: Color(0xFF3F3F46),
    s800: Color(0xFF27272A),
    s900: Color(0xFF18181B),
    s950: Color(0xFF09090B),
  );

  // Tailwind calls this set "neutral", but that name is the palette's
  // semantic role here — the gray wears "ash" instead.
  static const ash = Swatch.custom(
    s50: Color(0xFFFAFAFA),
    s100: Color(0xFFF5F5F5),
    s200: Color(0xFFE5E5E5),
    s300: Color(0xFFD4D4D4),
    s400: Color(0xFFA1A1A1),
    s500: Color(0xFF737373),
    s600: Color(0xFF525252),
    s700: Color(0xFF404040),
    s800: Color(0xFF262626),
    s900: Color(0xFF171717),
    s950: Color(0xFF0A0A0A),
  );

  static const stone = Swatch.custom(
    s50: Color(0xFFFAFAF9),
    s100: Color(0xFFF5F5F4),
    s200: Color(0xFFE7E5E4),
    s300: Color(0xFFD6D3D1),
    s400: Color(0xFFA6A09B),
    s500: Color(0xFF79716B),
    s600: Color(0xFF57534D),
    s700: Color(0xFF44403B),
    s800: Color(0xFF292524),
    s900: Color(0xFF1C1917),
    s950: Color(0xFF0C0A09),
  );

  static const mauve = Swatch.custom(
    s50: Color(0xFFFAFAFA),
    s100: Color(0xFFF3F1F3),
    s200: Color(0xFFE7E4E7),
    s300: Color(0xFFD7D0D7),
    s400: Color(0xFFA89EA9),
    s500: Color(0xFF79697B),
    s600: Color(0xFF594C5B),
    s700: Color(0xFF463947),
    s800: Color(0xFF2A212C),
    s900: Color(0xFF1D161E),
    s950: Color(0xFF0C090C),
  );

  static const olive = Swatch.custom(
    s50: Color(0xFFFBFBF9),
    s100: Color(0xFFF4F4F0),
    s200: Color(0xFFE8E8E3),
    s300: Color(0xFFD8D8D0),
    s400: Color(0xFFABAB9C),
    s500: Color(0xFF7C7C67),
    s600: Color(0xFF5B5B4B),
    s700: Color(0xFF474739),
    s800: Color(0xFF2B2B22),
    s900: Color(0xFF1D1D16),
    s950: Color(0xFF0C0C09),
  );

  static const mist = Swatch.custom(
    s50: Color(0xFFF9FBFB),
    s100: Color(0xFFF1F3F3),
    s200: Color(0xFFE3E7E8),
    s300: Color(0xFFD0D6D8),
    s400: Color(0xFF9CA8AB),
    s500: Color(0xFF67787C),
    s600: Color(0xFF4B585B),
    s700: Color(0xFF394447),
    s800: Color(0xFF22292B),
    s900: Color(0xFF161B1D),
    s950: Color(0xFF090B0C),
  );

  static const taupe = Swatch.custom(
    s50: Color(0xFFFBFAF9),
    s100: Color(0xFFF3F1F1),
    s200: Color(0xFFE8E4E3),
    s300: Color(0xFFD8D2D0),
    s400: Color(0xFFABA09C),
    s500: Color(0xFF7C6D67),
    s600: Color(0xFF5B4F4B),
    s700: Color(0xFF473C39),
    s800: Color(0xFF2B2422),
    s900: Color(0xFF1D1816),
    s950: Color(0xFF0C0A09),
  );

  /// Every swatch above, by the name it is written with.
  ///
  /// A palette that can be chosen has to survive being written down - a
  /// settings file holds "sky", not a ramp of twelve colors - so the names
  /// are part of the API rather than a detail of how they were declared.
  static const Map<String, Swatch> named = {
    'red': red,
    'orange': orange,
    'amber': amber,
    'yellow': yellow,
    'lime': lime,
    'green': green,
    'emerald': emerald,
    'teal': teal,
    'cyan': cyan,
    'sky': sky,
    'blue': blue,
    'indigo': indigo,
    'violet': violet,
    'purple': purple,
    'fuchsia': fuchsia,
    'pink': pink,
    'rose': rose,
    'slate': slate,
    'gray': gray,
    'zinc': zinc,
    'ash': ash,
    'stone': stone,
    'mauve': mauve,
    'olive': olive,
    'mist': mist,
    'taupe': taupe,
  };

  /// The swatch [name] stands for, or null where nothing does. Callers
  /// reading a stored value take their own default for null rather than
  /// being handed one, because what "default" means is theirs to say.
  static Swatch? byName(String? name) => name == null ? null : named[name];

  /// The colors, in the order the ramp runs round the wheel. Suitable for
  /// anything offering a choice of brand color.
  static const List<String> colorNames = [
    'red',
    'orange',
    'amber',
    'yellow',
    'lime',
    'green',
    'emerald',
    'teal',
    'cyan',
    'sky',
    'blue',
    'indigo',
    'violet',
    'purple',
    'fuchsia',
    'pink',
    'rose',
  ];

  /// The grays, warm to cool. What a neutral is chosen from.
  static const List<String> grayNames = [
    'slate',
    'gray',
    'zinc',
    'ash',
    'stone',
    'mauve',
    'olive',
    'mist',
    'taupe',
  ];
}

/// WCAG relative-luminance contrast ratio between two colors, in `[1, 21]`.
/// How far apart two colors are to the eye, as the WCAG ratio: 1 is the
/// same color, 21 is black against white.
///
/// The measure a widget uses to ask whether what it is about to paint will
/// be seen at all — a swatch handed to something drawn *on* that swatch is
/// a color painting itself.
double contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}
