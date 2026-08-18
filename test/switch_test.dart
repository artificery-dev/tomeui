import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

enum Watch { morning, forenoon, dog }

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  BoxDecoration? decorationOf(WidgetTester tester, [Finder? within]) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: within ?? find.byType(Surface),
                  matching: find.byType(Container),
                ),
              )
              .decoration
          as BoxDecoration?;

  Alignment thumbOf(WidgetTester tester) =>
      tester
              .widget<Align>(
                find.descendant(
                  of: find.byType(Surface),
                  matching: find.byType(Align),
                ),
              )
              .alignment
          as Alignment;

  group('standalone — a checkbox in another shape', () {
    testWidgets('reports the flipped value', (tester) async {
      bool? reported;
      await pump(
        tester,
        Switch(value: false, onChanged: (value) => reported = value),
      );

      await tester.tap(find.byType(Switch<bool>));
      expect(reported, isTrue);
    });

    testWidgets('the thumb rides from one end to the other', (tester) async {
      await pump(tester, Switch(value: false, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect(thumbOf(tester), Alignment.centerLeft);

      await pump(tester, Switch(value: true, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect(thumbOf(tester), Alignment.centerRight);
    });

    testWidgets('the track fills in both positions, never hollow', (
      tester,
    ) async {
      for (final value in [false, true]) {
        await pump(tester, Switch(value: value, onChanged: (_) {}));
        await tester.pumpAndSettle();
        expect(
          decorationOf(tester)?.color?.a,
          greaterThan(0),
          reason: 'on: $value',
        );
      }
    });

    testWidgets('on wears the swatch, off wears neutral', (tester) async {
      final style = const Theme().widgets.switch_.resolve();

      await pump(tester, Switch(value: true, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect(decorationOf(tester)?.color, style.on.fill);

      await pump(tester, Switch(value: false, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect(decorationOf(tester)?.color, style.off.fill);
    });

    testWidgets('null onChanged disables', (tester) async {
      await pump(tester, const Switch(value: false, onChanged: null));
      final opacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(Switch<bool>),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, const Opacities().disabled);
    });
  });

  group('grouped — a radio button in another shape', () {
    Future<void> pumpGroup(
      WidgetTester tester, {
      Watch? value = Watch.morning,
      ValueChanged<Watch>? onChanged,
      bool disabled = false,
    }) => tester.pumpWidget(
      TomeApp(
        home: SwitchGroup<Watch>(
          value: value,
          onChanged: disabled ? null : (onChanged ?? (_) {}),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final watch in Watch.values)
                Switch(key: ValueKey(watch), value: watch),
            ],
          ),
        ),
      ),
    );

    testWidgets('only the group\'s answer is on', (tester) async {
      await pumpGroup(tester, value: Watch.forenoon);
      await tester.pumpAndSettle();

      expect(
        groupedThumbOf(tester, Watch.forenoon),
        Alignment.centerRight,
        reason: 'the chosen watch',
      );
      for (final watch in [Watch.morning, Watch.dog]) {
        expect(
          groupedThumbOf(tester, watch),
          Alignment.centerLeft,
          reason: '$watch',
        );
      }
    });

    testWidgets('flipping one reports it to the group', (tester) async {
      Watch? reported;
      await pumpGroup(tester, onChanged: (value) => reported = value);

      await tester.tap(find.byKey(const ValueKey(Watch.dog)));
      expect(reported, Watch.dog);
    });

    testWidgets('flipping the one that is on keeps it on', (tester) async {
      Watch? reported;
      await pumpGroup(
        tester,
        value: Watch.morning,
        onChanged: (value) => reported = value,
      );

      await tester.tap(find.byKey(const ValueKey(Watch.morning)));
      expect(reported, Watch.morning, reason: 'a group always has an answer');
    });

    testWidgets('the group disables every switch at once', (tester) async {
      await pumpGroup(tester, disabled: true);
      for (final watch in Watch.values) {
        final opacity = tester.widget<AnimatedOpacity>(
          find.descendant(
            of: find.byKey(ValueKey(watch)),
            matching: find.byType(AnimatedOpacity),
          ),
        );
        expect(opacity.opacity, const Opacities().disabled, reason: '$watch');
      }
    });

    testWidgets('a non-bool switch with no group says so', (tester) async {
      await tester.pumpWidget(
        const TomeApp(home: Switch<Watch>(value: Watch.dog)),
      );
      final error = tester.takeException();
      expect(error, isFlutterError);
      expect('$error', contains('standalone Switch<Watch>'));
      expect('$error', contains('SwitchGroup<Watch>'));
    });
  });

  testWidgets('keyboard: tab focuses, Enter flips', (tester) async {
    bool? reported;
    await pump(
      tester,
      Switch(value: false, onChanged: (value) => reported = value),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(reported, isTrue);
  });

  testWidgets('the label is part of the switch: clicking it flips', (
    tester,
  ) async {
    bool? reported;
    await pump(
      tester,
      Switch(
        value: false,
        onChanged: (value) => reported = value,
        label: const Text('Light the lantern'),
      ),
    );

    await tester.tap(find.text('Light the lantern'));
    expect(reported, isTrue);
  });

  testWidgets('custom paints the style exactly as given', (tester) async {
    const style = SwitchStyle(
      on: SurfaceStyle(foreground: Color(0xFFFFFFFF), fill: Color(0xFF112233)),
      off: SurfaceStyle(foreground: Color(0xFF445566), fill: Color(0xFF223344)),
      ring: Color(0xFF112233),
      width: 60,
      height: 30,
    );
    await pump(
      tester,
      Switch.custom(value: true, onChanged: (_) {}, style: style),
    );
    await tester.pumpAndSettle();

    expect(decorationOf(tester)?.color, const Color(0xFF112233));
    expect(tester.getSize(find.byType(Surface)), const Size(60, 30));
  });
}

/// The thumb alignment of the keyed switch in a group.
Alignment groupedThumbOf(WidgetTester tester, Watch watch) =>
    tester
            .widget<Align>(
              find.descendant(
                of: find.byKey(ValueKey(watch)),
                matching: find.descendant(
                  of: find.byType(Surface),
                  matching: find.byType(Align),
                ),
              ),
            )
            .alignment
        as Alignment;
