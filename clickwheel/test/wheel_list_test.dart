import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

/// The rubber band past a list's ends and the scrollbar beside them
/// belong to lists that scroll: a list that fits on the screen is simply
/// at its end, stays still, and wears no bar.
void main() {
  Future<ClickWheelController> pumpList(
    WidgetTester tester, {
    required int rows,
  }) async {
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            ClickWheelInput(controller: wheel, child: child!),
        home: SizedBox(
          height: 300,
          child: WheelList(
            itemExtent: 40,
            autofocus: true,
            children: [for (var i = 0; i < rows; i++) Text('Row $i')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return wheel;
  }

  group('initial selection', () {
    for (final variable in [false, true]) {
      for (final selected in [25, 39]) {
        testWidgets(
          'reveals row $selected on the first frame (variable: $variable)',
          (tester) async {
            const viewport = Key('viewport');
            const rowKey = Key('selected-row');
            await tester.pumpWidget(
              TomeApp(
                home: Center(
                  child: SizedBox(
                    key: viewport,
                    width: 240,
                    height: 200,
                    child: WheelList.builder(
                      initialIndex: selected,
                      itemCount: 40,
                      itemExtent: 40,
                      extentOf: variable ? (i) => i.isEven ? 28 : 72 : null,
                      itemBuilder: (_, i, _) => SizedBox.expand(
                        key: i == selected ? rowKey : null,
                        child: Text('Row $i'),
                      ),
                    ),
                  ),
                ),
              ),
            );
            // No extra frame or wheel jog: the selection must already be visible.
            final bounds = tester.getRect(find.byKey(viewport));
            final row = tester.getRect(find.byKey(rowKey));
            expect(row.top, greaterThanOrEqualTo(bounds.top));
            expect(row.bottom, lessThanOrEqualTo(bounds.bottom));
            final position = tester
                .state<ScrollableState>(find.byType(Scrollable))
                .position;
            expect(
              position.pixels,
              inInclusiveRange(0, position.maxScrollExtent),
            );
            expect(position.pixels, greaterThan(0));
            final offset = position.pixels;
            await tester.pump();
            expect(
              position.pixels,
              offset,
              reason: 'no jump after the first frame',
            );
          },
        );
      }
    }

    testWidgets(
      'keeps an explicit top row when the selection is already visible',
      (tester) async {
        await tester.pumpWidget(
          TomeApp(
            home: Center(
              child: SizedBox(
                width: 240,
                height: 200,
                child: WheelList(
                  initialIndex: 2,
                  initialTopRow: 2,
                  itemExtent: 40,
                  children: [for (var i = 0; i < 4; i++) Text('Row $i')],
                ),
              ),
            ),
          ),
        );
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;
        expect(position.pixels, 80);
        expect(position.maxScrollExtent, 80);
      },
    );
  });

  double pull(WidgetTester tester) {
    final transform = tester.widget<Transform>(find.byKey(WheelList.bandKey));
    return transform.transform.getTranslation().y;
  }

  testWidgets('a list that fits does not stretch past its ends', (
    tester,
  ) async {
    final wheel = await pumpList(tester, rows: 3);
    wheel.jog(-2);
    await tester.pump();
    expect(pull(tester), 0);
    wheel.jog(6);
    await tester.pump();
    expect(pull(tester), 0);
  });

  testWidgets('a list longer than the screen stretches, and lets go', (
    tester,
  ) async {
    final wheel = await pumpList(tester, rows: 40);
    wheel.jog(-2);
    await tester.pump();
    expect(pull(tester), greaterThan(0), reason: 'pulled past the top');
    // The wheel goes still, the band lets go and springs home.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(pull(tester).abs(), lessThan(0.5), reason: 'let go');
  });

  testWidgets('a list that scrolls wears a scrollbar with a track and a '
      'thumb no shorter than a row; one that fits wears none', (tester) async {
    await pumpList(tester, rows: 3);
    expect(find.byType(RawScrollbar), findsNothing);

    await pumpList(tester, rows: 40);
    final bar = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
    expect(bar.thumbVisibility, isTrue);
    expect(bar.trackVisibility, isTrue);
    expect(bar.minThumbLength, 40);
    final theme = ThemeProvider.of(tester.element(find.byType(RawScrollbar)));
    expect(
      bar.thumbColor,
      theme.widgets.surface
          .resolve(SemanticSwatch.primary, SurfaceVariant.solid)
          .fill,
    );
  });

  group('wrapping at the ends', () {
    /// A wrapping list of [rows], reporting where the selection lands.
    Future<(ClickWheelController, List<int>)> pumpWrapping(
      WidgetTester tester, {
      int rows = 4,
      bool wrap = true,
    }) async {
      final wheel = ClickWheelController();
      final landed = <int>[];
      await tester.pumpWidget(
        TomeApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) =>
              ClickWheelInput(controller: wheel, child: child!),
          home: SizedBox(
            height: 300,
            child: WheelList(
              itemExtent: 40,
              autofocus: true,
              wrap: wrap,
              onSelectionChanged: landed.add,
              children: [for (var i = 0; i < rows; i++) Text('Row $i')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (wheel, landed);
    }

    testWidgets('a detent past the last row comes back to the first', (
      tester,
    ) async {
      final (wheel, landed) = await pumpWrapping(tester);
      wheel.jog(3);
      await tester.pump();
      expect(landed.last, 3, reason: 'at the end');

      wheel.jog(1);
      await tester.pump();
      expect(landed.last, 0);

      // And the other way, off the front.
      wheel.jog(-1);
      await tester.pump();
      expect(landed.last, 3);
    });

    testWidgets('and does not, where the list does not wrap', (tester) async {
      final (wheel, landed) = await pumpWrapping(tester, wrap: false);
      wheel.jog(3);
      await tester.pump();
      wheel.jog(1);
      await tester.pump();
      expect(landed.last, 3, reason: 'the end is the end');
    });

    testWidgets('a fast spin still stops at the end', (tester) async {
      // A page that wrapped would carry the selection somewhere nobody
      // was looking - the end of a long list is where a spin should stop.
      final (wheel, landed) = await pumpWrapping(tester, rows: 40);
      wheel.jog(1, page: true);
      await tester.pump();
      final first = landed.last;
      for (var i = 0; i < 20; i++) {
        wheel.jog(1, page: true);
        await tester.pump();
      }
      expect(landed.last, 39);
      expect(first, lessThan(39), reason: 'it took more than one spin');
    });

    testWidgets('a list of one row has nowhere to wrap to', (tester) async {
      final (wheel, landed) = await pumpWrapping(tester, rows: 1);
      wheel.jog(1);
      await tester.pump();
      expect(landed, isEmpty);
    });
  });

  group('the row dress', () {
    /// The fill the dress paints, or null where it paints none.
    Color? fillUnder(WidgetTester tester, String text) {
      final boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.ancestor(
            of: find.text(text),
            matching: find.byType(WheelRowDress),
          ),
          matching: find.byType(DecoratedBox),
        ),
      );
      for (final box in boxes) {
        final decoration = box.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          return decoration.color;
        }
      }
      return null;
    }

    testWidgets('marks the selected row and leaves the rest alone', (
      tester,
    ) async {
      final wheel = await pumpList(tester, rows: 3);
      expect(fillUnder(tester, 'Row 0'), isNotNull);
      expect(fillUnder(tester, 'Row 1'), isNull);

      wheel.jog(1);
      await tester.pump();
      expect(fillUnder(tester, 'Row 0'), isNull);
      expect(fillUnder(tester, 'Row 1'), isNotNull);
    });

    testWidgets('a row does not move when the cursor arrives on it', (
      tester,
    ) async {
      final wheel = await pumpList(tester, rows: 3);
      final before = tester.getRect(find.text('Row 1'));
      expect(tester.getRect(find.text('Row 0')).left, before.left);

      wheel.jog(1);
      await tester.pump();
      expect(
        tester.getRect(find.text('Row 1')),
        before,
        reason: 'the words shifted under the cursor',
      );
      // And the row it left is where it was too.
      expect(tester.getRect(find.text('Row 0')).left, before.left);
    });

    testWidgets('and every row keeps the same room at the edges', (
      tester,
    ) async {
      await pumpList(tester, rows: 3);
      final viewport = tester.getRect(find.byType(WheelList));
      for (final row in ['Row 0', 'Row 1', 'Row 2']) {
        expect(
          tester.getRect(find.text(row)).left,
          greaterThan(viewport.left),
          reason: '$row was flush with the edge',
        );
      }
    });

    testWidgets('and says which row it is, dressed or not', (tester) async {
      // A builder row that dresses itself still reads the selection off
      // the same widget, so wrapping in the dress is enough.
      await pumpList(tester, rows: 2);
      final rows = tester.widgetList<WheelRowDress>(find.byType(WheelRowDress));
      expect(rows.where((row) => row.selected), hasLength(1));
    });
  });

  platformScrollbarTests();
  variedExtentTests();
}

/// A list whose rows are not all the same height: a settings list, where a
/// slider tile carries a track and a switch tile does not. The offsets stop
/// being a multiplication and become a sum, and everything that reads them -
/// revealing the selection, a page leap, whether there is a bar at all - has
/// to follow.
void variedExtentTests() {
  /// Three rows of 20 and then three of 60, in a viewport of 100.
  Future<ClickWheelController> pumpVaried(
    WidgetTester tester, {
    int rows = 6,
    double height = 100,
  }) async {
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            ClickWheelInput(controller: wheel, child: child!),
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: height,
            width: 200,
            child: WheelList(
              itemExtent: 20,
              extentOf: (index) => index < 3 ? 20 : 60,
              autofocus: true,
              children: [
                for (var i = 0; i < rows; i++)
                  Text('Row $i', key: ValueKey('row.$i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return wheel;
  }

  double offset(WidgetTester tester) =>
      tester.widget<Scrollable>(find.byType(Scrollable)).controller!.offset;

  testWidgets('every row is drawn its own height', (tester) async {
    final wheel = await pumpVaried(tester);
    // Row 3 is the first tall one and shows from 60 down, so both kinds
    // are on screen at once; the rows past it are not built yet.
    expect(tester.getSize(find.byKey(const ValueKey('row.0'))).height, 20);
    expect(tester.getSize(find.byKey(const ValueKey('row.3'))).height, 60);
    expect(find.byKey(const ValueKey('row.5')), findsNothing);

    wheel.jog(5);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('row.5'))).height, 60);
  });

  testWidgets('the selection is revealed by the sum of the rows above it', (
    tester,
  ) async {
    final wheel = await pumpVaried(tester);
    expect(offset(tester), 0, reason: 'the short rows are all on screen');

    // Row 3 is the first tall one: it runs 60..120, so the least scroll
    // that shows all of it in a 100 viewport is 20.
    wheel.jog(3);
    await tester.pumpAndSettle();
    expect(offset(tester), 20);

    // Row 5 ends at 240.
    wheel.jog(2);
    await tester.pumpAndSettle();
    expect(offset(tester), 140);
  });

  testWidgets('a page leap counts the rows that fit from where it starts', (
    tester,
  ) async {
    final wheel = await pumpVaried(tester);
    // From row 0, a 100-tall page holds the three short rows and no more.
    wheel.jog(1, page: true);
    await tester.pumpAndSettle();
    expect(offset(tester), 20, reason: 'landed on the first tall row');

    // From a 60-tall row, a page is one row.
    wheel.jog(1, page: true);
    await tester.pumpAndSettle();
    expect(offset(tester), 80);
  });

  testWidgets('a varied list that fits wears no scrollbar, and one that '
      'does not, does', (tester) async {
    await pumpVaried(tester, rows: 3, height: 100);
    expect(find.byType(RawScrollbar), findsNothing);

    await pumpVaried(tester, rows: 6, height: 100);
    expect(find.byType(RawScrollbar), findsOneWidget);
  });
}

/// The platform adds no scrollbar of its own under the wheel: the list's
/// persistent bar is the only one.
void platformScrollbarTests() {
  testWidgets(
    'a scrolling list wears one bar, the list\'s own',
    (tester) async {
      final wheel = ClickWheelController();
      await tester.pumpWidget(
        TomeApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) =>
              ClickWheelInput(controller: wheel, child: child!),
          home: SizedBox(
            height: 120,
            child: WheelList(
              itemExtent: 40,
              autofocus: true,
              children: [for (var i = 0; i < 20; i++) Text('Row $i')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      wheel.jog(3);
      await tester.pump();
      // The platform's would be a second RawScrollbar around the viewport.
      expect(find.byType(RawScrollbar), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  headerTests();
}

void headerTests() {
  group('header', () {
    Future<ClickWheelController> pumpWithHeader(WidgetTester tester) async {
      final wheel = ClickWheelController();
      await tester.pumpWidget(
        TomeApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) =>
              ClickWheelInput(controller: wheel, child: child!),
          home: Center(
            child: SizedBox(
              height: 200,
              child: WheelList(
                itemExtent: 40,
                autofocus: true,
                header: const SizedBox(height: 120, child: Text('Lead')),
                children: [for (var i = 0; i < 12; i++) Text('Row $i')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return wheel;
    }

    testWidgets('opens with the header in view and the first row under it', (
      tester,
    ) async {
      await pumpWithHeader(tester);
      final top = tester.getTopLeft(find.byType(WheelList)).dy;
      expect(find.text('Lead'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Lead')).dy, top);
      expect(tester.getTopLeft(find.text('Row 0')).dy, top + 120);
    });

    testWidgets('scrolls away with the rows, and the selected row is '
        'revealed past it', (tester) async {
      final wheel = await pumpWithHeader(tester);
      final list = tester.getRect(find.byType(WheelList));
      wheel.jog(11);
      await tester.pumpAndSettle();
      // Scrolled off the top: past the list's reach, or above its edge.
      final lead = find.text('Lead');
      if (lead.evaluate().isNotEmpty) {
        expect(tester.getRect(lead).bottom, lessThanOrEqualTo(list.top));
      }
      final last = tester.getRect(find.text('Row 11'));
      expect(last.bottom, lessThanOrEqualTo(list.bottom));
      expect(last.top, greaterThanOrEqualTo(list.top));
      wheel.jog(-11);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Row 0')).dy,
        greaterThanOrEqualTo(list.top),
      );
    });
  });
}
