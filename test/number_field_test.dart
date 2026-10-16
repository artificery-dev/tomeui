import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

/// A lock that pins on demand and lets the test feed movement.
class _FakeLock extends PointerLock {
  _FakeLock();

  int locked = 0;
  int released = 0;
  StreamController<Offset>? deltas;

  @override
  Future<PointerLockSession?> lock() async {
    locked++;
    deltas = StreamController<Offset>();
    return _FakeSession(this);
  }
}

class _FakeSession extends PointerLockSession {
  _FakeSession(this.lock);

  final _FakeLock lock;

  @override
  Stream<Offset> get deltas => lock.deltas!.stream;

  @override
  Future<void> release() async {
    lock.released++;
    await lock.deltas?.close();
    lock.deltas = null;
  }
}

void main() {
  tearDown(() => PointerLock.instance = const NoPointerLock());

  /// A field whose value the test owns; [onChanged] writes straight back
  /// into it, so the widget always shows what it last reported.
  Future<ValueNotifier<double>> pump(
    WidgetTester tester, {
    double value = 10,
    double? min,
    double? max,
    double step = 1,
    int decimals = 0,
    bool enabled = true,
  }) async {
    final state = ValueNotifier<double>(value);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: SizedBox(
            width: 200,
            child: ValueListenableBuilder<double>(
              valueListenable: state,
              builder: (context, v, _) => NumberField(
                value: v,
                min: min,
                max: max,
                step: step,
                decimals: decimals,
                enabled: enabled,
                suffix: const Text('px'),
                onChanged: (next) => state.value = next,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  Finder field() => find.byType(NumberField);

  Future<TestGesture> press(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(field()),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    return gesture;
  }

  testWidgets('a sideways drag slides the value one step per pixel', (
    tester,
  ) async {
    final state = await pump(tester, step: 2);
    final gesture = await press(tester);
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    expect(state.value, 10 + 25 * 2);
    await gesture.moveBy(const Offset(-5, 0));
    await tester.pump();
    expect(state.value, 10 + 20 * 2);
    await gesture.up();
    await tester.pumpAndSettle();
    // A drag is not a click: the box stays closed.
    expect(find.byType(EditableText), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
  });

  testWidgets('shift makes the drag fine, and the clamp holds', (tester) async {
    final state = await pump(tester, max: 15, decimals: 1);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final gesture = await press(tester);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(state.value, 12);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(state.value, 15);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a click opens the box with the number selected, and Enter '
      'commits what was typed', (tester) async {
    final state = await pump(tester);
    await tester.tap(field());
    await tester.pumpAndSettle();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.selection.start, 0);
    expect(editable.controller.selection.end, 2);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    await tester.enterText(find.byType(EditableText), '42.7');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(state.value, 43);
    expect(find.text('43'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
  });

  testWidgets('Escape puts the old value back; nonsense is ignored', (
    tester,
  ) async {
    final state = await pump(tester);
    await tester.tap(field());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '99');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(state.value, 10);
    expect(find.text('10'), findsOneWidget);

    await tester.tap(field());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'ten');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(state.value, 10);
  });

  testWidgets('with a lock installed the scrub pins the pointer and reads '
      'its deltas', (tester) async {
    final lock = _FakeLock();
    PointerLock.instance = lock;
    final state = await pump(tester);

    final gesture = await press(tester);
    await tester.pump();
    expect(lock.locked, 1);

    // The platform now reports movement; raw pointer events are ignored.
    lock.deltas!.add(const Offset(30, 0));
    await tester.pump();
    expect(state.value, 40);
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(state.value, 40);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(lock.released, 1);
    // Pinned movement counts as a drag: no edit box.
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
  });

  testWidgets('disabled, the pointer does nothing', (tester) async {
    final state = await pump(tester, enabled: false);
    final gesture = await press(tester);
    await gesture.moveBy(const Offset(25, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.value, 10);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
  });
}
