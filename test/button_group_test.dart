import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  Widget button(String label) =>
      Button(onPressed: () {}, center: Text(label), variant: SurfaceVariant.outline);

  /// The nearest surface above the label — the button wearing it.
  BorderRadius radiusOf(WidgetTester tester, String label) => tester
      .widget<Surface>(
        find.ancestor(of: find.text(label), matching: find.byType(Surface)).first,
      )
      .style!
      .radius;

  testWidgets('the run rounds its outside and squares every seam', (
    tester,
  ) async {
    await pump(
      tester,
      ButtonGroup(children: [button('a'), button('b'), button('c')]),
    );

    final own = const Theme().widgets.button.resolve().surface.radius;
    expect(
      radiusOf(tester, 'a'),
      BorderRadius.only(
        topLeft: own.topLeft,
        bottomLeft: own.bottomLeft,
      ),
      reason: 'the first keeps the start corners',
    );
    expect(radiusOf(tester, 'b'), BorderRadius.zero, reason: 'all seams');
    expect(
      radiusOf(tester, 'c'),
      BorderRadius.only(topRight: own.topRight, bottomRight: own.bottomRight),
    );
  });

  testWidgets('right to left, the start corners are the right-hand ones', (
    tester,
  ) async {
    await tester.pumpWidget(
      TomeApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: ButtonGroup(children: [button('a'), button('b')]),
          ),
        ),
      ),
    );

    final own = const Theme().widgets.button.resolve().surface.radius;
    expect(
      radiusOf(tester, 'a'),
      BorderRadius.only(topRight: own.topRight, bottomRight: own.bottomRight),
    );
  });

  testWidgets('neighbours share their edge rather than drawing two', (
    tester,
  ) async {
    await pump(
      tester,
      ButtonGroup(children: [button('a'), button('b'), button('c')]),
    );

    final buttons = [
      for (final label in ['a', 'b', 'c'])
        tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(Button))),
    ];
    expect(buttons[1].left, buttons[0].right - 1, reason: 'one hairline of overlap');
    expect(buttons[2].left, buttons[1].right - 1);
    expect(
      tester.getSize(find.byType(ButtonGroup)).width,
      buttons.fold<double>(0, (sum, rect) => sum + rect.width) - 2,
      reason: 'the run is shorter than its parts by a seam each',
    );
  });

  testWidgets('vertical stacks the run, rounding its top and bottom', (
    tester,
  ) async {
    await pump(
      tester,
      ButtonGroup(
        axis: Axis.vertical,
        children: [button('a'), button('b')],
      ),
    );

    final own = const Theme().widgets.button.resolve().surface.radius;
    expect(
      radiusOf(tester, 'a'),
      BorderRadius.only(topLeft: own.topLeft, topRight: own.topRight),
    );
    final a = tester.getRect(find.ancestor(of: find.text('a'), matching: find.byType(Button)));
    final b = tester.getRect(find.ancestor(of: find.text('b'), matching: find.byType(Button)));
    expect(b.top, a.bottom - 1);
    expect(b.left, a.left, reason: 'a column, not a diagonal');
  });

  testWidgets('a run of one is a button like any other', (tester) async {
    await pump(tester, ButtonGroup(children: [button('a')]));

    expect(
      radiusOf(tester, 'a'),
      const Theme().widgets.button.resolve().surface.radius,
    );
  });

  testWidgets('a button nested inside a slot belongs to no group', (
    tester,
  ) async {
    await pump(
      tester,
      ButtonGroup(
        children: [
          Button(
            onPressed: () {},
            center: Button(onPressed: () {}, center: const Text('inner')),
          ),
          button('b'),
        ],
      ),
    );

    expect(
      radiusOf(tester, 'inner'),
      const Theme().widgets.button.resolve().surface.radius,
    );
  });

  testWidgets('each button keeps its own press', (tester) async {
    final pressed = <String>[];
    await pump(
      tester,
      ButtonGroup(
        children: [
          for (final label in ['a', 'b'])
            Button(onPressed: () => pressed.add(label), center: Text(label)),
        ],
      ),
    );

    await tester.tap(find.text('b'));
    expect(pressed, ['b']);
  });
}
