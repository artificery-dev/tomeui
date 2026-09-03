import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  /// The card inside its hairline — where the slots actually sit.
  Rect boxOf(WidgetTester tester) => tester.getRect(
    find.descendant(of: find.byType(Card), matching: find.byType(ClipRRect)),
  );

  testWidgets('one slot is a padded surface: the spacing is the inset', (
    tester,
  ) async {
    await pump(tester, const Card(content: Text('x')));

    final box = boxOf(tester);
    final content = tester.getRect(find.text('x'));
    expect(content.left - box.left, 16, reason: 'x4, the resolved spacing');
    expect(content.top - box.top, 16);
    expect(box.bottom - content.bottom, 16);
    expect(
      box.left - tester.getRect(find.byType(Card)).left,
      0,
      reason: 'the outline’s hairline is painted over the edge, not laid out',
    );
  });

  testWidgets('the stack keeps one gap between neighbors, not two', (
    tester,
  ) async {
    await pump(
      tester,
      const Card(header: Text('h'), content: Text('c'), footer: Text('f')),
    );

    expect(
      tester.getTopLeft(find.text('c')).dy -
          tester.getBottomLeft(find.text('h')).dy,
      16,
    );
    expect(
      tester.getTopLeft(find.text('f')).dy -
          tester.getBottomLeft(find.text('c')).dy,
      16,
    );
  });

  testWidgets('zero on a slot is full bleed, and its neighbor still keeps '
      'its own daylight', (tester) async {
    await pump(
      tester,
      const Card(
        header: Text('h'),
        headerSpacing: SpaceStep.none,
        content: Text('c'),
      ),
    );

    final box = boxOf(tester);
    final header = tester.getRect(find.text('h'));
    expect(header.top, box.top, reason: 'flush to the top');
    expect(header.left, box.left, reason: 'and to the edges beside it');
    expect(
      tester.getTopLeft(find.text('c')).dy - header.bottom,
      16,
      reason: 'the roomier of the pair wins the gap',
    );
  });

  testWidgets('a slot spacing of its own overrides the card’s', (tester) async {
    await pump(
      tester,
      const Card(
        spacing: SpaceStep.x2,
        content: Text('c'),
        footer: Text('f'),
        footerSpacing: SpaceStep.x8,
      ),
    );

    final box = boxOf(tester);
    expect(tester.getRect(find.text('c')).top - box.top, 8);
    expect(box.bottom - tester.getRect(find.text('f')).bottom, 32);
    expect(
      tester.getTopLeft(find.text('f')).dy -
          tester.getBottomLeft(find.text('c')).dy,
      32,
    );
  });

  testWidgets('leading and trailing bookend the stack', (tester) async {
    await pump(
      tester,
      const SizedBox(
        width: 400,
        child: Card(
          leading: Text('l'),
          content: Text('c'),
          trailing: Text('t'),
        ),
      ),
    );

    final box = boxOf(tester);
    final leading = tester.getRect(find.text('l'));
    final content = tester.getRect(find.text('c'));
    final trailing = tester.getRect(find.text('t'));
    expect(leading.left - box.left, 16);
    expect(content.left - leading.right, 16, reason: 'one gap between them');
    expect(trailing.left - content.right, 16);
    expect(box.right - trailing.right, 16);
  });

  testWidgets('it is a Surface, wearing the swatch it was given', (
    tester,
  ) async {
    await pump(
      tester,
      const Card(swatch: SemanticSwatch.error, content: Text('x')),
    );

    final surface = tester.widget<Surface>(
      find.descendant(of: find.byType(Card), matching: find.byType(Surface)),
    );
    const theme = Theme();
    expect(
      surface.style,
      theme.widgets.card.resolve(SemanticSwatch.error).surface,
    );
  });
}
