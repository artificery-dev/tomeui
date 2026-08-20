import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: child));

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

  testWidgets('it centres itself in whatever it is given', (tester) async {
    await pump(tester, const EmptyState(title: Text('Nothing here')));

    expect(
      tester.getCenter(find.text('Nothing here')).dx,
      moreOrLessEquals(tester.getCenter(find.byType(TomeApp)).dx, epsilon: 1),
    );
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
