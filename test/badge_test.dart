import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  testWidgets('a count says its number', (tester) async {
    await pump(tester, const Badge.count(3));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('past the most it counts, it stops counting', (tester) async {
    await pump(tester, const Badge.count(40));
    expect(find.text('9+'), findsOneWidget);

    await pump(tester, const Badge.count(40, max: 99));
    expect(find.text('40'), findsOneWidget, reason: 'still worth counting');

    await pump(tester, const Badge.count(140, max: 99));
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('nothing to report draws nothing at all', (tester) async {
    await pump(tester, const Badge.count(0, child: Text('inbox')));

    expect(find.text('0'), findsNothing);
    expect(find.text('inbox'), findsOneWidget, reason: 'what it rides on');
  });

  testWidgets('a dot is the fact without the number', (tester) async {
    await pump(tester, const Badge.dot());

    final style = const Theme().widgets.badge.resolve();
    expect(find.byType(Text), findsNothing);
    expect(
      tester.getSize(find.byType(Badge)),
      Size(style.dotSize, style.dotSize),
    );
  });

  testWidgets('riding on something, it sits past the top trailing corner', (
    tester,
  ) async {
    await pump(
      tester,
      const Badge.count(3, child: SizedBox.square(dimension: 40)),
    );

    final host = tester.getRect(find.byType(SizedBox).first);
    final mark = tester.getRect(find.text('3'));
    expect(mark.center.dx, greaterThan(host.center.dx));
    expect(mark.center.dy, lessThan(host.center.dy));
  });

  testWidgets('a label badge says whatever it was given', (tester) async {
    await pump(tester, const Badge.label(Text('NEW')));
    expect(find.text('NEW'), findsOneWidget);
  });

  testWidgets('it is solid, so it reads against what it rides on', (
    tester,
  ) async {
    await pump(tester, const Badge.count(1, swatch: SemanticSwatch.primary));

    final surface = tester.widget<Surface>(
      find.descendant(of: find.byType(Badge), matching: find.byType(Surface)),
    );
    expect(
      surface.style!.fill,
      const Theme().widgets.surface
          .resolve(SemanticSwatch.primary, SurfaceVariant.solid)
          .fill,
    );
  });
}
