import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? value = 'Log',
    ValueChanged<String>? onChanged,
    List<TabOption<String>>? tabs,
    double width = 600,
  }) => tester.pumpWidget(
    TomeApp(
      home: Center(
        child: SizedBox(
          width: width,
          child: Tabs<String>(
            value: value,
            onChanged: onChanged ?? (_) {},
            tabs:
                tabs ??
                const [
                  TabOption(value: 'Log', label: Text('Log')),
                  TabOption(value: 'Crew', label: Text('Crew')),
                  TabOption(value: 'Cargo', label: Text('Cargo')),
                ],
          ),
        ),
      ),
    ),
  );

  /// What one tab is dressed in.
  BoxDecoration dressOf(WidgetTester tester, String label) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .ancestor(
                      of: find.text(label),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration
          as BoxDecoration;

  testWidgets('the tab you are on wears the swatch; the rest stay quiet', (
    tester,
  ) async {
    await pump(tester);

    final style = const Theme().widgets.tabs.resolve();
    expect(dressOf(tester, 'Log').color, style.selected.fill);
    expect(dressOf(tester, 'Crew').color, style.unselected.fill);
    expect(
      style.unselected.fill,
      const Theme().widgets.surface
          .resolve(SemanticSwatch.neutral, SurfaceVariant.subtle)
          .fill,
      reason: 'the quietest surface there is',
    );
  });

  testWidgets('tapping a tab reports it, and tapping the open one does not', (
    tester,
  ) async {
    final chosen = <String>[];
    await pump(tester, onChanged: chosen.add);

    await tester.tap(find.text('Crew'));
    await tester.pump();
    expect(chosen, ['Crew']);

    await tester.tap(find.text('Log'), warnIfMissed: false);
    await tester.pump();
    expect(chosen, ['Crew'], reason: 'Log is already what is showing');
  });

  testWidgets('the arrows walk the strip and the ends stop it', (tester) async {
    final chosen = <String>[];
    await pump(tester, onChanged: chosen.add);

    // Tab into the strip: it's one focus stop, the way a radio group is.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(chosen, ['Crew']);

    // The value is still Log — this is a controlled widget — so walking
    // left from the first tab reports nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(chosen, ['Crew']);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(chosen, ['Crew', 'Cargo']);
  });

  testWidgets('a disabled tab is stepped over, not landed on', (tester) async {
    final chosen = <String>[];
    await pump(
      tester,
      onChanged: chosen.add,
      tabs: const [
        TabOption(value: 'Log', label: Text('Log')),
        TabOption(value: 'Crew', label: Text('Crew'), enabled: false),
        TabOption(value: 'Cargo', label: Text('Cargo')),
      ],
    );

    await tester.tap(find.text('Crew'), warnIfMissed: false);
    await tester.pump();
    expect(chosen, isEmpty);

    // Tab into the strip: it's one focus stop, the way a radio group is.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(chosen, ['Cargo'], reason: 'straight past Crew');
  });

  testWidgets('a null onChanged disables the strip', (tester) async {
    await pump(tester, onChanged: null, value: 'Log');
    await tester.pumpWidget(
      TomeApp(
        home: const Center(
          child: Tabs<String>(
            value: 'Log',
            onChanged: null,
            tabs: [
              TabOption(value: 'Log', label: Text('Log')),
              TabOption(value: 'Crew', label: Text('Crew')),
            ],
          ),
        ),
      ),
    );

    final dimmed = tester.widget<AnimatedOpacity>(
      find
          .descendant(
            of: find.byType(Tabs<String>),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(dimmed.opacity, const Theme().opacities.disabled);
  });

  testWidgets('the strip scrolls rather than squeezing its words', (
    tester,
  ) async {
    await pump(
      tester,
      width: 200,
      tabs: const [
        TabOption(value: 'Log', label: Text('Ship’s log')),
        TabOption(value: 'Crew', label: Text('Crew list')),
        TabOption(value: 'Cargo', label: Text('Cargo manifest')),
      ],
    );

    expect(tester.takeException(), isNull, reason: 'no overflow');
    final scroll = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(Tabs<String>),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
  });

  testWidgets('tabs sit shoulder to shoulder, square where the pane begins', (
    tester,
  ) async {
    await pump(tester);

    final log = tester.getRect(
      find
          .ancestor(
            of: find.text('Log'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final crew = tester.getRect(
      find
          .ancestor(
            of: find.text('Crew'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(crew.left, moreOrLessEquals(log.right, epsilon: 0.5));

    final radius = dressOf(tester, 'Log').borderRadius! as BorderRadius;
    expect(radius.topLeft.y, greaterThan(0));
    expect(radius.bottomLeft, Radius.zero, reason: 'the pane begins here');
    expect(radius.bottomRight, Radius.zero);
  });

  testWidgets('a tab that can be shut says so on the one you are on, and '
      'on the one under the pointer', (tester) async {
    var shut = 0;
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: Tabs<String>(
            value: 'Log',
            onChanged: (_) {},
            tabs: [
              TabOption(
                value: 'Log',
                label: const Text('Log'),
                onClose: () => shut++,
              ),
              const TabOption(value: 'Crew', label: Text('Crew')),
            ],
          ),
        ),
      ),
    );

    // The tab you're on shows its cross; the one that can't be shut has
    // none at all.
    final crosses = find.byIcon(const Icons().close);
    expect(crosses, findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(of: crosses, matching: find.byType(AnimatedOpacity))
                .first,
          )
          .opacity,
      1,
    );

    await tester.tap(crosses);
    await tester.pump();
    expect(shut, 1);
  });

  testWidgets('a cross on a tab you are not on keeps its place, unseen', (
    tester,
  ) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: Tabs<String>(
            value: 'Log',
            onChanged: (_) {},
            tabs: [
              TabOption(value: 'Log', label: const Text('Log'), onClose: () {}),
              TabOption(
                value: 'Crew',
                label: const Text('Crew'),
                onClose: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final resting = tester.widgetList<AnimatedOpacity>(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Crew'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(resting.map((each) => each.opacity), contains(0));

    // Laid out all the same: a strip that grew as the pointer crossed it
    // would move the next tab out from under the one going to press it.
    final cross = find.descendant(
      of: find
          .ancestor(
            of: find.text('Crew'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
      matching: find.byIcon(const Icons().close),
    );
    expect(tester.getSize(cross).width, greaterThan(0));
  });

  testWidgets('the cross sits against the trailing edge, not a padding in '
      'from it', (tester) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: Tabs<String>(
            value: 'Log',
            onChanged: (_) {},
            tabs: [
              TabOption(value: 'Log', label: const Text('Log'), onClose: () {}),
            ],
          ),
        ),
      ),
    );

    final style = const Theme().widgets.tabs.resolve();
    final pad = style.padding.resolve(TextDirection.ltr).right;
    final tab = tester.getRect(
      find
          .ancestor(
            of: find.text('Log'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final cross = tester.getRect(find.byIcon(const Icons().close));

    // The cross keeps a box of its own around the glyph, so the tab gives
    // back half of it: the padding was otherwise counted twice.
    expect(
      tab.right - cross.right,
      moreOrLessEquals(pad - style.closeSize / 2, epsilon: 0.5),
    );
  });
}
