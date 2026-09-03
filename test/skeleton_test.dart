import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool animations = true,
  }) => tester.pumpWidget(
    TomeApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: !animations),
        child: Center(child: child),
      ),
    ),
  );

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(Skeleton),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .first
              .decoration
          as BoxDecoration;

  testWidgets('a box is the size it was given, in the resting fill', (
    tester,
  ) async {
    await pump(tester, const Skeleton.box(width: 120, height: 80));

    expect(tester.getSize(find.byType(Skeleton)), const Size(120, 80));
    expect(
      decorationOf(tester).color,
      const Theme().widgets.skeleton.resolve().fill,
    );
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('the sheen travels: the band is not where it was', (
    tester,
  ) async {
    await pump(tester, const Skeleton.box(width: 120, height: 80));

    await tester.pump(const Duration(milliseconds: 100));
    final early = decorationOf(tester).gradient! as LinearGradient;
    await tester.pump(const Duration(milliseconds: 400));
    final later = decorationOf(tester).gradient! as LinearGradient;

    // The band moves by its geometry, not by squeezing its stops, so it
    // slides off each edge whole instead of piling up against it.
    expect(later.begin, isNot(early.begin));
    expect(later.end, isNot(early.end));
    expect(early.stops, later.stops);

    final style = const Theme().widgets.skeleton.resolve();
    expect(
      early.colors[1],
      Color.alphaBlend(style.sheen, style.fill),
      reason: 'the light in the middle of the sweep, blended onto the fill',
    );
  });

  testWidgets('one light, not two: every stop of the sweep is opaque', (
    tester,
  ) async {
    await pump(tester, const Skeleton.box(width: 120, height: 80));
    await tester.pump(const Duration(milliseconds: 300));

    final sweep = decorationOf(tester).gradient! as LinearGradient;
    // A ramp from an opaque fill to a translucent sheen is *brightest*
    // halfway along it, which paints two bright shoulders around a dark
    // core — one pass of the light, arriving as two.
    for (final color in sweep.colors) {
      expect(color.a, 1, reason: '$color is translucent');
    }
  });

  testWidgets('asked for less motion, it holds still', (tester) async {
    await pump(
      tester,
      const Skeleton.box(width: 120, height: 80),
      animations: false,
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(decorationOf(tester).gradient, isNull);
    expect(
      decorationOf(tester).color,
      const Theme().widgets.skeleton.resolve().fill,
      reason: 'still a shape, just not a shimmering one',
    );
  });

  testWidgets('text is lines, and the last one is short', (tester) async {
    await pump(
      tester,
      const SizedBox(width: 200, child: Skeleton.text(lines: 3)),
    );

    final boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(Skeleton),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(boxes.length, 3);

    final style = const Theme().widgets.skeleton.resolve();
    final rects = [
      for (final box
          in find
              .descendant(
                of: find.byType(Skeleton),
                matching: find.byType(DecoratedBox),
              )
              .evaluate())
        tester.getRect(find.byWidget(box.widget)),
    ];
    expect(rects.first.width, 200);
    expect(rects.last.width, 200 * style.lastLineFraction);
    expect(rects.first.height, style.lineHeight);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('a circle is round', (tester) async {
    await pump(tester, const Skeleton.circle(size: 40));

    expect(tester.getSize(find.byType(Skeleton)), const Size(40, 40));
    expect(decorationOf(tester).borderRadius, BorderRadius.circular(20));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('it says it is loading, for a reader who cannot see it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Skeleton.box(width: 40, height: 40));

    expect(
      tester.getSemantics(find.byType(Skeleton)),
      matchesSemantics(label: const Labels().loading),
    );
    handle.dispose();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
