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

  /// The line under one tab — transparent unless that tab is the chosen one.
  Color? indicatorUnder(WidgetTester tester, String label) {
    final indicator = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find
                .ancestor(of: find.text(label), matching: find.byType(Column))
                .last,
            matching: find.byType(AnimatedContainer),
          ),
        )
        .last;
    return (indicator.decoration as BoxDecoration?)?.color;
  }

  testWidgets('the chosen tab wears the line, and the others do not', (
    tester,
  ) async {
    await pump(tester);

    final indicator = const Theme().widgets.tabs.resolve().indicator;
    expect(indicatorUnder(tester, 'Log'), indicator);
    expect(indicatorUnder(tester, 'Crew')?.a, 0);
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

  testWidgets('the arrows walk the strip and the ends stop it', (
    tester,
  ) async {
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
}
