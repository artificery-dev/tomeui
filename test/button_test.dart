import 'package:flutter/gestures.dart';
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

  testWidgets('fires onPressed on tap', (tester) async {
    var pressed = 0;
    await pump(
      tester,
      Button(onPressed: () => pressed++, center: const Text('Save')),
    );

    await tester.tap(find.byType(Button));
    expect(pressed, 1);
  });

  testWidgets('wears its swatch and variant like a surface', (tester) async {
    await pump(
      tester,
      Button(
        onPressed: () {},
        variant: SurfaceVariant.soft,
        swatch: SemanticSwatch.error,
        center: const Text('Delete'),
      ),
    );

    final expected = const Theme().widgets.button
        .resolve(SemanticSwatch.error, SurfaceVariant.soft)
        .surface
        .fill;
    expect(decorationOf(tester)?.color, expected);
  });

  testWidgets('stands at control height', (tester) async {
    await pump(tester, Button(onPressed: () {}, center: const Text('x')));
    expect(tester.getSize(find.byType(Button)).height, const Sizes().control);
  });

  testWidgets('squeezed, the centre yields rather than overflowing', (
    tester,
  ) async {
    // The centre rides in a loose Flexible: a room too small for the label
    // squeezes the label, while the leading glyph keeps its size. A plain
    // child would take unbounded width from the row and overflow the
    // button — a Select's trigger in a narrow field was the first casualty.
    await pump(
      tester,
      SizedBox(
        width: 90,
        child: Button(
          onPressed: () {},
          leading: const Icon(LucideIcons.check, size: 14),
          center: const Text(
            'A label far too long for the room',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hover washes the fill; release lets it go', (tester) async {
    // Hover highlights only show in traditional (pointer) highlight mode;
    // the test platform defaults to touch.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await pump(tester, Button(onPressed: () {}, center: const Text('x')));
    final resting = decorationOf(tester)?.color;

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(Button)));
    await tester.pumpAndSettle();

    final hovered = decorationOf(tester)?.color;
    expect(hovered, isNot(resting));

    final style = const Theme().widgets.button.resolve();
    expect(hovered, Color.alphaBlend(style.hover!, style.surface.fill!));

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(decorationOf(tester)?.color, resting);
  });

  testWidgets('lifts on hover, sinks below rest while pressed', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await pump(tester, Button(onPressed: () {}, center: const Text('x')));

    double scaleOf() => tester
        .widget<AnimatedScale>(
          find.descendant(
            of: find.byType(Button),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;

    final lift = const Theme().widgets.button.resolve().lift;
    expect(scaleOf(), 1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(Button)));
    await tester.pump();
    expect(scaleOf(), 1 + lift);

    await mouse.down(tester.getCenter(find.byType(Button)));
    await tester.pump();
    expect(scaleOf(), 1 - lift);

    await mouse.up();
    await tester.pump();
    expect(scaleOf(), 1 + lift);
  });

  testWidgets('a ghost button is felt when touched', (tester) async {
    await pump(
      tester,
      Button(
        onPressed: () {},
        variant: SurfaceVariant.ghost,
        center: const Text('x'),
      ),
    );
    // At rest the wash is present but fully faded, ready to fade in.
    expect(decorationOf(tester)?.color?.a, 0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Button)),
    );
    await tester.pumpAndSettle();
    final style = const Theme().widgets.button.resolve(
      SemanticSwatch.primary,
      SurfaceVariant.ghost,
    );
    expect(decorationOf(tester)?.color, style.pressed);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('null onPressed disables: dimmed, ignored', (tester) async {
    await pump(tester, const Button(onPressed: null, center: Text('x')));

    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(Button),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, const Opacities().disabled);

    // Tapping a disabled button does nothing and doesn't throw.
    await tester.tap(find.byType(Button), warnIfMissed: false);
  });

  testWidgets('keyboard focus draws the ring; Enter activates', (tester) async {
    var pressed = 0;
    await pump(
      tester,
      Button(onPressed: () => pressed++, center: const Text('x')),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final ringed = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(Button),
            matching: find.byType(CustomPaint),
          ),
        )
        .where((paint) => paint.foregroundPainter != null);
    expect(ringed, hasLength(1));
    final ring = ringed.single.foregroundPainter! as dynamic;
    expect(ring.color, const Theme().widgets.button.resolve().ring);
    expect(ring.width, const Strokes().focus);
    // Outset, with a hairline of daylight between ring and edge.
    expect(ring.gap, const Strokes().hairline);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressed, 1);
  });

  testWidgets('custom paints the style exactly as given', (tester) async {
    const style = ButtonStyle(
      surface: SurfaceStyle(
        foreground: Color(0xFF123456),
        fill: Color(0xFF654321),
      ),
      ring: Color(0xFF000000),
      height: 52,
    );
    await pump(
      tester,
      Button.custom(onPressed: () {}, style: style, child: const Text('x')),
    );

    expect(decorationOf(tester)?.color, const Color(0xFF654321));
    expect(tester.getSize(find.byType(Button)).height, 52);
  });
}
