import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Widget? child}) => tester.pumpWidget(
    TomeApp(
      home: Center(
        child: Tooltip(
          message: const Text('Weigh anchor'),
          child: child ?? const SizedBox(width: 80, height: 32),
        ),
      ),
    ),
  );

  Future<TestGesture> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(Tooltip)));
    await tester.pump();
    return mouse;
  }

  testWidgets('waits before speaking, then shows', (tester) async {
    await pump(tester);
    final wait = const Theme().widgets.tooltip.resolve().wait;

    await hover(tester);
    expect(find.text('Weigh anchor'), findsNothing, reason: 'still waiting');

    await tester.pump(wait);
    await tester.pumpAndSettle();
    expect(find.text('Weigh anchor'), findsOneWidget);
  });

  testWidgets('a pointer passing through gets nothing', (tester) async {
    await pump(tester);
    final wait = const Theme().widgets.tooltip.resolve().wait;

    final mouse = await hover(tester);
    await tester.pump(wait ~/ 2);
    await mouse.moveTo(Offset.zero);
    await tester.pump(wait);
    await tester.pumpAndSettle();
    expect(find.text('Weigh anchor'), findsNothing);
  });

  testWidgets('leaving hides it again', (tester) async {
    await pump(tester);
    final wait = const Theme().widgets.tooltip.resolve().wait;

    final mouse = await hover(tester);
    await tester.pump(wait);
    await tester.pumpAndSettle();
    expect(find.text('Weigh anchor'), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('Weigh anchor'), findsNothing);
  });

  testWidgets('focus shows it at once — arriving by Tab is deliberate', (
    tester,
  ) async {
    await pump(
      tester,
      child: Button(onPressed: () {}, center: const Text('Sail')),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Weigh anchor'), findsOneWidget, reason: 'no wait');
  });

  testWidgets('a long press shows it while held, for touch', (tester) async {
    await pump(tester);

    final touch = await tester.startGesture(
      tester.getCenter(find.byType(Tooltip)),
    );
    await tester.pump(kLongPressTimeout);
    await tester.pumpAndSettle();
    expect(find.text('Weigh anchor'), findsOneWidget);

    await touch.up();
    await tester.pumpAndSettle();
    expect(find.text('Weigh anchor'), findsNothing, reason: 'let go');
  });

  testWidgets('it annotates without interrupting: the child stays clickable', (
    tester,
  ) async {
    var pressed = 0;
    await pump(
      tester,
      child: Button(onPressed: () => pressed++, center: const Text('Sail')),
    );
    final wait = const Theme().widgets.tooltip.resolve().wait;

    await hover(tester);
    await tester.pump(wait);
    await tester.pumpAndSettle();
    expect(find.text('Weigh anchor'), findsOneWidget);

    await tester.tap(find.text('Sail'));
    expect(pressed, 1);
  });

  testWidgets('it inverts the page: text becomes fill, background ink', (
    tester,
  ) async {
    await pump(tester);
    final wait = const Theme().widgets.tooltip.resolve().wait;
    await hover(tester);
    await tester.pump(wait);
    await tester.pumpAndSettle();

    final decoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(Surface),
                    matching: find.byType(Container),
                  ),
                )
                .decoration
            as BoxDecoration?;
    expect(decoration?.color, const Palette().text);

    final style = DefaultTextStyle.of(
      tester.element(find.text('Weigh anchor')),
    );
    expect(style.style.color, const Palette().background);
  });

  testWidgets('the message wears body type, never the debug fallback', (
    tester,
  ) async {
    await pump(tester);
    final resolved = const Theme().widgets.tooltip.resolve();
    await hover(tester);
    await tester.pump(resolved.wait);
    await tester.pumpAndSettle();

    final style = DefaultTextStyle.of(
      tester.element(find.text('Weigh anchor')),
    ).style;
    expect(style.fontSize, resolved.textStyle.fontSize);
    expect(style.fontFamily, isNot('monospace'));
    expect(style.decoration ?? TextDecoration.none, TextDecoration.none);
  });

  testWidgets('it sits above its child by default', (tester) async {
    await pump(tester);
    final resolved = const Theme().widgets.tooltip.resolve();
    await hover(tester);
    await tester.pump(resolved.wait);
    await tester.pumpAndSettle();

    final child = tester.getRect(find.byType(Tooltip));
    final panel = tester.getRect(find.byType(Surface));
    expect(panel.bottom, child.top - resolved.popover.gap);
  });
}
