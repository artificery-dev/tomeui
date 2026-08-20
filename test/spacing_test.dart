import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: child));

  testWidgets('a column measures it down, and it takes no width across', (
    tester,
  ) async {
    await pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text('a'), Spacing(SpaceStep.x6), Text('b')],
      ),
    );

    expect(tester.getSize(find.byType(Spacing)), const Size(0, 24));
  });

  testWidgets('a row measures it across', (tester) async {
    await pump(
      tester,
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text('a'), Spacing(SpaceStep.x4), Text('b')],
      ),
    );

    expect(tester.getSize(find.byType(Spacing)), const Size(16, 0));
  });

  testWidgets('a list has no spacing parameter, and this stands in for it', (
    tester,
  ) async {
    await pump(
      tester,
      ListView(
        children: const [Text('a'), Spacing(SpaceStep.x8), Text('b')],
      ),
    );

    final size = tester.getSize(find.byType(Spacing));
    expect(size.height, 32);
    expect(
      size.width,
      tester.getSize(find.byType(ListView)).width,
      reason: 'a list gives its children a tight width',
    );
    expect(
      tester.getTopLeft(find.text('b')).dy - tester.getBottomLeft(find.text('a')).dy,
      32,
    );
  });

  testWidgets('an axis said outright beats the surroundings', (tester) async {
    await pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('a'),
          Spacing(SpaceStep.x4, axis: Axis.horizontal),
          Text('b'),
        ],
      ),
    );

    expect(tester.getSize(find.byType(Spacing)), const Size(16, 0));
  });
}
