import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

const anchorKey = Key('anchor');
const panelKey = Key('panel');

void main() {
  /// The panel's own rectangle — the floating Surface, padding and all.
  Rect panelRect(WidgetTester tester) => tester.getRect(find.byType(Surface));
  Rect anchorRect(WidgetTester tester) => tester.getRect(find.byKey(anchorKey));

  /// A popover anchored to a button placed at [where] in a 800×600 page.
  Future<void> pumpAt(
    WidgetTester tester, {
    required bool open,
    Alignment where = Alignment.center,
    PopoverSide side = PopoverSide.bottom,
    PopoverAlign align = PopoverAlign.center,
    VoidCallback? onDismiss,
    PopoverBarrier barrier = PopoverBarrier.blocking,
  }) => tester.pumpWidget(
    TomeApp(
      home: Align(
        alignment: where,
        child: Popover(
          open: open,
          side: side,
          align: align,
          barrier: barrier,
          onDismiss: onDismiss,
          anchor: const SizedBox(key: anchorKey, width: 100, height: 40),
          content: (_, _) =>
              const SizedBox(key: panelKey, width: 120, height: 80),
        ),
      ),
    ),
  );

  testWidgets('shows and hides with open', (tester) async {
    await pumpAt(tester, open: false);
    await tester.pumpAndSettle();
    expect(find.byKey(panelKey), findsNothing);

    await pumpAt(tester, open: true);
    await tester.pumpAndSettle();
    expect(find.byKey(panelKey), findsOneWidget);

    await pumpAt(tester, open: false);
    await tester.pumpAndSettle();
    expect(find.byKey(panelKey), findsNothing);
  });

  testWidgets('sits on the wanted side, gap and all', (tester) async {
    await pumpAt(tester, open: true);
    await tester.pumpAndSettle();

    final style = const Theme().widgets.popover.resolve();
    final anchor = anchorRect(tester);
    final panel = panelRect(tester);
    expect(panel.top, anchor.bottom + style.gap);
    // Centred on the anchor.
    expect(panel.center.dx, closeTo(anchor.center.dx, 0.01));
  });

  testWidgets('flips to the other side when there is no room', (tester) async {
    // Anchored at the bottom edge: a bottom popover would fall off.
    await pumpAt(tester, open: true, where: Alignment.bottomCenter);
    await tester.pumpAndSettle();

    final style = const Theme().widgets.popover.resolve();
    final anchor = anchorRect(tester);
    final panel = panelRect(tester);
    expect(panel.bottom, anchor.top - style.gap, reason: 'flipped to top');
  });

  testWidgets('slides along the edge to stay on screen', (tester) async {
    await pumpAt(
      tester,
      open: true,
      where: Alignment.centerLeft,
      align: PopoverAlign.end,
    );
    await tester.pumpAndSettle();

    final style = const Theme().widgets.popover.resolve();
    final panel = panelRect(tester);
    // End-aligned on a left-edge anchor would hang off; it slid back in.
    expect(panel.left, greaterThanOrEqualTo(style.margin));
  });

  testWidgets('left and right sides place beside the anchor', (tester) async {
    final style = const Theme().widgets.popover.resolve();

    await pumpAt(tester, open: true, side: PopoverSide.right);
    await tester.pumpAndSettle();
    var anchor = anchorRect(tester);
    var panel = panelRect(tester);
    expect(panel.left, anchor.right + style.gap);

    await pumpAt(tester, open: true, side: PopoverSide.left);
    await tester.pumpAndSettle();
    anchor = anchorRect(tester);
    panel = panelRect(tester);
    expect(panel.right, anchor.left - style.gap);
  });

  testWidgets('a tap outside asks to dismiss', (tester) async {
    var dismissed = 0;
    await pumpAt(tester, open: true, onDismiss: () => dismissed++);
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    expect(dismissed, 1);

    // Asking is not closing — the caller still owns `open`.
    await tester.pumpAndSettle();
    expect(find.byKey(panelKey), findsOneWidget);
  });

  testWidgets('Escape asks to dismiss', (tester) async {
    var dismissed = 0;
    await pumpAt(tester, open: true, onDismiss: () => dismissed++);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(dismissed, 1);
  });

  testWidgets('without a barrier the page underneath stays live', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      TomeApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
              ),
            ),
            Center(
              child: Popover(
                open: true,
                barrier: PopoverBarrier.none,
                anchor: const SizedBox(width: 100, height: 40),
                content: (_, _) =>
                    const SizedBox(key: panelKey, width: 80, height: 40),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(panelKey), findsOneWidget);

    // The panel doesn't swallow the pointer.
    await tester.tapAt(tester.getCenter(find.byKey(panelKey)));
    expect(taps, 1);
  });

  testWidgets('the panel dresses itself — an overlay inherits nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: Popover(
            open: true,
            anchor: const SizedBox(key: anchorKey, width: 100, height: 40),
            content: (_, _) => const Text('words'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const theme = Theme();
    final style = DefaultTextStyle.of(tester.element(find.text('words'))).style;
    // Not the framework's red-on-yellow monospace fallback.
    expect(style.fontSize, theme.typography.body.fontSize);
    expect(style.fontFamily, isNot('monospace'));
    expect(style.decoration ?? TextDecoration.none, TextDecoration.none);
    expect(style.color, theme.widgets.popover.resolve().surface.foreground);
  });

  testWidgets('content that handles its own keys keeps them', (tester) async {
    var arrows = 0;
    var dismissed = 0;
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: Popover(
            open: true,
            takeFocus: false,
            onDismiss: () => dismissed++,
            anchor: const SizedBox(key: anchorKey, width: 100, height: 40),
            content: (_, _) => CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    arrows++,
              },
              child: const Focus(
                autofocus: true,
                child: SizedBox(key: panelKey, width: 80, height: 40),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(arrows, 1, reason: 'the content saw its own key');

    // And what it doesn't handle still reaches the popover.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(dismissed, 1);
  });

  testWidgets('the panel leaves the tree when its anchor does', (tester) async {
    await pumpAt(tester, open: true);
    await tester.pumpAndSettle();
    expect(find.byKey(panelKey), findsOneWidget);

    await tester.pumpWidget(const TomeApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(find.byKey(panelKey), findsNothing);
  });

  testWidgets('inside a nested navigator, the panel still sits on its '
      'anchor', (tester) async {
    // A routing shell brings a navigator — and so an overlay — that covers
    // only the body. Placed in that overlay, the panel would land shifted
    // by the shell's chrome and be clipped to the body besides.
    await tester.pumpWidget(
      TomeApp(
        home: Column(
          children: [
            const SizedBox(height: 120),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 200),
                  Expanded(
                    child: Navigator(
                      onGenerateRoute: (_) => PageRouteBuilder(
                        pageBuilder: (_, _, _) => Align(
                          alignment: Alignment.topLeft,
                          child: Popover(
                            open: true,
                            anchor: const SizedBox(
                              key: anchorKey,
                              width: 100,
                              height: 40,
                            ),
                            content: (_, _) => const SizedBox(
                              key: panelKey,
                              width: 120,
                              height: 80,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final style = const Theme().widgets.popover.resolve();
    final anchor = anchorRect(tester);
    final panel = panelRect(tester);
    expect(anchor.topLeft, const Offset(200, 120), reason: 'inside the shell');
    expect(panel.top, anchor.bottom + style.gap);
    expect(panel.center.dx, closeTo(anchor.center.dx, 0.01));
  });
}
