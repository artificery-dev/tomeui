import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  const theme = Theme();
  final style = theme.widgets.slider.resolve();

  /// A slider of a known length, so a position on screen means a value.
  Future<void> pump(WidgetTester tester, Widget slider) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(child: SizedBox(width: 300, child: slider)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Where the thumb's center sits, in the slider's own coordinates.
  double thumbCenter(WidgetTester tester) {
    final slider = tester.getTopLeft(find.byType(Slider));
    // The thumb is the only thing in a slider that scales.
    final thumb = tester.getCenter(
      find.descendant(
        of: find.byType(Slider),
        matching: find.byType(AnimatedScale),
      ),
    );
    return thumb.dx - slider.dx;
  }

  testWidgets('the thumb sits where the value says', (tester) async {
    // Half a thumb is parked at each end, so the center travels the width
    // less one thumb — and at 0.5 it lands in the middle either way.
    for (final (value, expected) in [
      (0.0, style.thumbSize / 2),
      (0.5, 150.0),
      (1.0, 300 - style.thumbSize / 2),
    ]) {
      await pump(tester, Slider(value: value, onChanged: (_) {}));
      expect(thumbCenter(tester), moreOrLessEquals(expected, epsilon: 0.5));
    }
  });

  testWidgets('a value past the end draws at the end', (tester) async {
    await pump(tester, Slider(value: 9, onChanged: (_) {}));
    expect(
      thumbCenter(tester),
      moreOrLessEquals(300 - style.thumbSize / 2, epsilon: 0.5),
    );
  });

  testWidgets('a tap on the band takes the thumb there', (tester) async {
    double? reported;
    await pump(
      tester,
      Slider(value: 0, onChanged: (value) => reported = value),
    );

    await tester.tapAt(tester.getCenter(find.byType(Slider)));
    await tester.pump();
    expect(reported, moreOrLessEquals(0.5, epsilon: 0.01));
  });

  testWidgets('dragging reports every step of the way', (tester) async {
    final reported = <double>[];
    await pump(tester, Slider(value: 0, onChanged: reported.add));

    final start = tester.getTopLeft(find.byType(Slider));
    final gesture = await tester.startGesture(
      start + Offset(style.thumbSize / 2, style.height / 2),
    );
    for (var dx = 30.0; dx <= 150; dx += 30) {
      await gesture.moveTo(start + Offset(dx, style.height / 2));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reported.length, greaterThan(3));
    expect(reported, reported.toList()..sort());
  });

  testWidgets('onChangeStart and onChangeEnd bracket the drag', (tester) async {
    final events = <String>[];
    await pump(
      tester,
      Slider(
        value: 0.5,
        onChanged: (_) {},
        onChangeStart: (value) => events.add('start $value'),
        onChangeEnd: (value) => events.add('end $value'),
      ),
    );

    final center = tester.getCenter(find.byType(Slider));
    final gesture = await tester.startGesture(center);
    await gesture.moveTo(center + const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(events, ['start 0.5', 'end 0.5']);
  });

  testWidgets('divisions snap the value to a stop', (tester) async {
    double? reported;
    await pump(
      tester,
      Slider(value: 0, divisions: 4, onChanged: (value) => reported = value),
    );

    // A little past the second stop still means the second stop.
    final left = tester.getTopLeft(find.byType(Slider));
    await tester.tapAt(left + const Offset(160, 18));
    await tester.pump();
    expect(reported, 0.5);
  });

  testWidgets('the arrows step, and Home and End take the ends', (
    tester,
  ) async {
    double value = 0.5;
    // Genuinely controlled: each press has to move the widget it reads
    // from, or the second press would compute from the first's old value.
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Slider(
          value: value,
          divisions: 4,
          onChanged: (next) => setState(() => value = next),
        ),
      ),
    );
    // Tab, not tap: tapping a slider is a value change, which would make
    // the arrows look like they worked when they hadn't.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, moreOrLessEquals(0.75));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value, moreOrLessEquals(0.5));

    // Past the end stops at the end rather than wrapping.
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
    }
    expect(value, 1.0);

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(value, 0.0);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(value, 1.0);
  });

  testWidgets('a continuous slider steps by a hundredth of its range', (
    tester,
  ) async {
    double value = 50;
    await pump(
      tester,
      Slider(value: value, min: 0, max: 200, onChanged: (next) => value = next),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(value, moreOrLessEquals(52));
  });

  testWidgets('a null onChanged disables it', (tester) async {
    double? reported;
    await pump(tester, const Slider(value: 0.5, onChanged: null));

    await tester.tapAt(
      tester.getTopLeft(find.byType(Slider)) + const Offset(10, 18),
    );
    await tester.pump();
    expect(reported, isNull);
  });

  testWidgets('an unbounded slot gets the style width', (tester) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Slider(value: 0.5, onChanged: (_) {})],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Slider)).width, style.minWidth);
  });

  testWidgets('it says what it is to assistive tech', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      Slider(
        value: 3,
        min: 0,
        max: 10,
        divisions: 10,
        onChanged: (_) {},
        semanticFormatter: (value) => '${value.round()} of 10',
      ),
    );

    expect(
      tester.getSemantics(find.byType(Slider)),
      matchesSemantics(
        isSlider: true,
        isEnabled: true,
        hasEnabledState: true,
        value: '3 of 10',
        increasedValue: '4 of 10',
        decreasedValue: '2 of 10',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        // What the band and the traversal contribute: a slider is
        // tappable, focusable, and draggable either way.
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasScrollLeftAction: true,
        hasScrollRightAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('vertical: the line stands up and more is up', (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: SizedBox(
            height: 300,
            child: Slider(axis: Axis.vertical, value: 0.5, onChanged: seen.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final box = tester.getSize(find.byType(Slider));
    expect(box.height, 300);
    expect(box.width, style.height, reason: 'the cross size is the height');

    // A tap near the top asks for nearly everything; near the bottom,
    // nearly nothing.
    final rect = tester.getRect(find.byType(Slider));
    await tester.tapAt(Offset(rect.center.dx, rect.top + 10));
    expect(seen.last, greaterThan(0.9));
    await tester.tapAt(Offset(rect.center.dx, rect.bottom - 10));
    expect(seen.last, lessThan(0.1));
  });

  testWidgets('vertical: a drag rides the vertical axis', (tester) async {
    final seen = <double>[];
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: SizedBox(
            height: 300,
            child: Slider(axis: Axis.vertical, value: 0.5, onChanged: seen.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byType(Slider));
    await tester.dragFrom(rect.center, const Offset(0, -80));
    expect(seen.last, greaterThan(0.5), reason: 'dragging up is more');
  });
}
