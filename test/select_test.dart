import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

enum Watch { morning, forenoon, dog }

void main() {
  const options = [
    SelectOption(value: Watch.morning, label: Text('Morning')),
    SelectOption(value: Watch.forenoon, label: Text('Forenoon')),
    SelectOption(value: Watch.dog, label: Text('Dog')),
  ];

  Future<void> pump(
    WidgetTester tester, {
    Watch? value,
    ValueChanged<Watch>? onChanged,
    bool disabled = false,
    List<SelectOption<Watch>> items = options,
  }) => tester.pumpWidget(
    TomeApp(
      home: Center(
        child: Select<Watch>(
          value: value,
          options: items,
          placeholder: const Text('Pick a watch'),
          onChanged: disabled ? null : (onChanged ?? (_) {}),
        ),
      ),
    ),
  );

  /// The list row, not the trigger's copy of the same words.
  Finder row(String label) => find.descendant(
    of: find.byType(SingleChildScrollView),
    matching: find.text(label),
  );

  Future<void> openList(WidgetTester tester) async {
    await tester.tap(find.byType(Button));
    await tester.pumpAndSettle();
  }

  testWidgets('closed, it shows the chosen option — or the placeholder', (
    tester,
  ) async {
    // hitTestable: every label also rides in the trigger invisibly to fix
    // its width, and only the shown one takes the pointer.
    await pump(tester);
    expect(find.text('Pick a watch').hitTestable(), findsOneWidget);

    await pump(tester, value: Watch.dog);
    expect(find.text('Pick a watch').hitTestable(), findsNothing);
    expect(find.text('Dog').hitTestable(), findsOneWidget);
  });

  testWidgets('opens on tap and closes on choosing', (tester) async {
    Watch? reported;
    await pump(tester, onChanged: (value) => reported = value);
    expect(row('Morning'), findsNothing);

    await openList(tester);
    expect(row('Morning'), findsOneWidget);
    expect(row('Dog'), findsOneWidget);

    await tester.tap(row('Forenoon'));
    await tester.pumpAndSettle();
    expect(reported, Watch.forenoon);
    expect(row('Morning'), findsNothing, reason: 'closed behind the choice');
  });

  testWidgets('choosing reports; the caller still owns the value', (
    tester,
  ) async {
    await pump(tester, value: Watch.morning);
    await openList(tester);
    await tester.tap(row('Dog'));
    await tester.pumpAndSettle();

    // Nothing was told to change, so nothing did.
    expect(find.text('Morning').hitTestable(), findsOneWidget);
  });

  testWidgets('the trigger is as wide as its widest option, whatever is '
      'chosen', (tester) async {
    await pump(tester, value: Watch.dog);
    final withShort = tester.getSize(find.byType(Button)).width;

    await pump(tester, value: Watch.forenoon);
    expect(
      tester.getSize(find.byType(Button)).width,
      withShort,
      reason: 'choosing must never resize the control',
    );
  });

  testWidgets('the open list hugs its widest row, not the allowance', (
    tester,
  ) async {
    await pump(tester, value: Watch.morning);
    await openList(tester);

    final list = tester.getSize(find.byType(SingleChildScrollView)).width;
    expect(
      list,
      lessThan(const Theme().sizes.dialog / 2),
      reason: 'a short word list must not take the whole allowance',
    );
    expect(
      list,
      greaterThanOrEqualTo(tester.getSize(find.byType(Button)).width),
      reason: 'and never narrower than its trigger',
    );
  });

  testWidgets('the list is never narrower than its trigger', (tester) async {
    await pump(tester, value: Watch.morning);
    final trigger = tester.getSize(find.byType(Button));
    await openList(tester);

    final panel = tester.getSize(
      find.ancestor(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Surface),
      ),
    );
    expect(panel.width, greaterThanOrEqualTo(trigger.width));
  });

  testWidgets('keyboard: arrows move, Enter chooses, Escape closes', (
    tester,
  ) async {
    Watch? reported;
    await pump(tester, onChanged: (value) => reported = value);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(row('Morning'), findsOneWidget, reason: 'opened from the keyboard');

    // Highlight starts on the first row; step twice to the third.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(reported, Watch.dog);

    // And Escape leaves without choosing.
    reported = null;
    await openList(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(row('Morning'), findsNothing);
    expect(reported, isNull);
  });

  testWidgets('the highlight wraps around the ends', (tester) async {
    Watch? reported;
    await pump(tester, onChanged: (value) => reported = value);
    await openList(tester);

    // Up from the first row lands on the last.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(reported, Watch.dog);
  });

  testWidgets('a disabled option is skipped and cannot be chosen', (
    tester,
  ) async {
    Watch? reported;
    await pump(
      tester,
      onChanged: (value) => reported = value,
      items: const [
        SelectOption(value: Watch.morning, label: Text('Morning')),
        SelectOption(
          value: Watch.forenoon,
          label: Text('Forenoon'),
          enabled: false,
        ),
        SelectOption(value: Watch.dog, label: Text('Dog')),
      ],
    );
    await openList(tester);

    await tester.tap(row('Forenoon'));
    await tester.pumpAndSettle();
    expect(reported, isNull, reason: 'tapping a disabled row does nothing');

    // The keyboard steps over it too.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(reported, Watch.dog);
  });

  testWidgets('a null onChanged disables the control', (tester) async {
    await pump(tester, disabled: true);
    await tester.tap(find.byType(Button), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(row('Morning'), findsNothing);
  });

  testWidgets('the open list follows its trigger when the page scrolls', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TomeApp(
        home: ListView(
          controller: controller,
          children: [
            const SizedBox(height: 200),
            Select<Watch>(
              value: Watch.morning,
              options: options,
              onChanged: (_) {},
            ),
            const SizedBox(height: 1200),
          ],
        ),
      ),
    );
    await openList(tester);

    final before = tester.getRect(find.byType(Button));
    final panelBefore = tester.getRect(
      find.ancestor(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Surface),
      ),
    );

    controller.jumpTo(120);
    await tester.pumpAndSettle();

    final after = tester.getRect(find.byType(Button));
    final panelAfter = tester.getRect(
      find.ancestor(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Surface),
      ),
    );

    expect(after.top, lessThan(before.top), reason: 'the trigger moved up');
    expect(
      panelAfter.top - after.top,
      closeTo(panelBefore.top - before.top, 0.01),
      reason: 'the panel kept its place relative to the trigger',
    );
  });

  testWidgets('the list gives up when its trigger scrolls out of sight', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TomeApp(
        home: ListView(
          controller: controller,
          children: [
            Select<Watch>(
              value: Watch.morning,
              options: options,
              onChanged: (_) {},
            ),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
    await openList(tester);
    expect(row('Dog'), findsOneWidget);

    controller.jumpTo(900);
    await tester.pumpAndSettle();
    expect(row('Dog'), findsNothing);
  });
}
