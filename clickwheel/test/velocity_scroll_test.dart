import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

void main() {
  const config = WheelScrollConfig(
    ticksPerRevolution: 20,
    enterRevolutionsPerSecond: 2,
  );
  late ClickWheelController wheel;
  var selected = 0;
  final overlay = find.byKey(const ValueKey('WheelList.letters'));
  Future<void> setup(
    WidgetTester tester, {
    int count = 200,
    double sensitivity = 1,
  }) async {
    wheel = ClickWheelController();
    selected = 0;
    await tester.pumpWidget(
      TomeApp(
        home: ClickWheelInput(
          controller: wheel,
          feel: WheelFeel(rowsPerDetent: sensitivity),
          child: WheelAcceleration(
            enabled: true,
            scrollConfig: config,
            child: Center(
              child: SizedBox(
                width: 200,
                height: 180,
                child: WheelList.builder(
                  itemCount: count,
                  itemExtent: 20,
                  autofocus: true,
                  sectionOf: (i) => String.fromCharCode(65 + i ~/ 10),
                  onSelectionChanged: (i) => selected = i,
                  itemBuilder: (context, i, chosen) => Text('Row $i'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> turn(
    WidgetTester tester, {
    int direction = 1,
    int delay = 20,
  }) async {
    await tester.pump(Duration(milliseconds: delay));
    wheel.jog(direction);
    await tester.pump();
  }

  Future<void> flick(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await turn(tester);
    }
  }

  Future<void> hardwareTick(WidgetTester tester, Duration stamp) async {
    HardwareKeyboard.instance.handleKeyEvent(
      KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: stamp,
      ),
    );
    HardwareKeyboard.instance.handleKeyEvent(
      KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: stamp + const Duration(microseconds: 1),
      ),
    );
    await tester.pump();
  }

  for (final clicks in [1, 2, 3, 4, 5]) {
    testWidgets('hardware entry needs ten raw ticks at sensitivity $clicks', (
      tester,
    ) async {
      await setup(tester, sensitivity: 1 / clicks);
      for (var i = 0; i < 9; i++) {
        // Deliberately delay delivery beyond the hardware cadence. The real
        // timestamp must determine the window, regardless of rendering load.
        await tester.pump(const Duration(milliseconds: 60));
        await hardwareTick(tester, Duration(milliseconds: i * 20));
        expect(overlay, findsNothing);
      }
      await hardwareTick(tester, const Duration(milliseconds: 180));
      expect(overlay, findsOneWidget);
      await tester.pumpAndSettle();
    });
  }
  testWidgets(
    'batched delivery of slow hardware ticks cannot trigger letters',
    (tester) async {
      await setup(tester);
      for (var i = 0; i < 40; i++) {
        await hardwareTick(tester, Duration(milliseconds: i * 100));
        expect(overlay, findsNothing);
      }
      await tester.pumpAndSettle();
    },
  );

  testWidgets('slow continuous nudges never enter letters', (tester) async {
    await setup(tester);
    for (var i = 0; i < 40; i++) {
      await turn(tester, delay: 200);
    }
    expect(selected, 40);
    expect(overlay, findsNothing);
    await tester.pumpAndSettle();
  });
  testWidgets('raw velocity is independent of clicks per row', (tester) async {
    await setup(tester, sensitivity: .2);
    await flick(tester);
    expect(overlay, findsOneWidget);
    await tester.pumpAndSettle();
  });
  testWidgets('three screens are required', (tester) async {
    await setup(tester, count: 26);
    await flick(tester);
    expect(overlay, findsNothing);
    await tester.pumpAndSettle();
  });
  testWidgets('idle holds wheel focus until overlay disappears, then lands', (
    tester,
  ) async {
    await setup(tester);
    await flick(tester);
    await turn(tester);
    expect(selected, 9);
    await tester.pump(const Duration(milliseconds: 1499));
    expect(selected, 9);
    expect(overlay, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(overlay, findsOneWidget); // outgoing fade still owns the wheel
    await turn(tester);
    expect(selected, 9);
    await tester.pump(WheelList.modeTransition);
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
    expect(selected, 10);
    await turn(tester);
    expect(selected, 11);
    await tester.pumpAndSettle();
  });
  testWidgets('reversals browse letters both ways without closing', (
    tester,
  ) async {
    await setup(tester);
    await flick(tester);
    await turn(tester, direction: 3); // D
    await turn(tester, direction: -1); // C
    await turn(tester, direction: -1); // B
    await turn(tester); // C
    expect(selected, 9, reason: 'the underlying list never regains input');
    expect(overlay, findsOneWidget);
    await tester.pumpAndSettle();
    expect(selected, 20);
  });
  testWidgets('slow reverse detents also reset the full idle timeout', (
    tester,
  ) async {
    await setup(tester);
    await flick(tester);
    await turn(tester, direction: 3); // D
    await turn(tester, direction: -1, delay: 1000); // C
    await turn(tester, direction: -1, delay: 1000); // B
    await tester.pump(const Duration(milliseconds: 1499));
    expect(overlay, findsOneWidget);
    expect(selected, 9);
    await tester.pumpAndSettle();
    expect(selected, 10);
  });
  testWidgets('reversals browse letters at five clicks per row', (
    tester,
  ) async {
    await setup(tester, sensitivity: .2);
    await flick(tester);
    await turn(tester, direction: 15); // D
    await turn(tester, direction: -10); // B
    expect(overlay, findsOneWidget);
    expect(selected, 1);
    await tester.pumpAndSettle();
    expect(selected, 10);
  });
  testWidgets('a short hitch does not leave letter mode', (tester) async {
    await setup(tester);
    await flick(tester);
    await turn(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(selected, 9);
    for (var i = 0; i < 4; i++) {
      await turn(tester);
    }
    expect(selected, 9);
    await tester.pumpAndSettle();
    expect(selected, 50);
  });
}
