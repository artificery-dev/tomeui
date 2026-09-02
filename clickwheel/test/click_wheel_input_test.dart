import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

/// The wheel's keys arrive twice unless somebody stops them: once at
/// [ClickWheelInput]'s global ear, and once more down the focus chain, where
/// [WidgetsApp]'s default shortcuts turn Enter into a second [ActivateIntent]
/// and the arrows into focus moves. On the player that doubled every
/// activation - two pushes of each screen, so two presses of back to leave
/// it - so the test presses the real keys, not the controller.
void main() {
  Future<int Function()> pumpMenu(WidgetTester tester) async {
    var activations = 0;
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ClickWheelInput(child: child!),
        home: WheelList(
          itemExtent: 40,
          autofocus: true,
          onActivate: (_) => activations++,
          children: const [Text('one'), Text('two'), Text('three')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => activations;
  }

  testWidgets('a physical select press activates exactly once', (tester) async {
    final activations = await pumpMenu(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activations(), 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(activations(), 2);
  });

  testWidgets('a physical jog moves the selection by one detent', (
    tester,
  ) async {
    await pumpMenu(tester);

    // The fixed shape dresses the selected row in the primary bar; an
    // unselected row sits on the page.
    bool selected(String label) {
      final bar = ThemeProvider.of(
        tester.element(find.text(label)),
      ).palette.primary.s500;
      return find
          .ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (widget) => widget is ColoredBox && widget.color == bar,
            ),
          )
          .evaluate()
          .isNotEmpty;
    }

    expect(selected('one'), isTrue);
    expect(selected('two'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(selected('one'), isFalse);
    expect(selected('two'), isTrue);
    expect(selected('three'), isFalse, reason: 'one detent, one row');
  });

  testWidgets('the controller speaks the same grammar, once', (tester) async {
    var activations = 0;
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            ClickWheelInput(controller: wheel, child: child!),
        home: WheelList(
          itemExtent: 40,
          autofocus: true,
          onActivate: (_) => activations++,
          children: const [Text('one'), Text('two')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(wheel.attached, isTrue);

    wheel.press(WheelButton.select);
    await tester.pumpAndSettle();
    expect(activations, 1);
  });

  mutedTests();
}

/// Muted, the wheel is claimed but silent - and the power chord is not.
void mutedTests() {
  testWidgets('a muted wheel says nothing but power', (tester) async {
    var activations = 0;
    final presses = <PowerPress>[];
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ClickWheelInput(
          controller: wheel,
          muted: true,
          onPower: presses.add,
          child: child!,
        ),
        home: WheelList(
          itemExtent: 40,
          autofocus: true,
          onActivate: (_) => activations++,
          children: const [Text('one'), Text('two')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Both mouths: the real key and the controller.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    wheel.press(WheelButton.select);
    wheel.jog(1);
    await tester.pumpAndSettle();
    expect(activations, 0);

    wheel.powerDown();
    await tester.pump(const Duration(milliseconds: 50));
    wheel.powerUp();
    await tester.pump(const Duration(milliseconds: 400));
    expect(presses, [isA<PowerTaps>().having((p) => p.taps, 'taps', 1)]);
  });
}
