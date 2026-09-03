import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.dark,
  }) => tester.pumpWidget(
    TomeApp(
      theme: Theme(palette: Palette(brightness: brightness)),
      home: Center(child: child),
    ),
  );

  BoxDecoration? decorationOf(WidgetTester tester) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byType(Surface),
                  matching: find.byType(Container),
                ),
              )
              .decoration
          as BoxDecoration?;

  /// The hairline lives in the foreground decoration — painted over the
  /// edge, never laid out, so a surface that gains its ring shifts nothing.
  BoxDecoration? ringOf(WidgetTester tester) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byType(Surface),
                  matching: find.byType(Container),
                ),
              )
              .foregroundDecoration
          as BoxDecoration?;

  testWidgets('solid wears the swatch: 500 in light, 400 in dark', (
    tester,
  ) async {
    await pump(
      tester,
      const Surface(swatch: SemanticSwatch.error, child: Text('x')),
      brightness: Brightness.light,
    );
    expect(decorationOf(tester)?.color, const Palette().error.s500);

    await pump(
      tester,
      const Surface(swatch: SemanticSwatch.error, child: Text('x')),
    );
    expect(decorationOf(tester)?.color, const Palette().error.s400);
  });

  testWidgets('wears the theme primary by default', (tester) async {
    await pump(tester, const Surface(child: Text('x')));
    expect(decorationOf(tester)?.color, const Palette().primary.s400);
  });

  testWidgets('speaks its foreground to text and icons', (tester) async {
    const theme = Theme();
    await pump(
      tester,
      Surface(child: Icon(theme.icons.info)),
      brightness: Brightness.light,
    );

    final expected = const Palette().primary.contrastFor(500);
    final element = tester.element(find.byType(Icon));
    expect(DefaultTextStyle.of(element).style.color, expected);
    expect(IconTheme.of(element).color, expected);
  });

  testWidgets('outline draws a hairline and no fill', (tester) async {
    await pump(
      tester,
      const Surface(
        variant: SurfaceVariant.outline,
        swatch: SemanticSwatch.success,
        child: Text('x'),
      ),
    );

    final decoration = decorationOf(tester);
    expect(decoration?.color, isNull);
    final side = (ringOf(tester)?.border as Border?)?.top;
    expect(side?.color, const Palette().success.s600);
    expect(side?.width, const Strokes().hairline);
  });

  testWidgets('the ring is painted, never laid out: a surface adds nothing '
      'to its child\u2019s size', (tester) async {
    // Two identical rows, one bare and one ringed: hovering a list row in
    // and out of an outlined surface must not shift its siblings.
    await pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 120, height: 34, child: Text('bare')),
          Surface(
            variant: SurfaceVariant.outline,
            child: SizedBox(width: 120, height: 34, child: Text('ringed')),
          ),
        ],
      ),
    );

    expect(
      tester.getSize(find.byType(Surface)),
      const Size(120, 34),
      reason: 'the hairline must not grow the row',
    );
  });

  testWidgets('ghost paints nothing but still has a voice', (tester) async {
    await pump(
      tester,
      const Surface(variant: SurfaceVariant.ghost, child: Text('x')),
    );

    final decoration = decorationOf(tester);
    expect(decoration?.color, isNull);
    expect(ringOf(tester), isNull);
    final element = tester.element(find.text('x'));
    expect(
      DefaultTextStyle.of(element).style.color,
      const Palette().primary.s300,
    );
  });

  testWidgets('placeholder dashes its border', (tester) async {
    await pump(
      tester,
      const Surface(variant: SurfaceVariant.placeholder, child: Text('x')),
    );

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(Surface),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paint.foregroundPainter, isNotNull);
    // Dashed edges are painted, not drawn as a box border.
    expect(decorationOf(tester)?.border, isNull);
    expect(ringOf(tester), isNull);
  });

  testWidgets('custom paints the style exactly as given', (tester) async {
    const radius = BorderRadius.all(Radius.circular(999));
    const style = SurfaceStyle(
      foreground: Color(0xFF123456),
      fill: Color(0xFF654321),
      radius: radius,
    );
    await pump(tester, const Surface.custom(style: style, child: Text('x')));

    final decoration = decorationOf(tester);
    expect(decoration?.color, const Color(0xFF654321));
    expect(decoration?.borderRadius, radius);
    final element = tester.element(find.text('x'));
    expect(DefaultTextStyle.of(element).style.color, const Color(0xFF123456));
  });

  test('the theme resolves: every variant names a foreground', () {
    for (final variant in SurfaceVariant.values) {
      for (final brightness in Brightness.values) {
        final theme = Theme(palette: Palette(brightness: brightness));
        final style = theme.widgets.surface.resolve(
          SemanticSwatch.accent,
          variant,
        );
        expect(style.foreground, isNotNull, reason: '$variant $brightness');
        if (variant == SurfaceVariant.placeholder) {
          expect(style.dashed, isTrue);
          expect(style.border, isNotNull);
        }
      }
    }
  });

  test('a two-swatch theme gets the default mapping for free', () {
    const theme = Theme(
      palette: Palette(primary: Swatch.rose, neutral: Swatch.stone),
    );
    expect(theme.widgets.surface.resolve().fill, Swatch.rose.s400);
    expect(
      theme.widgets.surface
          .resolve(SemanticSwatch.primary, SurfaceVariant.soft)
          .fill,
      Swatch.rose.s900,
    );
  });

  test('the semantic mapping is the palette\'s to change', () {
    const theme = Theme(palette: Palette(warning: Swatch.orange));
    expect(
      theme.widgets.surface.resolve(SemanticSwatch.warning).fill,
      Swatch.orange.s400,
    );
    // The untouched roles keep their defaults.
    expect(
      theme.widgets.surface.resolve(SemanticSwatch.error).fill,
      const Palette().error.s400,
    );
  });

  test('the tone mapping is configuration, not code', () {
    // A theme with opinions: solid runs deeper, and its text is pinned to
    // the neutral ramp instead of the contrast pick.
    const theme = Theme(
      styles: WidgetStyles(
        surface: SurfaceStyles(
          solid: SurfaceShades(
            fill: Shade(light: 600, dark: 300),
            foreground: Shade.fixed(50, on: Swatch.zinc),
          ),
        ),
      ),
    );

    final style = theme.widgets.surface.resolve(SemanticSwatch.accent);
    expect(style.fill, Swatch.blue.s300);
    expect(style.foreground, Swatch.zinc.s50);

    // Only the replaced mapping changed; soft still wears the default.
    expect(
      theme.widgets.surface
          .resolve(SemanticSwatch.accent, SurfaceVariant.soft)
          .fill,
      Swatch.blue.s900,
    );
  });

  test('the grays never paint the page onto the page', () {
    for (final brightness in Brightness.values) {
      final theme = Theme(palette: Palette(brightness: brightness));
      final page = theme.palette.background;
      for (final variant in [SurfaceVariant.soft, SurfaceVariant.subtle]) {
        expect(
          theme.widgets.surface.resolve(SemanticSwatch.neutral, variant).fill,
          isNot(page),
          reason: '$variant neutral in $brightness',
        );
      }
    }
  });

  test('an exception is one swatch\'s business, not the variant\'s', () {
    const theme = Theme();
    // The colors keep the variant's own stops...
    expect(
      theme.widgets.surface
          .resolve(SemanticSwatch.primary, SurfaceVariant.subtle)
          .fill,
      const Palette().primary.s950,
    );
    // ...while neutral wears the one named for it.
    expect(
      theme.widgets.surface
          .resolve(SemanticSwatch.neutral, SurfaceVariant.subtle)
          .fill,
      const Palette().neutral.s900,
    );
  });

  test('an exception is configuration too: a gray primary names its own', () {
    // A palette whose *primary* is a gray hits the same collision, and
    // answers it the same way — by naming an exception of its own.
    const theme = Theme(
      palette: Palette(primary: Swatch.zinc),
      styles: WidgetStyles(
        surface: SurfaceStyles(
          subtle: SurfaceShades(
            fill: Shade(light: 50, dark: 950),
            exceptions: {
              SemanticSwatch.primary: SurfaceShades(
                fill: Shade(light: 100, dark: 900),
              ),
            },
          ),
        ),
      ),
    );

    expect(
      theme.widgets.surface
          .resolve(SemanticSwatch.primary, SurfaceVariant.subtle)
          .fill,
      Swatch.zinc.s900,
    );
    // A swatch the exceptions don't name is untouched by them.
    expect(
      theme.widgets.surface
          .resolve(SemanticSwatch.error, SurfaceVariant.subtle)
          .fill,
      const Palette().error.s950,
    );
  });

  test('tokens are theme data: custom radii reach the resolved style', () {
    const round = BorderRadius.all(Radius.circular(24));
    const theme = Theme(radii: Radii(medium: round));
    expect(theme.widgets.surface.resolve().radius, round);
    // And the default theme still carries the default scale.
    expect(
      const Theme().widgets.surface.resolve().radius,
      const Radii().medium,
    );
  });

  test('shades interpolate off the named stops', () {
    const theme = Theme(
      styles: WidgetStyles(
        surface: SurfaceStyles(solid: SurfaceShades(fill: Shade.fixed(450))),
      ),
    );
    final fill = theme.widgets.surface.resolve(SemanticSwatch.accent).fill;
    expect(fill, isNot(Swatch.blue.s400));
    expect(fill, isNot(Swatch.blue.s500));
    expect(fill, Swatch.blue[450]);
  });
}
