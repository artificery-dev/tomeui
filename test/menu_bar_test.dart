import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<String> opened = const [],
    bool disableView = false,
  }) => tester.pumpWidget(
    TomeApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: MenuBar(
          menus: [
            BarMenu(
              label: const Text('File'),
              entries: [
                MenuItem(label: const Text('New'), onPressed: () {}),
                MenuItem(label: const Text('Open'), onPressed: () {}),
              ],
            ),
            BarMenu(
              label: const Text('Edit'),
              entries: [
                MenuItem(label: const Text('Undo'), onPressed: () {}),
              ],
            ),
            BarMenu(
              label: const Text('View'),
              enabled: !disableView,
              entries: [
                MenuItem(label: const Text('Zoom'), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  /// A mouse: it hovers on its way to what it clicks, which is what tells
  /// the bar that the press is its own business rather than a press
  /// somewhere else on the page.
  Future<TestGesture> mouse(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    return gesture;
  }

  Future<void> click(
    WidgetTester tester,
    TestGesture gesture,
    Finder target,
  ) async {
    await gesture.moveTo(tester.getCenter(target));
    await tester.pumpAndSettle();
    await gesture.down(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('the words sit in a row, and nothing drops until asked', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('File'), findsOneWidget);
    expect(find.text('New'), findsNothing);
    expect(
      tester.getRect(find.text('Edit')).left,
      greaterThan(tester.getRect(find.text('File')).right),
    );
  });

  testWidgets('clicking a word drops its menu, and again puts it away', (
    tester,
  ) async {
    await pump(tester);
    final gesture = await mouse(tester);

    await click(tester, gesture, find.text('File'));
    expect(find.text('New'), findsOneWidget);

    await click(tester, gesture, find.text('File'));
    expect(find.text('New'), findsNothing);
  });

  testWidgets('once the bar is active the pointer switches menus', (
    tester,
  ) async {
    await pump(tester);
    final gesture = await mouse(tester);

    await click(tester, gesture, find.text('File'));
    await gesture.moveTo(tester.getCenter(find.text('Edit')));
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsOneWidget, reason: 'Edit dropped');
    expect(find.text('New'), findsNothing, reason: 'File put itself away');
  });

  testWidgets('the pointer alone does nothing while the bar is asleep', (
    tester,
  ) async {
    await pump(tester);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.text('Edit'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('the arrows walk the bar, stepping over a disabled menu', (
    tester,
  ) async {
    await pump(tester, disableView: true);

    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);

    // View is out, so right from Edit comes back round to File.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('a disabled menu does not drop', (tester) async {
    await pump(tester, disableView: true);

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('Zoom'), findsNothing);
  });

  testWidgets('a press on the page puts the bar away', (tester) async {
    await pump(tester);
    final gesture = await mouse(tester);

    await click(tester, gesture, find.text('File'));
    expect(find.text('New'), findsOneWidget);

    await gesture.moveTo(const Offset(600, 500));
    await tester.pumpAndSettle();
    await gesture.down(const Offset(600, 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('New'), findsNothing);
  });

  testWidgets('escape puts the bar back to sleep', (tester) async {
    await pump(tester);

    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('New'), findsNothing);
  });
}
