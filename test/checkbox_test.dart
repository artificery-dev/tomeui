import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  BoxDecoration? decorationOf(WidgetTester tester) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byType(Surface),
                  matching: find.byType(Container),
                ),
              )
              .decoration
          as BoxDecoration?;

  testWidgets('reports the flipped value; paints nothing until told', (
    tester,
  ) async {
    bool? reported;
    await pump(
      tester,
      Checkbox(value: false, onChanged: (value) => reported = value),
    );

    await tester.tap(find.byType(Checkbox));
    expect(reported, isTrue);

    reported = null;
    await pump(
      tester,
      Checkbox(value: true, onChanged: (value) => reported = value),
    );
    await tester.tap(find.byType(Checkbox));
    expect(reported, isFalse);
  });

  testWidgets('checked wears the swatch solid, with the check grown in', (
    tester,
  ) async {
    await pump(tester, Checkbox(value: true, onChanged: (_) {}));
    await tester.pumpAndSettle();

    final style = const Theme().widgets.checkbox.resolve();
    expect(decorationOf(tester)?.color, style.checked.fill);
    expect(find.byIcon(const Theme().icons.confirm), findsOneWidget);
    expect(
      tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byIcon(const Theme().icons.confirm),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform,
      Matrix4.diagonal3Values(1, 1, 1),
    );
  });

  testWidgets('unchecked is a quiet neutral outline', (tester) async {
    await pump(tester, Checkbox(value: false, onChanged: (_) {}));
    await tester.pumpAndSettle();

    final style = const Theme().widgets.checkbox.resolve();
    final decoration = decorationOf(tester);
    expect(decoration?.color?.a, 0);
    expect((decoration?.border as Border?)?.top.color, style.unchecked.border);
  });

  testWidgets('the variant dresses the box, like any surface', (tester) async {
    await pump(
      tester,
      Checkbox(
        value: true,
        onChanged: (_) {},
        variant: SurfaceVariant.soft,
        swatch: SemanticSwatch.success,
      ),
    );
    await tester.pumpAndSettle();

    final expected = const Theme().widgets.surface.resolve(
      SemanticSwatch.success,
      SurfaceVariant.soft,
    );
    expect(decorationOf(tester)?.color, expected.fill);
  });

  testWidgets('an outline checkbox has no fill in either state', (
    tester,
  ) async {
    for (final value in [false, true]) {
      await pump(
        tester,
        Checkbox(
          value: value,
          onChanged: (_) {},
          variant: SurfaceVariant.outline,
        ),
      );
      await tester.pumpAndSettle();
      // Fill-less in both states: what's there is the resting wash, faded
      // out entirely.
      expect(decorationOf(tester)?.color?.a, 0, reason: 'checked: $value');
    }

    // And the check wears the swatch rather than a contrast colour.
    final style = const Theme().widgets.checkbox.resolve(
      SemanticSwatch.primary,
      SurfaceVariant.outline,
    );
    final icon = tester.widget<Icon>(find.byIcon(const Theme().icons.confirm));
    expect(
      IconTheme.of(tester.element(find.byWidget(icon))).color,
      style.checked.foreground,
    );
  });

  testWidgets('solid rests as an outline — an empty box is never filled', (
    tester,
  ) async {
    final style = const Theme().widgets.checkbox.resolve();
    expect(style.unchecked.fill, isNull);
    expect(style.unchecked.border, isNotNull);
    // Every other variant rests in its own dress, on neutral.
    final soft = const Theme().widgets.checkbox.resolve(
      SemanticSwatch.primary,
      SurfaceVariant.soft,
    );
    expect(
      soft.unchecked.fill,
      const Theme().widgets.surface
          .resolve(SemanticSwatch.neutral, SurfaceVariant.soft)
          .fill,
    );
  });

  testWidgets('a placeholder checkbox keeps its dashes through the toggle', (
    tester,
  ) async {
    for (final value in [false, true]) {
      await pump(
        tester,
        Checkbox(
          value: value,
          onChanged: (_) {},
          variant: SurfaceVariant.placeholder,
        ),
      );
      await tester.pumpAndSettle();
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(Surface),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(
        paint.foregroundPainter,
        isNotNull,
        reason: 'dashed border, checked: $value',
      );
    }
  });

  testWidgets('the ring is the swatch at full voice, whatever the variant', (
    tester,
  ) async {
    for (final variant in SurfaceVariant.values) {
      final style = const Theme().widgets.checkbox.resolve(
        SemanticSwatch.error,
        variant,
      );
      expect(
        style.ring,
        const Theme().widgets.surface
            .resolve(SemanticSwatch.error, SurfaceVariant.solid)
            .fill,
        reason: '$variant',
      );
    }
  });

  testWidgets('the box is the styled size', (tester) async {
    await pump(tester, Checkbox(value: false, onChanged: (_) {}));
    final size = const Theme().widgets.checkbox.resolve().size;
    expect(tester.getSize(find.byType(Surface)), Size(size, size));
  });

  testWidgets('keyboard: tab focuses, Enter toggles', (tester) async {
    bool? reported;
    await pump(
      tester,
      Checkbox(value: false, onChanged: (value) => reported = value),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(reported, isTrue);
  });

  testWidgets('null onChanged disables: dimmed, ignored', (tester) async {
    await pump(tester, const Checkbox(value: false, onChanged: null));

    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(Checkbox),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, const Opacities().disabled);
    await tester.tap(find.byType(Checkbox), warnIfMissed: false);
  });

  testWidgets('the label is part of the control: clicking it toggles', (
    tester,
  ) async {
    var toggles = 0;
    await pump(
      tester,
      Checkbox(
        value: false,
        onChanged: (_) => toggles++,
        label: const Text('Stow the sails'),
      ),
    );

    await tester.tap(find.text('Stow the sails'));
    expect(toggles, 1);

    // And the box itself still works.
    await tester.tap(find.byType(Surface));
    expect(toggles, 2);
  });

  testWidgets('the label keeps the ambient text style', (tester) async {
    await pump(
      tester,
      Checkbox(value: true, onChanged: (_) {}, label: const Text('Label')),
    );
    await tester.pumpAndSettle();

    // Page text, not the checked box's contrast colour.
    final style = DefaultTextStyle.of(tester.element(find.text('Label')));
    expect(style.style.color, const Palette().text);
  });

  testWidgets('custom paints the style exactly as given', (tester) async {
    const style = CheckboxStyle(
      checked: SurfaceStyle(
        foreground: Color(0xFFFFFFFF),
        fill: Color(0xFF112233),
      ),
      unchecked: SurfaceStyle(
        foreground: Color(0xFF445566),
        border: Color(0xFF445566),
      ),
      ring: Color(0xFF112233),
      size: 28,
    );
    await pump(
      tester,
      Checkbox.custom(value: true, onChanged: (_) {}, style: style),
    );
    await tester.pumpAndSettle();

    expect(decorationOf(tester)?.color, const Color(0xFF112233));
    expect(tester.getSize(find.byType(Surface)), const Size(28, 28));
  });
}
