import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

void main() {
  late ClickWheelController wheel;
  late ValueNotifier<bool> enabled;
  var selected = 0;
  var activated = -1;
  Future<void> pump(
    WidgetTester tester, {
    bool alphabetical = false,
    int count = 100,
  }) async {
    wheel = ClickWheelController();
    enabled = ValueNotifier(true);
    selected = 0;
    activated = -1;
    addTearDown(enabled.dispose);
    await tester.pumpWidget(
      TomeApp(
        home: ClickWheelInput(
          controller: wheel,
          child: ValueListenableBuilder(
            valueListenable: enabled,
            builder: (context, on, _) => WheelAcceleration(
              enabled: on,
              child: Center(
                child: SizedBox(
                  width: 175,
                  height: 180,
                  child: WheelList.builder(
                    itemCount: count,
                    itemExtent: 20,
                    autofocus: true,
                    sectionOf: alphabetical
                        ? (i) => String.fromCharCode(65 + i ~/ 20)
                        : null,
                    onSelectionChanged: (i) => selected = i,
                    onActivate: (i) => activated = i,
                    itemBuilder: (context, i, chosen) => Text('Item $i'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> jog(
    WidgetTester tester, {
    int amount = 1,
    int delay = 50,
    bool page = false,
  }) async {
    await tester.pump(Duration(milliseconds: delay));
    wheel.jog(amount, page: page);
    await tester.pump();
  }

  Future<void> accelerate(WidgetTester tester) async {
    for (var i = 0; i < 7; i++) {
      await jog(tester, delay: 30);
    }
  }

  testWidgets('long unordered lists accelerate, then return to single items', (
    tester,
  ) async {
    await pump(tester);
    for (var i = 0; i < 10; i++) {
      await jog(tester);
    }
    expect(selected, 10);
    await jog(tester);
    expect(selected, greaterThan(11));
    final fast = selected;
    await jog(tester, delay: 200);
    expect(selected, fast + 1);
    enabled.value = false;
    await tester.pump();
    final before = selected;
    for (var i = 0; i < 5; i++) {
      await jog(tester);
    }
    expect(selected, before + 5);
    expect(find.byKey(const ValueKey('WheelList.letters')), findsNothing);
  });

  testWidgets('select commits the letter without activating its item', (
    tester,
  ) async {
    await pump(tester, alphabetical: true);
    await accelerate(tester);
    await jog(tester);
    expect(selected, 6);
    wheel.press(WheelButton.select);
    await tester.pumpAndSettle();
    expect(selected, 20);
    expect(activated, -1);
    wheel.press(WheelButton.select);
    expect(activated, 20);
  });

  testWidgets('overlay has one neighbor per side and a larger primary letter', (
    tester,
  ) async {
    await pump(tester, alphabetical: true, count: 200);
    await accelerate(tester);
    await jog(tester, amount: 3);
    await tester.pump(WheelList.modeTransition);
    final overlay = find.byKey(const ValueKey('WheelList.letters'));
    for (final letter in ['C', 'D', 'E']) {
      expect(
        find.descendant(of: overlay, matching: find.text(letter)),
        findsOneWidget,
      );
    }
    for (final letter in ['B', 'F']) {
      expect(
        find.descendant(of: overlay, matching: find.text(letter)),
        findsNothing,
      );
    }
    expect(
      find.descendant(of: overlay, matching: find.byType(AnimatedSwitcher)),
      findsNothing,
    );
    expect(
      find.descendant(of: overlay, matching: find.byType(Surface)),
      findsOneWidget,
    );
    final label = tester.widget<Text>(find.text('D'));
    final theme = ThemeProvider.of(tester.element(find.text('D')));
    expect(
      label.style?.fontSize,
      (theme.typography.display.fontSize ?? 20) * 2.4,
    );
    expect(
      label.style?.color,
      theme.widgets.surface
          .resolve(SemanticSwatch.primary, SurfaceVariant.soft)
          .foreground,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(WheelList.accelerationIdle);
    await tester.pumpAndSettle();
    expect(selected, 60);
  });
}
