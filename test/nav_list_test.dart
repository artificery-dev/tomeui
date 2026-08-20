import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

const _icons = Icons();

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<NavEntry> entries,
    String? value = 'Log',
    ValueChanged<String>? onChanged,
  }) => tester.pumpWidget(
    TomeApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 240,
          child: NavList<String>(
            value: value,
            onChanged: onChanged ?? (_) {},
            entries: entries,
          ),
        ),
      ),
    ),
  );

  List<NavEntry> flat() => [
    const NavHeading(Text('Ship')),
    NavDestination(value: 'Log', label: const Text('Log'), icon: _icons.file),
    NavDestination(value: 'Crew', label: const Text('Crew'), icon: _icons.group),
    const NavSeparator(),
    NavDestination(value: 'Charts', label: const Text('Charts')),
  ];

  Color? fillBehind(WidgetTester tester, String label) {
    final container = tester.widget<AnimatedContainer>(
      find
          .ancestor(of: find.text(label), matching: find.byType(AnimatedContainer))
          .first,
    );
    return (container.decoration as BoxDecoration?)?.color;
  }

  testWidgets('headings, destinations, and rules all read in order', (
    tester,
  ) async {
    await pump(tester, entries: flat());

    expect(find.text('Ship'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(
      tester.getRect(find.text('Crew')).top,
      greaterThan(tester.getRect(find.text('Log')).top),
    );
  });

  testWidgets('the row you are on wears the swatch', (tester) async {
    await pump(tester, entries: flat(), value: 'Crew');

    final style = const Theme().widgets.navList.resolve();
    expect(fillBehind(tester, 'Crew'), style.selected.fill);
    // The rest are bare: the resting wash is there but transparent.
    expect(fillBehind(tester, 'Log')?.a ?? 0, 0);
  });

  testWidgets('tapping a destination reports it; the one you are on does '
      'not', (tester) async {
    final went = <String>[];
    await pump(tester, entries: flat(), value: 'Log', onChanged: went.add);

    await tester.tap(find.text('Crew'));
    await tester.pump();
    expect(went, ['Crew']);

    await tester.tap(find.text('Log'));
    await tester.pump();
    expect(went, ['Crew']);
  });

  testWidgets('a group folds its destinations away and back', (tester) async {
    await pump(
      tester,
      value: 'Log',
      entries: [
        NavDestination(value: 'Log', label: const Text('Log')),
        NavGroup(
          label: const Text('Cargo'),
          destinations: [
            NavDestination(value: 'Manifest', label: const Text('Manifest')),
          ],
        ),
      ],
    );

    expect(find.text('Manifest'), findsOneWidget);
    await tester.tap(find.text('Cargo'));
    await tester.pumpAndSettle();
    expect(find.text('Manifest'), findsNothing);
    await tester.tap(find.text('Cargo'));
    await tester.pumpAndSettle();
    expect(find.text('Manifest'), findsOneWidget);
  });

  testWidgets('a group holding where you are opens whatever it was told', (
    tester,
  ) async {
    await pump(
      tester,
      value: 'Manifest',
      entries: [
        NavGroup(
          label: const Text('Cargo'),
          initiallyOpen: false,
          destinations: [
            NavDestination(value: 'Manifest', label: const Text('Manifest')),
          ],
        ),
      ],
    );

    expect(find.text('Manifest'), findsOneWidget);
  });

  testWidgets('a group’s destinations sit in from the group', (tester) async {
    await pump(
      tester,
      value: 'Log',
      entries: [
        NavGroup(
          label: const Text('Cargo'),
          destinations: [
            NavDestination(value: 'Manifest', label: const Text('Manifest')),
          ],
        ),
      ],
    );

    expect(
      tester.getRect(find.text('Manifest')).left,
      greaterThan(tester.getRect(find.text('Cargo')).left),
    );
  });

  testWidgets('the arrows walk it, stepping over headings and rules', (
    tester,
  ) async {
    final went = <String>[];
    await pump(tester, entries: flat(), value: 'Log', onChanged: went.add);

    // Tab into the list, then walk: the heading and the rule are not rows
    // the keyboard can stop on.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(went, ['Crew']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(went, ['Crew', 'Charts'], reason: 'straight past the rule');
  });

  testWidgets('a disabled destination cannot be chosen', (tester) async {
    final went = <String>[];
    await pump(
      tester,
      value: 'Log',
      onChanged: went.add,
      entries: [
        NavDestination(value: 'Log', label: const Text('Log')),
        NavDestination(
          value: 'Crew',
          label: const Text('Crew'),
          enabled: false,
        ),
      ],
    );

    await tester.tap(find.text('Crew'));
    await tester.pump();
    expect(went, isEmpty);
  });

  testWidgets('a null onChanged disables the list', (tester) async {
    await tester.pumpWidget(
      TomeApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 240,
            child: NavList<String>(
              value: 'Log',
              onChanged: null,
              entries: flat(),
            ),
          ),
        ),
      ),
    );

    final dimmed = tester.widget<AnimatedOpacity>(
      find
          .descendant(
            of: find.byType(NavList<String>),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(dimmed.opacity, const Theme().opacities.disabled);
  });

  testWidgets('a trailing widget rides along', (tester) async {
    await pump(
      tester,
      value: 'Log',
      entries: [
        NavDestination(
          value: 'Log',
          label: const Text('Log'),
          trailing: const Text('12'),
        ),
      ],
    );

    expect(find.text('12'), findsOneWidget);
    expect(
      tester.getRect(find.text('12')).left,
      greaterThan(tester.getRect(find.text('Log')).left),
    );
  });
}
