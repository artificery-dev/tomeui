import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  // Loose constraints, the way callers hold a card: the panel hugs its
  // words and the Center does the placing.
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  testWidgets('glyph, title, message, and the one thing to do about it', (
    tester,
  ) async {
    await pump(
      tester,
      EmptyState(
        icon: const Icons().folder,
        title: const Text('No voyages yet'),
        message: const Text('Log the first one.'),
        action: Button(onPressed: () {}, center: const Text('Log a voyage')),
      ),
    );

    final glyph = tester.getRect(find.byIcon(const Icons().folder));
    final title = tester.getRect(find.text('No voyages yet'));
    final message = tester.getRect(find.text('Log the first one.'));
    final action = tester.getRect(find.text('Log a voyage'));
    expect(title.top, greaterThan(glyph.top));
    expect(message.top, greaterThan(title.top));
    expect(action.top, greaterThan(message.top));
  });

  testWidgets('it centers itself in whatever it is given', (tester) async {
    await pump(tester, const EmptyState(title: Text('Nothing here')));

    expect(
      tester.getCenter(find.text('Nothing here')).dx,
      moreOrLessEquals(tester.getCenter(find.byType(TomeApp)).dx, epsilon: 1),
    );
  });

  testWidgets('the panel is a card that hugs its words, not a wash', (
    tester,
  ) async {
    await pump(
      tester,
      EmptyState(
        icon: const Icons().folder,
        title: const Text('Nothing here'),
        action: Button(onPressed: () {}, center: const Text('Add one')),
      ),
    );

    final app = tester.getSize(find.byType(TomeApp));
    final panel = tester.getRect(find.byType(EmptyState));
    expect(panel.width, lessThan(app.width / 2));
    expect(panel.height, lessThan(app.height / 2));
    // And the caller's Center holds it in the middle of the room.
    expect(panel.center.dx, moreOrLessEquals(app.width / 2, epsilon: 1));
  });

  testWidgets('the faintest panel by default, and none when asked', (
    tester,
  ) async {
    final theme = const Theme();
    final panel = theme.widgets.emptyState.resolve().surface;
    final subtle = theme.widgets.surface.resolve(
      SemanticSwatch.neutral,
      SurfaceVariant.subtle,
    );
    expect(panel.fill, subtle.fill);
    expect(panel.border, subtle.border);
    expect(
      theme.widgets.emptyState
          .resolve(SemanticSwatch.neutral, SurfaceVariant.ghost)
          .surface
          .fill,
      isNull,
      reason: 'ghost is still the way to draw no panel at all',
    );

    await pump(
      tester,
      const EmptyState(
        variant: SurfaceVariant.outline,
        title: Text('Nothing here'),
      ),
    );

    final surface = tester.widget<Surface>(
      find
          .descendant(
            of: find.byType(EmptyState),
            matching: find.byType(Surface),
          )
          .first,
    );
    expect(
      surface.style,
      theme.widgets.emptyState
          .resolve(SemanticSwatch.neutral, SurfaceVariant.outline)
          .surface,
    );
  });

  test('the words keep the page\'s voice until the panel would swallow it', () {
    for (final brightness in Brightness.values) {
      final theme = Theme(palette: Palette(brightness: brightness));
      final quiet = theme.widgets.emptyState.resolve();
      expect(
        quiet.titleStyle.color,
        theme.palette.text,
        reason: 'a faint panel changes nothing about the heading',
      );

      // Whatever it lands on, the heading reads against the panel it is
      // printed on — which is the whole of the rule.
      for (final variant in SurfaceVariant.values) {
        for (final swatch in SemanticSwatch.values) {
          final style = theme.widgets.emptyState.resolve(swatch, variant);
          final fill = style.surface.fill;
          if (fill == null) continue;
          expect(
            contrastRatio(style.titleStyle.color!, fill),
            greaterThanOrEqualTo(4.5),
            reason: '$swatch $variant in $brightness',
          );
        }
      }
    }
  });

  test('a fill loud enough to swallow the page hands the words over', () {
    // Near-white on a bright sky-400 panel is not a heading anybody reads,
    // so a solid one speaks in the surface's own foreground instead.
    const theme = Theme();
    final loud = theme.widgets.emptyState.resolve(
      SemanticSwatch.primary,
      SurfaceVariant.solid,
    );
    expect(loud.titleStyle.color, loud.surface.foreground);
    expect(loud.titleStyle.color, isNot(theme.palette.text));
  });

  testWidgets('the words wrap at a readable measure, not the slot’s width', (
    tester,
  ) async {
    await pump(
      tester,
      const EmptyState(
        message: Text(
          'A long line of explanation that would run the whole width of a '
          'desktop window if nothing stopped it, which is not how anyone '
          'reads a sentence.',
        ),
      ),
    );

    final style = const Theme().widgets.emptyState.resolve();
    expect(
      tester.getSize(find.byType(Text)).width,
      lessThanOrEqualTo(style.maxWidth),
    );
  });

  testWidgets('the glyph is quiet: nothing has gone wrong', (tester) async {
    await pump(tester, EmptyState(icon: const Icons().folder));

    final icon = tester.widget<Icon>(find.byIcon(const Icons().folder));
    expect(icon.color, const Theme().widgets.emptyState.resolve().glyph);
  });

  testWidgets('a glyph and a picture together is a mistake worth catching', (
    tester,
  ) async {
    expect(
      () => EmptyState(
        icon: const Icons().folder,
        illustration: const SizedBox.shrink(),
      ),
      throwsAssertionError,
    );
  });
}
