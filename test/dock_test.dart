import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

const _icons = Icons();

List<NavDestination<String>> _destinations(List<String> names) => [
  for (final name in names)
    NavDestination(value: name, label: Text(name), icon: _icons.home),
];

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<String> names,
    String? value,
    ValueChanged<String>? onChanged,
    Axis axis = Axis.horizontal,
    double extent = 600,
  }) => tester.pumpWidget(
    TomeApp(
      home: Center(
        child: SizedBox(
          width: axis == Axis.horizontal ? extent : null,
          height: axis == Axis.horizontal ? null : extent,
          child: Dock<String>(
            value: value ?? names.first,
            onChanged: onChanged ?? (_) {},
            axis: axis,
            destinations: _destinations(names),
          ),
        ),
      ),
    ),
  );

  testWidgets('every destination shows when they all fit', (tester) async {
    await pump(tester, names: ['Home', 'Crew', 'Cargo']);

    for (final name in ['Home', 'Crew', 'Cargo']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text(const Labels().more), findsNothing);
  });

  testWidgets('what does not fit goes to More, not off the end', (
    tester,
  ) async {
    // Three places at 80 apiece, once the dock's own padding is off the
    // top: two destinations show, and More takes the third place.
    await pump(
      tester,
      names: ['Home', 'Crew', 'Cargo', 'Log', 'Charts'],
      extent: 256,
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Crew'), findsOneWidget);
    expect(find.text('Cargo'), findsNothing, reason: 'behind More');
    expect(find.text(const Labels().more), findsOneWidget);
  });

  testWidgets('the overflow menu offers the rest, and choosing one reports '
      'it', (tester) async {
    final chosen = <String>[];
    await pump(
      tester,
      names: ['Home', 'Crew', 'Cargo', 'Log'],
      onChanged: chosen.add,
      extent: 256,
    );

    await tester.tap(find.text(const Labels().more));
    await tester.pumpAndSettle();
    expect(find.text('Log'), findsOneWidget, reason: 'in the menu now');

    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    expect(chosen, ['Log']);
  });

  testWidgets('More wears the chosen state when it is holding the answer', (
    tester,
  ) async {
    await pump(
      tester,
      names: ['Home', 'Crew', 'Cargo', 'Log'],
      value: 'Log',
      extent: 256,
    );

    final labels = tester.widgetList<DefaultTextStyle>(
      find.ancestor(
        of: find.text(const Labels().more),
        matching: find.byType(DefaultTextStyle),
      ),
    );
    final style = const Theme().widgets.dock.resolve();
    expect(
      labels.first.style.color,
      style.selectedStyle.color,
      reason: 'the answer is in there, so More says so',
    );
  });

  testWidgets('tapping a destination reports it; the open one reports '
      'nothing', (tester) async {
    final chosen = <String>[];
    await pump(
      tester,
      names: ['Home', 'Crew'],
      value: 'Home',
      onChanged: chosen.add,
    );

    await tester.tap(find.text('Crew'));
    await tester.pump();
    expect(chosen, ['Crew']);

    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(chosen, ['Crew']);
  });

  testWidgets('vertical is the rail: the same dock, stacked', (tester) async {
    await pump(
      tester,
      names: ['Home', 'Crew', 'Cargo'],
      axis: Axis.vertical,
      extent: 400,
    );

    final home = tester.getRect(find.text('Home'));
    final crew = tester.getRect(find.text('Crew'));
    expect(crew.top, greaterThan(home.bottom));
    expect(crew.left, home.left, reason: 'a column, not a diagonal');
  });

  testWidgets('a null onChanged disables the dock', (tester) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: SizedBox(
            width: 400,
            child: Dock<String>(
              value: 'Home',
              onChanged: null,
              destinations: _destinations(['Home', 'Crew']),
            ),
          ),
        ),
      ),
    );

    final dimmed = tester.widget<AnimatedOpacity>(
      find
          .descendant(
            of: find.byType(Dock<String>),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(dimmed.opacity, const Theme().opacities.disabled);
  });

  testWidgets('too narrow for even one place keeps a destination anyway, and '
      'the row squeezes rather than overflows', (tester) async {
    await pump(tester, names: ['Home', 'Crew', 'Cargo'], extent: 100);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text(const Labels().more), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
