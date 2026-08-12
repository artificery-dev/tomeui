import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  group('Swatch', () {
    test('indexes exact stops and the bookends', () {
      expect(Swatch.blue[500], Swatch.blue.s500);
      expect(Swatch.blue[0], const Color(0xFFFFFFFF));
      expect(Swatch.blue[1000], const Color(0xFF000000));
    });

    test('interpolates between stops and clamps beyond them', () {
      final between = Swatch.blue[150];
      expect(between, isNot(Swatch.blue.s100));
      expect(between, isNot(Swatch.blue.s200));
      expect(Swatch.blue[-40], Swatch.blue.s0);
      expect(Swatch.blue[1400], Swatch.blue.s1000);
    });

    test('picks a readable foreground for light and dark fills', () {
      // Light text on a saturated dark fill; dark text on a pale one.
      expect(Swatch.blue.contrastFor(600), Swatch.blue.s50);
      expect(Swatch.yellow.contrastFor(300), Swatch.yellow.s950);
    });
  });

  group('TomeIcons', () {
    test('defaults to the Lucide set', () {
      expect(const Icons().close, Icons.lucide.close);
    });

    test('swaps one glyph without touching the rest', () {
      const standIn = IconData(0x2715);
      const custom = Icons(close: standIn);
      expect(custom.close, isNot(Icons.lucide.close));
      expect(custom.copy, Icons.lucide.copy);

      final copied = Icons.lucide.copyWith(close: standIn);
      expect(copied.close, standIn);
      expect(copied.search, Icons.lucide.search);
    });
  });

  group('TomeTypography', () {
    test('styles carry no colour and no family, except code', () {
      const type = Typography.standard;
      for (final style in [
        type.display,
        type.headline,
        type.title,
        type.subtitle,
        type.body,
        type.bodySmall,
        type.label,
        type.caption,
      ]) {
        expect(style.color, isNull);
        expect(style.fontFamily, isNull);
      }
      expect(type.code.fontFamily, isNotNull);
    });

    test('copyWith swaps one style without touching the rest', () {
      final custom = Typography.standard.copyWith(
        body: const TextStyle(fontSize: 16),
      );
      expect(custom.body.fontSize, 16);
      expect(custom.caption, Typography.standard.caption);
    });
  });
}
