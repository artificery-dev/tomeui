import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  /// A menu the test drives: the anchor toggles it, and choosing closes it
  /// the way an app would.
  Widget host(List<MenuEntry> entries) => _MenuHost(entries: entries);

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byType(Button));
    await tester.pumpAndSettle();
  }

  /// The row in the panel, not the anchor's own words.
  Finder row(String label) => find.descendant(
    of: find.byType(SingleChildScrollView),
    matching: find.text(label),
  );

  testWidgets('opens on its anchor and closes on choosing', (tester) async {
    var duplicated = 0;
    await tester.pumpWidget(
      TomeApp(
        home: host([
          MenuItem(
            label: const Text('Duplicate'),
            onPressed: () => duplicated++,
          ),
          MenuItem(label: const Text('Archive'), onPressed: () {}),
        ]),
      ),
    );
    expect(row('Duplicate'), findsNothing);

    await open(tester);
    expect(row('Duplicate'), findsOneWidget);
    expect(row('Archive'), findsOneWidget);

    await tester.tap(row('Duplicate'));
    await tester.pumpAndSettle();
    expect(duplicated, 1);
    expect(row('Duplicate'), findsNothing, reason: 'closed behind the choice');
  });

  testWidgets('it asks to close before it acts', (tester) async {
    // An action that opens a dialog of its own would otherwise race the
    // menu's dismissal.
    final log = <String>[];
    await tester.pumpWidget(
      TomeApp(
        home: _MenuHost(
          onDismissed: () => log.add('closed'),
          entries: [
            MenuItem(
              label: const Text('Act'),
              onPressed: () => log.add('acted'),
            ),
          ],
        ),
      ),
    );

    await open(tester);
    await tester.tap(row('Act'));
    await tester.pumpAndSettle();
    expect(log, ['closed', 'acted']);
  });

  testWidgets('keyboard: arrows walk, Enter takes, Escape leaves', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      TomeApp(
        home: host([
          MenuItem(label: const Text('One'), onPressed: () => chosen = 'One'),
          MenuItem(label: const Text('Two'), onPressed: () => chosen = 'Two'),
          MenuItem(
            label: const Text('Three'),
            onPressed: () => chosen = 'Three',
          ),
        ]),
      ),
    );
    await open(tester);

    // The highlight starts on the first row; step twice to the third.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 'Three');

    chosen = null;
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(row('One'), findsNothing);
    expect(chosen, isNull);
  });

  testWidgets('the walk wraps, and Home and End jump', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      TomeApp(
        home: host([
          MenuItem(label: const Text('One'), onPressed: () => chosen = 'One'),
          MenuItem(label: const Text('Two'), onPressed: () => chosen = 'Two'),
        ]),
      ),
    );

    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 'Two', reason: 'up from the first row lands on the last');

    chosen = null;
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 'One');
  });

  testWidgets('separators and sections are shown but never walked to', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      TomeApp(
        home: host([
          const MenuSection(Text('Manifest')),
          MenuItem(label: const Text('One'), onPressed: () => chosen = 'One'),
          const MenuSeparator(),
          MenuItem(label: const Text('Two'), onPressed: () => chosen = 'Two'),
        ]),
      ),
    );
    await open(tester);
    expect(row('Manifest'), findsOneWidget);

    // Two steps from the first item would land on the section label if the
    // walk counted them; instead it wraps straight back around.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 'One');
  });

  testWidgets('a disabled item is dimmed, skipped, and unchoosable', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      TomeApp(
        home: host([
          MenuItem(label: const Text('One'), onPressed: () => chosen = 'One'),
          const MenuItem(label: Text('Two'), onPressed: null),
          MenuItem(
            label: const Text('Three'),
            onPressed: () => chosen = 'Three',
          ),
        ]),
      ),
    );
    await open(tester);

    await tester.tap(row('Two'));
    await tester.pumpAndSettle();
    expect(chosen, isNull, reason: 'tapping a disabled row does nothing');
    expect(row('Two'), findsOneWidget, reason: 'and leaves the menu open');

    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: row('Two'), matching: find.byType(Opacity)).first,
          )
          .opacity,
      const Opacities().disabled,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 'Three', reason: 'the keyboard steps over it');
  });

  testWidgets('an item that means something wears it', (tester) async {
    await tester.pumpWidget(
      TomeApp(
        home: host([
          MenuItem(
            label: const Text('Delete'),
            swatch: SemanticSwatch.error,
            onPressed: () {},
          ),
          MenuItem(label: const Text('Rename'), onPressed: () {}),
        ]),
      ),
    );
    await open(tester);

    TextStyle styleOf(String label) => tester
        .widget<RichText>(
          find.descendant(of: row(label), matching: find.byType(RichText)),
        )
        .text
        .style!;

    expect(styleOf('Delete').color, const Palette().error[300]);
    expect(styleOf('Rename').color, isNot(const Palette().error[300]));
  });

  testWidgets('the highlight follows the pointer', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    String? chosen;
    await tester.pumpWidget(
      TomeApp(
        home: host([
          MenuItem(label: const Text('One'), onPressed: () => chosen = 'One'),
          MenuItem(label: const Text('Two'), onPressed: () => chosen = 'Two'),
        ]),
      ),
    );
    await open(tester);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(row('Two')));
    await tester.pumpAndSettle();

    // Whatever the pointer is over is what Enter takes.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 'Two');
  });

  group('ContextMenu', () {
    testWidgets('opens where the pointer asked, on a right-click', (
      tester,
    ) async {
      await tester.pumpWidget(
        TomeApp(
          home: Center(
            child: ContextMenu(
              entries: [
                MenuItem(label: const Text('Rename'), onPressed: () {}),
              ],
              child: const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );
      expect(find.text('Rename'), findsNothing);

      final at = tester.getCenter(find.byType(ContextMenu));
      final mouse = await tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await mouse.up();
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);

      // Hung off the point, not off the widget: the panel starts at the
      // pointer rather than at the child's own left edge, which is 100
      // pixels further left.
      final panel = tester.getRect(find.byType(SingleChildScrollView));
      final child = tester.getRect(find.byType(ContextMenu));
      expect(panel.left, greaterThanOrEqualTo(at.dx));
      expect(panel.left, greaterThan(child.left));
      expect(panel.top, greaterThan(at.dy));
      // And it hugs its rows rather than filling the screen.
      expect(panel.width, lessThan(child.width * 2));
    });

    testWidgets('a long press opens it too, for touch', (tester) async {
      await tester.pumpWidget(
        TomeApp(
          home: Center(
            child: ContextMenu(
              entries: [
                MenuItem(label: const Text('Rename'), onPressed: () {}),
              ],
              child: const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(ContextMenu));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets('a tap outside dismisses it', (tester) async {
      await tester.pumpWidget(
        TomeApp(
          home: Center(
            child: ContextMenu(
              entries: [
                MenuItem(label: const Text('Rename'), onPressed: () {}),
              ],
              child: const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(ContextMenu));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
    });
  });
}

/// A menu wired the way an app wires one: the anchor toggles it, dismissal
/// closes it.
class _MenuHost extends StatefulWidget {
  const _MenuHost({required this.entries, this.onDismissed});

  final List<MenuEntry> entries;

  /// Told the moment the menu asks to close, so a test can watch the order
  /// things happen in.
  final VoidCallback? onDismissed;

  @override
  State<_MenuHost> createState() => _MenuHostState();
}

class _MenuHostState extends State<_MenuHost> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Center(
    child: Menu(
      open: _open,
      entries: widget.entries,
      onDismiss: () {
        widget.onDismissed?.call();
        setState(() => _open = false);
      },
      anchor: Button(
        onPressed: () => setState(() => _open = !_open),
        center: const Text('Actions'),
      ),
    ),
  );
}
