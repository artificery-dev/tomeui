import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

/// A grid is read like a page: a detent moves one cell to the right, the
/// end of a row leads to the start of the next, a page detent moves a
/// whole row, and the center button activates the cell under the cursor.
void main() {
  Future<(ClickWheelController, List<int>)> pumpGrid(
    WidgetTester tester, {
    int cells = 7,
    int columns = 3,
  }) async {
    final wheel = ClickWheelController();
    final activated = <int>[];
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            ClickWheelInput(controller: wheel, child: child!),
        home: SizedBox(
          width: 300,
          height: 300,
          child: WheelGrid(
            columns: columns,
            cellExtent: 100,
            autofocus: true,
            onActivate: activated.add,
            children: [for (var i = 0; i < cells; i++) Text('Cell $i')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (wheel, activated);
  }

  /// Which cell wears the plate.
  int selectedCell(WidgetTester tester) {
    final plates = find.byWidgetPredicate(
      (widget) => widget is DecoratedBox && widget.decoration is BoxDecoration,
    );
    final texts = find.descendant(of: plates, matching: find.byType(Text));
    final text = tester.widget<Text>(texts.first).data!;
    return int.parse(text.split(' ').last);
  }

  testWidgets('cells are laid out across then down', (tester) async {
    await pumpGrid(tester);
    // Unselected cells, so the plate's inset under the cursor does not
    // shift what is compared.
    final c1 = tester.getTopLeft(find.text('Cell 1'));
    final c2 = tester.getTopLeft(find.text('Cell 2'));
    final c4 = tester.getTopLeft(find.text('Cell 4'));
    expect(c2.dx, greaterThan(c1.dx));
    expect(c2.dy, c1.dy);
    expect(c4.dx, c1.dx);
    expect(c4.dy, greaterThan(c1.dy));
  });

  testWidgets('a detent moves one cell along the row and on to the next', (
    tester,
  ) async {
    final (wheel, _) = await pumpGrid(tester);
    expect(selectedCell(tester), 0);
    wheel.jog(1);
    await tester.pumpAndSettle();
    expect(selectedCell(tester), 1);
    wheel.jog(2);
    await tester.pumpAndSettle();
    expect(selectedCell(tester), 3, reason: 'past the row end, down a row');
    wheel.jog(-1);
    await tester.pumpAndSettle();
    expect(selectedCell(tester), 2);
  });

  testWidgets('a page detent moves a row, and the edges hold', (tester) async {
    final (wheel, _) = await pumpGrid(tester);
    wheel.jog(1, page: true);
    await tester.pumpAndSettle();
    expect(selectedCell(tester), 3);
    wheel.jog(5, page: true);
    await tester.pumpAndSettle();
    expect(selectedCell(tester), 6, reason: 'clamped to the last cell');
    wheel.jog(-20);
    await tester.pumpAndSettle();
    expect(selectedCell(tester), 0);
  });

  testWidgets('the center button activates the selected cell', (tester) async {
    final (wheel, activated) = await pumpGrid(tester);
    wheel.jog(4);
    await tester.pumpAndSettle();
    wheel.press(WheelButton.select);
    await tester.pumpAndSettle();
    expect(activated, [4]);
  });
}
