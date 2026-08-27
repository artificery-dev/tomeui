import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required int page,
    required int pageCount,
    ValueChanged<int>? onChanged,
    int siblings = 1,
  }) => tester.pumpWidget(
    TomeApp(
      home: Center(
        child: Pagination(
          page: page,
          pageCount: pageCount,
          onChanged: onChanged ?? (_) {},
          siblings: siblings,
        ),
      ),
    ),
  );

  testWidgets('a short run shows every page', (tester) async {
    await pump(tester, page: 1, pageCount: 4);

    for (final number in ['1', '2', '3', '4']) {
      expect(find.text(number), findsOneWidget, reason: number);
    }
    expect(find.text('…'), findsNothing);
  });

  testWidgets('a long run keeps the ends and elides the middle', (
    tester,
  ) async {
    await pump(tester, page: 20, pageCount: 42);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    for (final near in ['19', '20', '21']) {
      expect(find.text(near), findsOneWidget, reason: near);
    }
    expect(find.text('…'), findsNWidgets(2));
    expect(find.text('10'), findsNothing);
  });

  testWidgets('a gap of one page is that page, not an ellipsis', (
    tester,
  ) async {
    // 1 … 3 4 5 … 42 would hide only page 2, which is wider as an
    // ellipsis than as itself.
    await pump(tester, page: 4, pageCount: 42);

    expect(find.text('2'), findsOneWidget);
    expect(find.text('…'), findsOneWidget, reason: 'only the far side');
  });

  testWidgets('more siblings widen the window', (tester) async {
    await pump(tester, page: 20, pageCount: 42, siblings: 2);

    for (final near in ['18', '19', '20', '21', '22']) {
      expect(find.text(near), findsOneWidget, reason: near);
    }
  });

  testWidgets('tapping a page reports it; the one you are on does not', (
    tester,
  ) async {
    final went = <int>[];
    await pump(tester, page: 2, pageCount: 5, onChanged: went.add);

    await tester.tap(find.text('4'));
    await tester.pump();
    expect(went, [4]);

    await tester.tap(find.text('2'), warnIfMissed: false);
    await tester.pump();
    expect(went, [4]);
  });

  testWidgets('the arrows step, and die at the ends', (tester) async {
    final went = <int>[];
    await pump(tester, page: 1, pageCount: 3, onChanged: went.add);

    final arrows = find.byType(Icon);
    await tester.tap(arrows.last);
    await tester.pump();
    expect(went, [2], reason: 'forward from the first page');

    await tester.tap(arrows.first, warnIfMissed: false);
    await tester.pump();
    expect(went, [2], reason: 'there is nothing before page one');
  });

  testWidgets('the page you are on is the one wearing the swatch', (
    tester,
  ) async {
    await pump(tester, page: 2, pageCount: 3);

    ButtonStyle styleOf(String number) => tester
        .widget<Button>(
          find
              .ancestor(of: find.text(number), matching: find.byType(Button))
              .first,
        )
        .style!;

    final buttons = const Theme().widgets.button;
    expect(
      styleOf('2').surface,
      buttons.resolve(SemanticSwatch.primary, SurfaceVariant.solid).surface,
    );
    expect(
      styleOf('3').surface,
      buttons.resolve(SemanticSwatch.primary, SurfaceVariant.subtle).surface,
      reason: 'the rest wear the quietest surface there is',
    );
    // Answered, not disabled: the current page keeps its full voice even
    // though there is nothing to press.
    expect(styleOf('2').disabledOpacity, 1);
  });

  testWidgets('the run is the same width whichever page you are on', (
    tester,
  ) async {
    final widths = <double>{};
    for (final page in [1, 2, 5, 20, 38, 41, 42]) {
      await pump(tester, page: page, pageCount: 42);
      widths.add(tester.getSize(find.byType(Pagination)).width);
    }
    expect(widths, hasLength(1), reason: 'walked, it does not breathe');
  });

  testWidgets('every slot is a square, the elision included', (tester) async {
    await pump(tester, page: 20, pageCount: 42);

    final side = const Theme().widgets.button.resolve().height;
    final slots = find.descendant(
      of: find.byType(Pagination),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == side && widget.height == side,
      ),
    );

    // Two arrows, five numbers, two elisions — and every one of them the
    // size of a control, in both directions.
    expect(slots, findsNWidgets(9));
    for (final slot in slots.evaluate()) {
      expect(tester.getSize(find.byWidget(slot.widget)), Size.square(side));
    }
    // The elision keeps a place of its own rather than a gap of its own.
    expect(
      tester.getSize(find.ancestor(of: find.text('…'), matching: slots).first),
      Size.square(side),
    );
  });

  testWidgets('an elision never stands in for a single page', (tester) async {
    // Whatever the window, what it hides is worth hiding: an ellipsis over
    // one number is wider than the number.
    for (var page = 1; page <= 42; page++) {
      await pump(tester, page: page, pageCount: 42);
      final shown = [
        for (final text in tester.widgetList<Text>(
          find.descendant(
            of: find.byType(Pagination),
            matching: find.byType(Text),
          ),
        ))
          text.data!,
      ];
      for (final (index, slot) in shown.indexed) {
        if (slot != '…') continue;
        final before = int.parse(shown[index - 1]);
        final after = int.parse(shown[index + 1]);
        expect(after - before, greaterThan(2), reason: 'page $page');
      }
    }
  });

  testWidgets('a null onChanged disables every page and both arrows', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TomeApp(
        home: Center(child: Pagination(page: 2, pageCount: 5, onChanged: null)),
      ),
    );

    for (final button in tester.widgetList<Button>(find.byType(Button))) {
      expect(button.onPressed, isNull);
    }
  });
}
