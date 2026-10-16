import 'package:flutter/gestures.dart';
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
    NavDestination(
      value: 'Crew',
      label: const Text('Crew'),
      icon: _icons.group,
    ),
    const NavSeparator(),
    NavDestination(value: 'Charts', label: const Text('Charts')),
  ];

  Color? fillBehind(WidgetTester tester, String label) {
    final container = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedContainer),
          )
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

  testWidgets('group separators fold with children and keyboard skips them', (
    tester,
  ) async {
    final went = <String>[];
    await pump(
      tester,
      value: null,
      onChanged: went.add,
      entries: [
        const NavGroup<String>(
          label: Text('Chat'),
          entries: [
            NavDestination(value: 'new', label: Text('New Chat...')),
            NavSeparator(),
            NavDestination(value: 'recent', label: Text('Recent chat')),
          ],
        ),
      ],
    );
    expect(find.byType(Divider), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(went, ['new']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(went, ['new', 'recent']);
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.byType(Divider), findsNothing);
    expect(find.text('Recent chat'), findsNothing);
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.byType(Divider), findsOneWidget);
    expect(find.text('Recent chat'), findsOneWidget);
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

  group('a group with a value', () {
    List<NavEntry> cargo() => [
      NavDestination(value: 'Log', label: const Text('Log')),
      NavGroup(
        value: 'Cargo',
        label: const Text('Cargo'),
        destinations: [
          NavDestination(value: 'Manifest', label: const Text('Manifest')),
        ],
      ),
    ];

    Finder chevron() => find.descendant(
      of: find.ancestor(
        of: find.text('Cargo'),
        matching: find.byType(AnimatedContainer),
      ),
      matching: find.byWidgetPredicate((w) => w is GestureDetector),
    );

    testWidgets('is chosen by its row, not folded', (tester) async {
      final chosen = <String>[];
      await pump(tester, entries: cargo(), onChanged: chosen.add);

      await tester.tap(find.text('Cargo'));
      await tester.pumpAndSettle();
      expect(chosen, ['Cargo']);
      expect(find.text('Manifest'), findsOneWidget);
    });

    testWidgets('shows as where you are', (tester) async {
      await pump(tester, entries: cargo(), value: 'Cargo');
      final selected = const Theme().widgets.navList
          .resolve(SemanticSwatch.primary, NavListSize.medium)
          .selected
          .fill;
      expect(fillBehind(tester, 'Cargo'), selected);
      expect(fillBehind(tester, 'Log'), isNot(selected));
    });

    testWidgets('folds from its chevron without being chosen', (tester) async {
      final chosen = <String>[];
      await pump(tester, entries: cargo(), onChanged: chosen.add);

      await tester.tap(chevron());
      await tester.pumpAndSettle();
      expect(find.text('Manifest'), findsNothing);
      expect(chosen, isEmpty);

      await tester.tap(chevron());
      await tester.pumpAndSettle();
      expect(find.text('Manifest'), findsOneWidget);
    });

    testWidgets('folds on a second press inside the double-tap window', (
      tester,
    ) async {
      final chosen = <String>[];
      await pump(tester, entries: cargo(), onChanged: chosen.add);

      await tester.tap(find.text('Cargo'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Cargo'));
      await tester.pumpAndSettle();
      expect(chosen, ['Cargo']);
      expect(find.text('Manifest'), findsNothing);

      // Two presses too far apart are two choices, not a fold. The window
      // is wall-clock time, which the tester's pump doesn't advance.
      await tester.tap(find.text('Cargo'));
      await tester.runAsync(
        () => Future<void>.delayed(
          kDoubleTapTimeout + const Duration(milliseconds: 20),
        ),
      );
      await tester.tap(find.text('Cargo'));
      await tester.pumpAndSettle();
      expect(find.text('Manifest'), findsNothing);
    });

    testWidgets('a group without a value still folds from its row', (
      tester,
    ) async {
      await pump(
        tester,
        entries: [
          NavGroup(
            label: const Text('Cargo'),
            destinations: [
              NavDestination(value: 'Manifest', label: const Text('Manifest')),
            ],
          ),
        ],
      );
      expect(chevron(), findsNothing);
      await tester.tap(find.text('Cargo'));
      await tester.pumpAndSettle();
      expect(find.text('Manifest'), findsNothing);
    });
  });

  testWidgets('a group that starts shut opens when tapped, and shuts again', (
    tester,
  ) async {
    Widget build() => TomeApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 240,
          child: NavList<String>(
            value: 'Log',
            onChanged: (_) {},
            entries: [
              NavDestination(value: 'Log', label: const Text('Log')),
              NavGroup(
                id: 'archived',
                label: const Text('Archived'),
                initiallyOpen: false,
                destinations: [
                  NavDestination(value: 'Old', label: const Text('Old')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(build());

    expect(find.text('Old'), findsNothing);
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsOneWidget);

    // Fresh instances from a parent rebuild keep the reader's fold.
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsOneWidget);

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsNothing);
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

  testWidgets('rows stand a small gap apart, folds included', (tester) async {
    const gap = 4.0;

    Rect rowOf(String label) => tester.getRect(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

    await pump(
      tester,
      entries: [
        NavDestination(value: 'Log', label: const Text('Log')),
        NavGroup<String>(
          label: const Text('Cargo'),
          destinations: const [
            NavDestination(value: 'Manifest', label: Text('Manifest')),
            NavDestination(value: 'Soundings', label: Text('Soundings')),
          ],
        ),
        NavDestination(value: 'Charts', label: const Text('Charts')),
      ],
    );

    // Between two plain rows, between a group and its first destination,
    // and between two of those: the one gap everywhere.
    expect(rowOf('Cargo').top - rowOf('Log').bottom, gap);
    expect(rowOf('Manifest').top - rowOf('Cargo').bottom, gap);
    expect(rowOf('Soundings').top - rowOf('Manifest').bottom, gap);
    expect(rowOf('Charts').top - rowOf('Soundings').bottom, gap);

    // Shut, the fold takes up nothing — including its gap, or the rows
    // either side of it would drift apart.
    await tester.tap(find.text('Cargo'));
    await tester.pumpAndSettle();
    expect(find.text('Manifest'), findsNothing);
    expect(rowOf('Charts').top - rowOf('Cargo').bottom, gap);
  });

  testWidgets('a group folds rather than vanishing', (tester) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: NavList<String>(
            value: 'log',
            onChanged: (_) {},
            entries: [
              const NavDestination(value: 'log', label: Text('Log')),
              NavGroup<String>(
                label: const Text('Cargo'),
                destinations: const [
                  NavDestination(value: 'manifest', label: Text('Manifest')),
                  NavDestination(value: 'soundings', label: Text('Soundings')),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final open = tester.getSize(find.byType(NavList<String>)).height;
    expect(find.text('Manifest'), findsOneWidget);

    await tester.tap(find.text('Cargo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    // Part way: the rows are still there, and the list is shorter than it
    // was but taller than it will be — a fold, not a disappearance.
    final midway = tester.getSize(find.byType(NavList<String>)).height;
    expect(find.text('Manifest'), findsOneWidget, reason: 'still collapsing');
    expect(midway, lessThan(open));

    await tester.pumpAndSettle();
    final shut = tester.getSize(find.byType(NavList<String>)).height;
    expect(shut, lessThan(midway));
    expect(find.text('Manifest'), findsNothing, reason: 'shut and still');
  });

  testWidgets('trailing widgets share a column, whatever they are', (
    tester,
  ) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: SizedBox(
            width: 240,
            child: NavList<String>(
              value: 'manifest',
              onChanged: (_) {},
              entries: [
                NavGroup<String>(
                  label: const Text('Cargo'),
                  destinations: const [
                    NavDestination(
                      value: 'manifest',
                      label: Text('Manifest'),
                      trailing: Text('3'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // The chevron on the group and the count on the row below it are
    // different widths flush to the same edge, which reads as two edges.
    final chevron = tester.getRect(find.byIcon(const Icons().chevronDown));
    final count = tester.getRect(find.text('3'));
    expect(chevron.center.dx, moreOrLessEquals(count.center.dx, epsilon: 1));
  });

  testWidgets('a fold survives the parent rebuilding the entries', (
    tester,
  ) async {
    // Parents rebuild sidebars constantly, constructing fresh NavGroup
    // instances each time. The fold is keyed by the destinations' values,
    // not the instances, so it holds.
    Widget build(int generation) => TomeApp(
      home: NavList<int>(
        value: 0,
        onChanged: (_) {},
        entries: [
          NavDestination(value: 0, label: Text('Home $generation')),
          NavGroup(
            label: const Text('Cargo'),
            destinations: const [
              NavDestination(value: 1, label: Text('Manifest')),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(build(1));
    expect(find.text('Manifest'), findsOneWidget);

    await tester.tap(find.text('Cargo'));
    await tester.pumpAndSettle();
    expect(find.text('Manifest'), findsNothing);

    await tester.pumpWidget(build(2));
    await tester.pumpAndSettle();
    expect(
      find.text('Manifest'),
      findsNothing,
      reason: 'new instances, same fold',
    );
  });

  List<NavEntry> nested({bool open = true}) => [
    NavGroup<String>(
      label: const Text('Chat'),
      initiallyOpen: open,
      entries: [
        const NavDestination(value: 'new', label: Text('New')),
        NavGroup<String>(
          label: const Text('Ada'),
          initiallyOpen: open,
          entries: const [
            NavDestination(value: 'a1', label: Text('Ada one')),
            NavDestination(value: 'a2', label: Text('Ada two')),
          ],
        ),
        NavGroup<String>(
          label: const Text('Bix'),
          initiallyOpen: open,
          entries: const [
            NavHeading(Text('Older')),
            NavDestination(value: 'b1', label: Text('Bix one')),
          ],
        ),
      ],
    ),
  ];

  testWidgets('a nested group sits in again, its heading too', (tester) async {
    await pump(tester, value: null, entries: nested());

    // Measured from the list's own edge.
    double left(String label) =>
        tester.getRect(find.text(label)).left -
        tester.getRect(find.byType(NavList<String>)).left;
    final step = left('Ada') - left('Chat');
    expect(step, greaterThan(0));
    expect(left('Ada one') - left('Ada'), moreOrLessEquals(step));
    expect(left('Bix one') - left('Chat'), moreOrLessEquals(2 * step));
    // Two steps in is at least two indents, whatever the heading's padding.
    expect(left('Older'), greaterThanOrEqualTo(2 * step));
  });

  testWidgets('folding an inner group hides only its own rows', (tester) async {
    await pump(tester, value: null, entries: nested());

    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();
    expect(find.text('Ada one'), findsNothing);
    expect(find.text('Ada two'), findsNothing);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Bix one'), findsOneWidget);

    // The outer fold takes everything with it, the inner groups included.
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Bix'), findsNothing);
    expect(find.text('Bix one'), findsNothing);

    // Reopened, the inner group remembers it was shut.
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Bix one'), findsOneWidget);
    expect(find.text('Ada one'), findsNothing);
  });

  testWidgets('where you are opens every group around it', (tester) async {
    await pump(tester, value: 'a2', entries: nested(open: false));

    expect(find.text('Ada two'), findsOneWidget);
    expect(find.text('Bix one'), findsNothing, reason: 'told to start shut');
    expect(find.text('Bix'), findsOneWidget);
  });

  testWidgets('the arrows walk nested rows in order and fold a nested group', (
    tester,
  ) async {
    final went = <String>[];
    await pump(tester, value: null, onChanged: went.add, entries: nested());

    Future<void> key(LogicalKeyboardKey key, [int times = 1]) async {
      for (var i = 0; i < times; i++) {
        await tester.sendKeyEvent(key);
      }
      await tester.pump();
    }

    // Chat, New, Ada, Ada one, Ada two, Bix, (heading), Bix one.
    await key(LogicalKeyboardKey.tab);
    await key(LogicalKeyboardKey.arrowDown, 3);
    await key(LogicalKeyboardKey.enter);
    expect(went, ['a1']);

    await key(LogicalKeyboardKey.arrowDown, 3);
    await key(LogicalKeyboardKey.enter);
    expect(went, ['a1', 'b1'], reason: 'straight past the heading');

    // Up onto the nested group and fold it with Enter.
    await key(LogicalKeyboardKey.arrowUp);
    await key(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Bix one'), findsNothing);
    expect(find.text('Ada one'), findsOneWidget);

    // The shut group's rows are out of the walk: the last row is Bix
    // itself, and Enter there opens it again.
    await key(LogicalKeyboardKey.end);
    await key(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Bix one'), findsOneWidget);
    expect(went, ['a1', 'b1']);

    // Open again, the walk ends on its row.
    await key(LogicalKeyboardKey.end);
    await key(LogicalKeyboardKey.enter);
    expect(went, ['a1', 'b1', 'b1']);
  });

  testWidgets('a group with an id keeps its fold whatever it holds', (
    tester,
  ) async {
    // The destinations inside change from one build to the next, as a
    // chat list does; the id is the name the fold goes by.
    Widget build(int generation) => TomeApp(
      home: NavList<String>(
        value: 'home',
        onChanged: (_) {},
        entries: [
          const NavDestination(value: 'home', label: Text('Home')),
          NavGroup<String>(
            id: 'agent:ada',
            label: const Text('Ada'),
            entries: [
              NavDestination(
                value: 'chat $generation',
                label: Text('Chat $generation'),
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(build(1));
    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();
    expect(find.text('Chat 1'), findsNothing);

    await tester.pumpWidget(build(2));
    await tester.pumpAndSettle();
    expect(find.text('Chat 2'), findsNothing, reason: 'same id, same fold');
  });

  testWidgets('a leading widget takes the icon’s place', (tester) async {
    await pump(
      tester,
      entries: [
        NavDestination(
          value: 'Log',
          label: const Text('Log'),
          icon: _icons.file,
        ),
        NavGroup<String>(
          label: const Text('Ada'),
          icon: _icons.group,
          leading: const SizedBox(key: Key('group avatar')),
          entries: [
            NavDestination(
              value: 'Crew',
              label: const Text('Crew'),
              icon: _icons.group,
              leading: const SizedBox(key: Key('avatar')),
            ),
          ],
        ),
      ],
    );

    expect(find.byIcon(_icons.group), findsNothing);
    final icon = tester.getRect(find.byIcon(_icons.file));
    final group = tester.getRect(find.byKey(const Key('group avatar')));
    final avatar = tester.getRect(find.byKey(const Key('avatar')));
    expect(group.size, icon.size);
    expect(avatar.size, icon.size);
    expect(group.left, icon.left);
    expect(
      tester.getRect(find.text('Ada')).left - group.right,
      moreOrLessEquals(tester.getRect(find.text('Log')).left - icon.right),
    );
  });

  group('a destination’s menu', () {
    List<NavEntry> withMenu(List<String> log) => [
      NavDestination(value: 'Log', label: const Text('Log')),
      NavDestination(
        value: 'Crew',
        label: const Text('Crew'),
        menu: [
          MenuItem(
            label: const Text('Archive'),
            onPressed: () => log.add('archived'),
          ),
          MenuItem(
            label: const Text('Delete'),
            onPressed: () => log.add('deleted'),
          ),
        ],
      ),
    ];

    Rect panel(WidgetTester tester) =>
        tester.getRect(find.byType(SingleChildScrollView));

    testWidgets('opens where a right-click asked', (tester) async {
      final went = <String>[];
      await pump(tester, entries: withMenu([]), onChanged: went.add);

      final at = tester.getCenter(find.text('Crew'));
      final mouse = await tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await mouse.up();
      await tester.pumpAndSettle();

      expect(find.text('Archive'), findsOneWidget);
      expect(panel(tester).left, greaterThanOrEqualTo(at.dx));
      expect(panel(tester).top, greaterThan(at.dy));
      expect(went, isEmpty);
    });

    testWidgets('opens on a long press, without choosing the row', (
      tester,
    ) async {
      final went = <String>[];
      await pump(tester, entries: withMenu([]), onChanged: went.add);

      await tester.longPress(find.text('Crew'));
      await tester.pumpAndSettle();

      expect(find.text('Archive'), findsOneWidget);
      expect(went, isEmpty);
    });

    testWidgets('a plain tap still chooses the row', (tester) async {
      final went = <String>[];
      await pump(tester, entries: withMenu([]), onChanged: went.add);

      await tester.tap(find.text('Crew'));
      await tester.pumpAndSettle();

      expect(went, ['Crew']);
      expect(find.text('Archive'), findsNothing);
    });

    testWidgets('choosing an item runs it, closes, and leaves the row be', (
      tester,
    ) async {
      final went = <String>[];
      final log = <String>[];
      await pump(tester, entries: withMenu(log), onChanged: went.add);

      await tester.longPress(find.text('Crew'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(log, ['deleted']);
      expect(went, isEmpty);
      expect(find.text('Delete'), findsNothing);
    });

    Future<void> pumpList(
      WidgetTester tester, {
      required List<NavEntry> entries,
      ValueChanged<String>? onChanged,
    }) => tester.pumpWidget(
      TomeApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 240,
            child: NavList<String>(
              value: 'Log',
              onChanged: onChanged,
              entries: entries,
            ),
          ),
        ),
      ),
    );

    /// Both ways of asking for the menu: a right-click and a long press.
    Future<void> askEveryWay(WidgetTester tester, String label) async {
      final mouse = await tester.startGesture(
        tester.getCenter(find.text(label)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await mouse.up();
      await tester.pumpAndSettle();
      await tester.longPress(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets('a disabled list offers no menu, and shuts one open', (
      tester,
    ) async {
      final log = <String>[];
      await pumpList(tester, entries: withMenu(log), onChanged: (_) {});
      await tester.longPress(find.text('Crew'));
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);

      // Disabling the list mid-flight — as sending a message does — shuts
      // the menu, and nothing asks it open again.
      await pumpList(tester, entries: withMenu(log));
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsNothing);

      await askEveryWay(tester, 'Crew');
      expect(find.text('Archive'), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('a disabled destination offers none either', (tester) async {
      final went = <String>[];
      final log = <String>[];
      await pump(
        tester,
        onChanged: went.add,
        entries: [
          NavDestination(
            value: 'Crew',
            label: const Text('Crew'),
            enabled: false,
            menu: [
              MenuItem(
                label: const Text('Archive'),
                onPressed: () => log.add('archived'),
              ),
            ],
          ),
        ],
      );

      await askEveryWay(tester, 'Crew');
      expect(find.text('Archive'), findsNothing);
      expect(log, isEmpty);
      expect(went, isEmpty);
    });
  });

  group('a flush group', () {
    List<NavEntry> sections({required bool indent}) => [
      NavGroup<String>(
        label: const Text('Chat'),
        indent: indent,
        entries: [
          const NavDestination(value: 'new', label: Text('New')),
          const NavHeading(Text('Older')),
          NavGroup<String>(
            label: const Text('Ada'),
            entries: const [
              NavDestination(value: 'a1', label: Text('Ada one')),
            ],
          ),
        ],
      ),
    ];

    double left(WidgetTester tester, String label) =>
        tester.getRect(find.text(label)).left -
        tester.getRect(find.byType(NavList<String>)).left;

    final step = const Theme().widgets.navList.resolve().indent;

    testWidgets('keeps its contents level with its own row', (tester) async {
      await pump(tester, value: null, entries: sections(indent: false));

      expect(left(tester, 'New'), moreOrLessEquals(left(tester, 'Chat')));
      expect(left(tester, 'Ada'), moreOrLessEquals(left(tester, 'Chat')));
      // A group inside still steps its own contents in, by one step.
      expect(
        left(tester, 'Ada one') - left(tester, 'Ada'),
        moreOrLessEquals(step),
      );
    });

    testWidgets('an indenting group steps its contents in by one indent', (
      tester,
    ) async {
      await pump(tester, value: null, entries: sections(indent: true));

      expect(
        left(tester, 'New') - left(tester, 'Chat'),
        moreOrLessEquals(step),
      );
      expect(
        left(tester, 'Ada one') - left(tester, 'Chat'),
        moreOrLessEquals(2 * step),
      );
    });

    testWidgets('changes only where rows sit across, not down', (tester) async {
      const labels = ['Chat', 'New', 'Older', 'Ada', 'Ada one'];
      List<double> tops() => [
        for (final label in labels) tester.getRect(find.text(label)).top,
      ];

      await pump(tester, value: null, entries: sections(indent: true));
      final stepped = tops();
      await pump(tester, value: null, entries: sections(indent: false));
      expect(tops(), stepped);

      // It folds the same, and the arrows walk the same rows.
      final went = <String>[];
      await pump(
        tester,
        value: null,
        onChanged: went.add,
        entries: sections(indent: false),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(went, ['a1']);

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsNothing);
      expect(find.text('Ada one'), findsNothing);
    });
  });
}
