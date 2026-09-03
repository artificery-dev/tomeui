import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

/// A theme installed part-way down the tree, the way a catalog previewing
/// a palette does — and the way any section with a palette of its own would.
const _inner = Theme(
  palette: Palette(brightness: Brightness.dark, primary: Swatch.orange),
);

void main() {
  /// Pumps an app themed one way with a subtree themed another, and hands
  /// back a context from inside the subtree.
  Future<BuildContext> pumpNested(WidgetTester tester) async {
    late BuildContext inner;
    await tester.pumpWidget(
      TomeApp(
        home: ThemeProvider(
          theme: _inner,
          child: Builder(
            builder: (context) {
              inner = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return inner;
  }

  /// What the words inside [of] are actually wearing.
  TextStyle styleInside(WidgetTester tester, Finder of, String text) =>
      DefaultTextStyle.of(
        tester.element(find.descendant(of: of, matching: find.text(text))),
      ).style;

  testWidgets('a dialog wears the theme it was asked for, not the one at the '
      'navigator it was pushed onto', (tester) async {
    final context = await pumpNested(tester);

    // Nothing pops these, so nothing awaits them.
    unawaited(
      showDialog<void>(
        context,
        builder: (context) => const Dialog(title: Text('Sign?')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      ThemeProvider.of(tester.element(find.byType(Dialog))),
      _inner,
      reason: 'the theme travelled with the route',
    );
    expect(
      styleInside(tester, find.byType(Dialog), 'Sign?').color,
      isNotNull,
      reason: 'and so the words have a color at all',
    );
  });

  testWidgets('a sheet does too, and its words with it', (tester) async {
    final context = await pumpNested(tester);

    unawaited(
      showSheet<void>(
        context,
        builder: (context) =>
            const Sheet(title: Text('Sort by'), child: Text('Name')),
      ),
    );
    await tester.pumpAndSettle();

    expect(ThemeProvider.of(tester.element(find.byType(Sheet))), _inner);

    // The sheet's own surface speaks its foreground to everything inside,
    // and that foreground is the nested palette's.
    expect(
      styleInside(tester, find.byType(Sheet), 'Name').color,
      _inner.widgets.sheet.resolve().surface.foreground,
    );
  });

  testWidgets('so does the command palette', (tester) async {
    final context = await pumpNested(tester);

    unawaited(
      showCommandPalette(
        context,
        commands: [Command(name: 'Save', onInvoke: () {})],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      ThemeProvider.of(tester.element(find.byType(CommandPalette))),
      _inner,
    );
    expect(
      styleInside(tester, find.byType(CommandPalette), 'Save').color,
      isNotNull,
    );
  });

  testWidgets('and a popover, which knew it first', (tester) async {
    await tester.pumpWidget(
      TomeApp(
        home: ThemeProvider(
          theme: _inner,
          child: Center(
            child: Popover(
              open: true,
              anchor: const Text('anchor'),
              content: (context, _) => const Text('panel'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(ThemeProvider.of(tester.element(find.text('panel'))), _inner);
  });
}
