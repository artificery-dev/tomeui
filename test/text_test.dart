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

  /// What actually reaches the painter: the role's type merged over
  /// whatever the surrounding surface said.
  /// Reached through the RichText rather than the Text, since text that
  /// carries its own semantics label sits under an annotation first.
  TextStyle painted(WidgetTester tester, String text) => tester
      .widget<RichText>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      )
      .text
      .style!;

  group('semantic text', () {
    testWidgets('each role carries its slice of the type scale', (
      tester,
    ) async {
      await pump(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DisplayText('D'),
            HeadlineText('H'),
            TitleText('T'),
            SubtitleText('S'),
            BodyText('B'),
            BodyText.small('b'),
            LabelText('L'),
            CaptionText('C'),
          ],
        ),
      );

      const type = Typography();
      expect(painted(tester, 'D').fontSize, type.display.fontSize);
      expect(painted(tester, 'H').fontSize, type.headline.fontSize);
      expect(painted(tester, 'T').fontSize, type.title.fontSize);
      expect(painted(tester, 'S').fontSize, type.subtitle.fontSize);
      expect(painted(tester, 'B').fontSize, type.body.fontSize);
      expect(painted(tester, 'b').fontSize, type.bodySmall.fontSize);
      expect(painted(tester, 'L').fontWeight, type.label.fontWeight);
      expect(painted(tester, 'C').fontSize, type.caption.fontSize);
    });

    testWidgets('colour comes from the surface, not from the widget', (
      tester,
    ) async {
      await pump(
        tester,
        const Surface(swatch: SemanticSwatch.error, child: BodyText('x')),
      );

      final surface = const Theme().widgets.surface.resolve(
        SemanticSwatch.error,
      );
      expect(painted(tester, 'x').color, surface.foreground);
    });

    testWidgets('emphasis grades that inherited colour', (tester) async {
      await pump(
        tester,
        const Surface(
          swatch: SemanticSwatch.error,
          child: BodyText('x', emphasis: TextEmphasis.secondary),
        ),
      );

      final foreground = const Theme().widgets.surface
          .resolve(SemanticSwatch.error)
          .foreground;
      expect(
        painted(tester, 'x').color,
        foreground.withValues(
          alpha: foreground.a * const Opacities().secondary,
        ),
      );
    });

    testWidgets('a swatch tints from the palette, per brightness', (
      tester,
    ) async {
      await pump(
        tester,
        const BodyText('x', swatch: SemanticSwatch.error),
        brightness: Brightness.light,
      );
      expect(painted(tester, 'x').color, const Palette().error[700]);

      await pump(tester, const BodyText('x', swatch: SemanticSwatch.error));
      expect(painted(tester, 'x').color, const Palette().error[300]);
    });

    testWidgets('style has the last word, and only over what it names', (
      tester,
    ) async {
      await pump(
        tester,
        const BodyText('x', style: TextStyle(fontWeight: FontWeight.w900)),
      );

      expect(painted(tester, 'x').fontWeight, FontWeight.w900);
      expect(painted(tester, 'x').fontSize, const Typography().body.fontSize);
    });

    testWidgets('captions and subtitles come quiet by default', (tester) async {
      await pump(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [CaptionText('C'), BodyText('B')],
        ),
      );

      final loud = painted(tester, 'B').color!;
      expect(
        painted(tester, 'C').color,
        loud.withValues(alpha: loud.a * const Opacities().secondary),
      );
    });

    testWidgets('the roles that structure a page announce as headings', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [TitleText('T'), BodyText('B')],
        ),
      );

      expect(
        tester.getSemantics(find.text('T')),
        matchesSemantics(label: 'T', isHeader: true),
      );
      expect(tester.getSemantics(find.text('B')), matchesSemantics(label: 'B'));
      semantics.dispose();
    });
  });

  group('KickerText', () {
    testWidgets('uppercases the paint, not the announcement', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const KickerText('Ship’s stores'));

      expect(find.text('SHIP’S STORES'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('SHIP’S STORES')).label,
        'Ship’s stores',
      );
      semantics.dispose();
    });

    testWidgets('stands its letters further apart than a label', (
      tester,
    ) async {
      await pump(tester, const KickerText('a'));

      const type = Typography();
      expect(
        painted(tester, 'A').letterSpacing,
        (type.label.letterSpacing ?? 0) + const TextStyles().kickerTracking,
      );
    });
  });
}
