import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  testWidgets('the glyph follows the meaning when none was named', (
    tester,
  ) async {
    const icons = Icons();
    for (final (swatch, glyph) in [
      (SemanticSwatch.success, icons.success),
      (SemanticSwatch.warning, icons.warning),
      (SemanticSwatch.error, icons.error),
      (SemanticSwatch.info, icons.info),
      (SemanticSwatch.primary, icons.info),
    ]) {
      await pump(tester, Callout(swatch: swatch, title: const Text('x')));
      expect(find.byIcon(glyph), findsOneWidget, reason: '$swatch');
    }
  });

  testWidgets('a glyph named outright wins', (tester) async {
    await pump(
      tester,
      Callout(icon: const Icons().favorite, title: const Text('x')),
    );
    expect(find.byIcon(const Icons().favorite), findsOneWidget);
  });

  testWidgets('title, message, actions, in that order down the block', (
    tester,
  ) async {
    await pump(
      tester,
      SizedBox(
        width: 400,
        child: Callout(
          title: const Text('Unsigned'),
          message: const Text('Nothing sails until it is.'),
          actions: [Button(onPressed: () {}, center: const Text('Sign'))],
        ),
      ),
    );

    final title = tester.getRect(find.text('Unsigned'));
    final message = tester.getRect(find.text('Nothing sails until it is.'));
    expect(message.top, greaterThan(title.top));
    expect(tester.getRect(find.text('Sign')).top, greaterThan(message.top));
  });

  testWidgets('it wears the swatch as a tint', (tester) async {
    await pump(
      tester,
      const Callout(swatch: SemanticSwatch.warning, title: Text('x')),
    );

    final surface = tester.widget<Surface>(
      find.descendant(of: find.byType(Callout), matching: find.byType(Surface)),
    );
    expect(
      surface.style,
      const Theme().widgets.callout.resolve(SemanticSwatch.warning).surface,
    );
  });

  testWidgets('one that can be put away grows a way to do it', (tester) async {
    var dismissed = 0;
    await pump(
      tester,
      SizedBox(
        width: 400,
        child: Callout(
          title: const Text('Unsigned'),
          onDismiss: () => dismissed++,
        ),
      ),
    );

    expect(find.byIcon(const Icons().close), findsOneWidget);
    await tester.tap(find.byIcon(const Icons().close));
    await tester.pump();
    expect(dismissed, 1);
  });

  testWidgets('one that cannot has no such button', (tester) async {
    await pump(tester, const Callout(title: Text('Unsigned')));
    expect(find.byIcon(const Icons().close), findsNothing);
  });
}
