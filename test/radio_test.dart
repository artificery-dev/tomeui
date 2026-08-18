import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

enum Ration { hardtack, salt, rum }

void main() {
  /// A group of three, reporting into [onChanged].
  Future<void> pumpGroup(
    WidgetTester tester, {
    Ration? value = Ration.hardtack,
    ValueChanged<Ration>? onChanged,
    SurfaceVariant variant = SurfaceVariant.solid,
    bool enabled = true,
    // Separate from onChanged: `?? (_) {}` can't tell "not given" from
    // "deliberately null", which is the whole point of this state.
    bool groupDisabled = false,
  }) => tester.pumpWidget(
    TomeApp(
      home: Center(
        child: RadioGroup<Ration>(
          value: value,
          onChanged: groupDisabled ? null : (onChanged ?? (_) {}),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final ration in Ration.values)
                RadioButton(
                  key: ValueKey(ration),
                  value: ration,
                  variant: variant,
                  enabled: enabled,
                ),
            ],
          ),
        ),
      ),
    ),
  );

  BoxDecoration? decorationOf(WidgetTester tester, Ration ration) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byKey(ValueKey(ration)),
                  matching: find.byType(Container),
                ),
              )
              .decoration
          as BoxDecoration?;

  testWidgets('the group hands its answer down; buttons only report', (
    tester,
  ) async {
    Ration? reported;
    await pumpGroup(tester, onChanged: (value) => reported = value);
    await tester.pumpAndSettle();

    final style = const Theme().widgets.radio.resolve();
    // The group's value is selected, the others are not.
    expect(decorationOf(tester, Ration.hardtack)?.color, style.selected.fill);
    expect(decorationOf(tester, Ration.salt)?.color?.a, 0);

    await tester.tap(find.byKey(const ValueKey(Ration.rum)));
    expect(reported, Ration.rum);

    // Reporting alone changes nothing — the group owns the choice.
    await tester.pumpAndSettle();
    expect(decorationOf(tester, Ration.hardtack)?.color, style.selected.fill);
  });

  testWidgets('a new group value moves the dot', (tester) async {
    await pumpGroup(tester, value: Ration.salt);
    await tester.pumpAndSettle();

    final style = const Theme().widgets.radio.resolve();
    expect(decorationOf(tester, Ration.salt)?.color, style.selected.fill);
    expect(decorationOf(tester, Ration.hardtack)?.color?.a, 0);
  });

  testWidgets('nothing selected is a legitimate state', (tester) async {
    await pumpGroup(tester, value: null);
    await tester.pumpAndSettle();

    for (final ration in Ration.values) {
      expect(decorationOf(tester, ration)?.color?.a, 0, reason: '$ration');
    }
  });

  testWidgets('choosing the chosen stays live, and re-reports', (tester) async {
    Ration? reported;
    await pumpGroup(
      tester,
      value: Ration.hardtack,
      onChanged: (value) => reported = value,
    );

    await tester.tap(find.byKey(const ValueKey(Ration.hardtack)));
    expect(reported, Ration.hardtack, reason: 'a radio never un-chooses');
  });

  testWidgets('the group disables every button at once', (tester) async {
    await pumpGroup(tester, groupDisabled: true);

    for (final ration in Ration.values) {
      final opacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byKey(ValueKey(ration)),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, const Opacities().disabled, reason: '$ration');
    }
  });

  testWidgets('a single button can bow out while the group stays live', (
    tester,
  ) async {
    Ration? reported;
    await tester.pumpWidget(
      TomeApp(
        home: RadioGroup<Ration>(
          value: Ration.hardtack,
          onChanged: (value) => reported = value,
          child: Column(
            children: [
              const RadioButton(
                key: ValueKey('off'),
                value: Ration.salt,
                enabled: false,
              ),
              const RadioButton(key: ValueKey('on'), value: Ration.rum),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('off')), warnIfMissed: false);
    expect(reported, isNull);

    await tester.tap(find.byKey(const ValueKey('on')));
    expect(reported, Ration.rum);
  });

  testWidgets('the variant dresses the circle, like any surface', (
    tester,
  ) async {
    await pumpGroup(tester, variant: SurfaceVariant.soft);
    await tester.pumpAndSettle();

    final expected = const Theme().widgets.surface.resolve(
      SemanticSwatch.primary,
      SurfaceVariant.soft,
    );
    expect(decorationOf(tester, Ration.hardtack)?.color, expected.fill);
  });

  testWidgets('the circle is round, whatever the theme radii say', (
    tester,
  ) async {
    await tester.pumpWidget(
      TomeApp(
        theme: const Theme(radii: Radii(small: BorderRadius.zero)),
        home: RadioGroup<Ration>(
          value: Ration.rum,
          onChanged: (_) {},
          child: const RadioButton(
            key: ValueKey(Ration.rum),
            value: Ration.rum,
          ),
        ),
      ),
    );

    final radius = decorationOf(tester, Ration.rum)?.borderRadius;
    expect(radius, const BorderRadius.all(Radius.circular(999)));
  });

  testWidgets('keyboard: tab focuses, Enter chooses', (tester) async {
    Ration? reported;
    await pumpGroup(
      tester,
      value: null,
      onChanged: (value) => reported = value,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(reported, Ration.hardtack);
  });

  testWidgets('a button without a group says so', (tester) async {
    await tester.pumpWidget(
      const TomeApp(home: RadioButton<Ration>(value: Ration.rum)),
    );

    final error = tester.takeException();
    expect(error, isFlutterError);
    expect('$error', contains('No RadioGroup<Ration>'));
  });

  testWidgets('the label is part of the button: clicking it chooses', (
    tester,
  ) async {
    Ration? reported;
    await tester.pumpWidget(
      TomeApp(
        home: RadioGroup<Ration>(
          value: Ration.hardtack,
          onChanged: (value) => reported = value,
          child: const Column(
            children: [
              RadioButton(value: Ration.rum, label: Text('A tot of rum')),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('A tot of rum'));
    expect(reported, Ration.rum);
  });

  testWidgets('custom paints the style exactly as given', (tester) async {
    const style = RadioStyle(
      selected: SurfaceStyle(
        foreground: Color(0xFFFFFFFF),
        fill: Color(0xFF112233),
      ),
      unselected: SurfaceStyle(
        foreground: Color(0xFF445566),
        border: Color(0xFF445566),
      ),
      ring: Color(0xFF112233),
      size: 30,
    );
    await tester.pumpWidget(
      TomeApp(
        home: RadioGroup<Ration>(
          value: Ration.rum,
          onChanged: (_) {},
          child: const RadioButton.custom(
            key: ValueKey(Ration.rum),
            value: Ration.rum,
            style: style,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(decorationOf(tester, Ration.rum)?.color, const Color(0xFF112233));
    expect(tester.getSize(find.byType(Surface)), const Size(30, 30));
  });
}
