import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  /// The spinner's painter, which is private — hence `dynamic`.
  dynamic spinnerPainter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(Progress),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as dynamic;

  testWidgets('a measured bar fills the share it was given', (tester) async {
    await pump(
      tester,
      const SizedBox(width: 200, child: Progress.bar(value: 0.25)),
    );

    final fill = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(Progress),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(fill.widthFactor, 0.25);
  });

  testWidgets('the fill is as tall as the bar, not nought pixels', (
    tester,
  ) async {
    await pump(
      tester,
      const SizedBox(width: 200, child: Progress.bar(value: 0.25)),
    );

    final painted = [
      for (final box
          in find
              .descendant(
                of: find.byType(Progress),
                matching: find.byType(DecoratedBox),
              )
              .evaluate())
        tester.getRect(find.byWidget(box.widget)),
    ];
    final style = const Theme().widgets.progress.resolve();
    // The groove, then the share of it that has happened — both the full
    // thickness. An [Align] around the fraction loosens the height it
    // hands down, and a childless [DecoratedBox] under a loose height is
    // a fill nobody can see.
    expect(painted.first.size, Size(200, style.thickness));
    expect(painted.last.size, Size(50, style.thickness));
  });

  testWidgets('on a surface already wearing its voice, it takes the '
      'surface\'s instead', (tester) async {
    await pump(
      tester,
      Button(
        onPressed: () {},
        leading: const Progress.spinner(value: 0.5),
        center: const Text('Signing…'),
      ),
    );

    final theme = const Theme();
    final button = theme.widgets.button.resolve(
      SemanticSwatch.primary,
      SurfaceVariant.solid,
    );
    final painter = spinnerPainter(tester);

    // A primary indicator on a solid primary button *is* the button.
    expect(painter.indicator, isNot(button.surface.fill));
    expect(painter.indicator, button.surface.foreground);
    expect(painter.track.a, lessThan(1));
  });

  testWidgets('the pointer resting on the button does not invert it', (
    tester,
  ) async {
    await pump(
      tester,
      Button(
        onPressed: () {},
        leading: const Progress.spinner(value: 0.5),
        center: const Text('Signing…'),
      ),
    );

    // Hover highlights are only shown under the traditional strategy, and
    // a test starts out assuming touch.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    addTearDown(() => pointer.removePointer());
    await tester.pump();
    await pointer.moveTo(tester.getCenter(find.byType(Button)));
    await tester.pumpAndSettle();

    final washed = tester
        .widget<Surface>(
          find.descendant(
            of: find.byType(Button),
            matching: find.byType(Surface),
          ),
        )
        .style!
        .fill!;

    // The hover wash lifts the button's fill, which is enough to make two
    // colours unequal and nowhere near enough to make one visible on the
    // other: the swap has to survive it.
    final button = const Theme().widgets.button.resolve(
      SemanticSwatch.primary,
      SurfaceVariant.solid,
    );
    expect(washed, isNot(button.surface.fill), reason: 'the wash landed');
    expect(spinnerPainter(tester).indicator, button.surface.foreground);
  });

  testWidgets('off any surface it keeps the swatch at full voice', (
    tester,
  ) async {
    await pump(tester, const Progress.spinner(value: 0.5));

    final painter = spinnerPainter(tester);
    expect(
      painter.indicator,
      const Theme().widgets.progress.resolve().indicator,
    );
  });

  testWidgets('a value outside nought and one is brought back inside', (
    tester,
  ) async {
    await pump(
      tester,
      const SizedBox(width: 200, child: Progress.bar(value: 4)),
    );

    final fill = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(Progress),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(fill.widthFactor, 1);
  });

  testWidgets('work of unknown length moves; measured work does not', (
    tester,
  ) async {
    await pump(tester, const SizedBox(width: 200, child: Progress.bar()));
    await tester.pump(const Duration(milliseconds: 100));
    final moving = tester
        .widget<FractionallySizedBox>(
          find.descendant(
            of: find.byType(Progress),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .alignment;
    await tester.pump(const Duration(milliseconds: 300));
    final later = tester
        .widget<FractionallySizedBox>(
          find.descendant(
            of: find.byType(Progress),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .alignment;
    expect(later, isNot(moving), reason: 'the sweep travelled');

    // A measured bar has nothing to animate: pumping settles it.
    await pump(
      tester,
      const SizedBox(width: 200, child: Progress.bar(value: 0.5)),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('the bar fills a slot that has a width, and takes the style’s '
      'where there is none', (tester) async {
    await pump(
      tester,
      const SizedBox(width: 300, child: Progress.bar(value: 0.5)),
    );
    expect(tester.getSize(find.byType(Progress)).width, 300);

    // A row hands its children all the width in the world, which is no
    // width at all to lay a bar along.
    await pump(
      tester,
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Progress.bar(value: 0.5)],
      ),
    );
    expect(
      tester.getSize(find.byType(Progress)).width,
      const Theme().widgets.progress.resolve().minWidth,
    );
  });

  testWidgets('the spinner is square and the size the style says', (
    tester,
  ) async {
    await pump(tester, const Progress.spinner());

    final style = const Theme().widgets.progress.resolve();
    expect(
      tester.getSize(find.byType(Progress)),
      Size(style.spinnerSize, style.spinnerSize),
    );
  });

  testWidgets('it says what it is doing, and how far along when it knows', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Progress.bar(value: 0.4));

    expect(
      tester.getSemantics(find.byType(Progress)),
      matchesSemantics(label: const Labels().loading, value: '40%'),
    );
    handle.dispose();
  });
}
