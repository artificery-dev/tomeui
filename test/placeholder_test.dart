import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: child));

  testWidgets('fills the size its parent dictates, child centerd', (
    tester,
  ) async {
    await pump(tester, const Placeholder(child: Text('x')));

    final size = tester.getSize(find.byType(Placeholder));
    expect(size, tester.getSize(find.byType(TomeApp)));
    expect(
      tester.getCenter(find.text('x')),
      tester.getCenter(find.byType(Placeholder)),
    );
  });

  testWidgets('hugs its child under loose constraints', (tester) async {
    await pump(tester, const Center(child: Placeholder(child: Text('x'))));

    final size = tester.getSize(find.byType(Placeholder));
    expect(size, tester.getSize(find.text('x')));
  });

  testWidgets('padding grows the hug', (tester) async {
    await pump(
      tester,
      const Center(
        child: Placeholder(padding: EdgeInsets.all(12), child: Text('x')),
      ),
    );

    final text = tester.getSize(find.text('x'));
    expect(
      tester.getSize(find.byType(Placeholder)),
      Size(text.width + 24, text.height + 24),
    );
  });

  testWidgets('wears the placeholder variant: stripes behind, dashes on top', (
    tester,
  ) async {
    await pump(tester, const Placeholder(child: Text('x')));

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(Placeholder),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paint.foregroundPainter, isNotNull, reason: 'the dashed hairline');

    // The striped wash parts around the child.
    expect(
      find.descendant(
        of: find.byType(Placeholder),
        matching: find.byType(StripeGap),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(StripeGap), matching: find.text('x')),
      findsOneWidget,
    );

    // Stripes are painted, not decorated: the box itself carries no fill.
    final decoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(Placeholder),
                    matching: find.byType(Container),
                  ),
                )
                .decoration
            as BoxDecoration?;
    expect(decoration?.color, isNull);
  });

  test('the placeholder mapping stripes a faint fill by default', () {
    const theme = Theme();
    final style = theme.widgets.surface.resolve(
      SemanticSwatch.neutral,
      SurfaceVariant.placeholder,
    );
    expect(style.striped, isTrue);
    expect(style.fill, const Palette().neutral.s800);
  });
}
