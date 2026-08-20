import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  testWidgets('a word in a pill, wearing the swatch softly', (tester) async {
    await pump(
      tester,
      const StatusChip(
        label: Text('Delivered'),
        swatch: SemanticSwatch.success,
      ),
    );

    final surface = tester.widget<Surface>(
      find.descendant(
        of: find.byType(StatusChip),
        matching: find.byType(Surface),
      ),
    );
    const theme = Theme();
    expect(
      surface.style,
      theme.widgets.chip.resolve(SemanticSwatch.success).surface,
    );
    expect(surface.style!.radius, theme.radii.full, reason: 'a stadium');
  });

  testWidgets('the height is the style’s, whatever the words', (tester) async {
    await pump(tester, const StatusChip(label: Text('Draft')));

    expect(
      tester.getSize(find.byType(StatusChip)).height,
      const Theme().widgets.chip.resolve().height,
    );
  });

  testWidgets('a dot wears the swatch at full voice against the soft fill', (
    tester,
  ) async {
    await pump(
      tester,
      const StatusChip(
        label: Text('Overdue'),
        dot: true,
        swatch: SemanticSwatch.error,
      ),
    );

    // The chip's own surface is a rectangle; the dot is the round one.
    final decoration = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(StatusChip),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((box) => box.shape == BoxShape.circle);
    expect(
      decoration.color,
      const Theme().widgets.surface
          .resolve(SemanticSwatch.error, SurfaceVariant.solid)
          .fill,
    );
  });

  testWidgets('a glyph goes where the dot would', (tester) async {
    await pump(
      tester,
      StatusChip(label: const Text('Sailing'), icon: const Icons().forward),
    );

    expect(find.byIcon(const Icons().forward), findsOneWidget);
    expect(
      tester.getRect(find.byIcon(const Icons().forward)).left,
      lessThan(tester.getRect(find.text('Sailing')).left),
    );
  });

  testWidgets('a glyph and a dot together is a mistake worth catching', (
    tester,
  ) async {
    expect(
      () => StatusChip(
        label: const Text('x'),
        icon: const Icons().info,
        dot: true,
      ),
      throwsAssertionError,
    );
  });
}
