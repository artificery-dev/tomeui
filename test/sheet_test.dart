import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<List<String?>> pumpPage(
    WidgetTester tester, {
    SheetSide side = SheetSide.bottom,
    bool draggable = true,
    bool barrierDismissible = true,
  }) async {
    final answers = <String?>[];
    await tester.pumpWidget(
      TomeApp(
        home: Builder(
          builder: (context) => Center(
            child: Button(
              onPressed: () async {
                answers.add(
                  await showSheet<String>(
                    context,
                    side: side,
                    draggable: draggable,
                    barrierDismissible: barrierDismissible,
                    builder: (context) => Sheet(
                      side: side,
                      title: const Text('Sort by'),
                      child: Button(
                        onPressed: () => Navigator.of(context).pop('name'),
                        center: const Text('Name'),
                      ),
                    ),
                  ),
                );
              },
              center: const Text('open'),
            ),
          ),
        ),
      ),
    );
    return answers;
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a bottom sheet sits on the bottom edge, full width', (
    tester,
  ) async {
    await pumpPage(tester);
    await open(tester);

    final sheet = tester.getRect(find.byType(Sheet));
    final screen = tester.getRect(find.byType(TomeApp));
    expect(sheet.bottom, screen.bottom);
    expect(sheet.width, screen.width);
    expect(sheet.top, greaterThan(screen.top), reason: 'not the whole page');
  });

  testWidgets('a side sheet comes in from its edge, as wide as the style '
      'says', (tester) async {
    await pumpPage(tester, side: SheetSide.trailing);
    await open(tester);

    final sheet = tester.getRect(find.byType(Sheet));
    final screen = tester.getRect(find.byType(TomeApp));
    expect(sheet.right, screen.right);
    expect(sheet.top, screen.top);
    expect(sheet.bottom, screen.bottom);
    expect(sheet.width, const Theme().widgets.sheet.resolve().size);
  });

  testWidgets('only a bottom sheet wears a grabber', (tester) async {
    await pumpPage(tester);
    await open(tester);
    final withGrabber = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Sheet),
            matching: find.byType(DecoratedBox),
          ),
        )
        .length;

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await pumpPage(tester, side: SheetSide.leading);
    await open(tester);
    final without = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Sheet),
            matching: find.byType(DecoratedBox),
          ),
        )
        .length;

    expect(withGrabber, greaterThan(without));
  });

  testWidgets('what is inside pops the answer back', (tester) async {
    final answers = await pumpPage(tester);
    await open(tester);

    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(find.byType(Sheet), findsNothing);
    expect(answers, ['name']);
  });

  testWidgets('the scrim and escape both dismiss it', (tester) async {
    final answers = await pumpPage(tester);

    await open(tester);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(Sheet), findsNothing);

    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Sheet), findsNothing);
    expect(answers, [null, null]);
  });

  testWidgets('thrown downward, a bottom sheet goes', (tester) async {
    final answers = await pumpPage(tester);
    await open(tester);

    await tester.fling(find.byType(Sheet), const Offset(0, 300), 2000);
    await tester.pumpAndSettle();
    expect(find.byType(Sheet), findsNothing);
    expect(answers, [null]);
  });

  testWidgets('nudged, it settles back where it was', (tester) async {
    await pumpPage(tester);
    await open(tester);
    final before = tester.getRect(find.byType(Sheet));

    await tester.drag(find.byType(Sheet), const Offset(0, 12));
    await tester.pumpAndSettle();

    expect(find.byType(Sheet), findsOneWidget);
    expect(tester.getRect(find.byType(Sheet)), before);
  });

  testWidgets('a sheet told not to drag ignores the throw', (tester) async {
    await pumpPage(tester, draggable: false);
    await open(tester);

    await tester.fling(find.byType(Sheet), const Offset(0, 300), 2000);
    await tester.pumpAndSettle();
    expect(find.byType(Sheet), findsOneWidget);
  });

  testWidgets('it leaves the way it came: its own height, gathering speed', (
    tester,
  ) async {
    await pumpPage(tester);
    await open(tester);

    final rest = tester.getRect(find.byType(Sheet)).top;
    final height = tester.getSize(find.byType(Sheet)).height;

    // A slide measured against a full-screen box travels a whole screen,
    // which puts the panel out of sight in the first few frames and spends
    // the rest of the animation off stage — no exit at all, to the eye.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    final travelled = <double>[];
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      if (find.byType(Sheet).evaluate().isEmpty) break;
      travelled.add(tester.getRect(find.byType(Sheet)).top - rest);
    }

    expect(travelled.first, lessThan(height * 0.1), reason: 'it holds first');
    expect(travelled.last, lessThan(height), reason: 'never past its own end');

    // Gathering speed: every step is longer than the one before it.
    final steps = [
      for (var i = 1; i < travelled.length; i++)
        travelled[i] - travelled[i - 1],
    ];
    for (var i = 1; i < steps.length; i++) {
      expect(
        steps[i],
        greaterThanOrEqualTo(steps[i - 1] - 0.5),
        reason: 'an exit accelerates away rather than trailing off',
      );
    }

    await tester.pumpAndSettle();
    expect(find.byType(Sheet), findsNothing);
  });
}
