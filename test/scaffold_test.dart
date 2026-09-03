import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  const theme = Theme();
  final style = theme.widgets.scaffold.resolve();

  /// A scaffold at a chosen window width — the one input every adaptive
  /// decision here turns on.
  Future<void> pump(
    WidgetTester tester,
    Widget scaffold, {
    double width = 1400,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TomeApp(home: scaffold));
    await tester.pumpAndSettle();
  }

  /// The width a sidebar's panel is actually occupying, which is what the
  /// reveal animates and what "open" means on screen.
  double panelWidth(WidgetTester tester, String label) => tester
      .getSize(
        find
            .ancestor(of: find.text(label), matching: find.byType(ClipRect))
            .first,
      )
      .width;

  testWidgets('stacks toolbars above and status bars below the body', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(
        toolbars: [Text('title'), Text('tabs')],
        statusbars: [Text('status')],
        body: Text('body'),
      ),
    );

    double top(String label) => tester.getTopLeft(find.text(label)).dy;
    expect(top('title'), lessThan(top('tabs')));
    expect(top('tabs'), lessThan(top('body')));
    expect(top('body'), lessThan(top('status')));
  });

  testWidgets('sidebars stand beside the body when there is room', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(
        leading: Text('nav'),
        trailing: Text('inspector'),
        body: Text('body'),
      ),
    );

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isDrawer(ScaffoldSide.leading), isFalse);
    expect(scaffold.isDrawer(ScaffoldSide.trailing), isFalse);
    // Beside, not over: three columns, left to right.
    expect(
      tester.getCenter(find.text('nav')).dx,
      lessThan(tester.getCenter(find.text('body')).dx),
    );
    expect(
      tester.getCenter(find.text('body')).dx,
      lessThan(tester.getCenter(find.text('inspector')).dx),
    );
  });

  testWidgets('inline sidebars start open, drawers start shut', (tester) async {
    const page = Scaffold(
      leading: Text('nav'),
      trailing: Text('inspector'),
      body: Text('body'),
    );

    await pump(tester, page);
    var scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isOpen(ScaffoldSide.leading), isTrue);

    // Narrow enough that neither sidebar can leave a minBodyWidth body.
    await pump(tester, page, width: style.minBodyWidth + 100);
    scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isDrawer(ScaffoldSide.leading), isTrue);
    expect(scaffold.isOpen(ScaffoldSide.leading), isFalse);
  });

  testWidgets('trailing becomes a drawer before leading does', (tester) async {
    // Room for one sidebar beside the body, but not for two.
    await pump(
      tester,
      const Scaffold(
        leading: Text('nav'),
        trailing: Text('inspector'),
        body: Text('body'),
      ),
      width: style.minBodyWidth + style.sidebarWidth + 40,
    );

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isDrawer(ScaffoldSide.leading), isFalse);
    expect(scaffold.isDrawer(ScaffoldSide.trailing), isTrue);
  });

  testWidgets('the mode follows the window, not what is showing', (
    tester,
  ) async {
    // One sidebar's worth of room, with both slots filled: closing the
    // leading one must not promote the trailing one out of its drawer.
    await pump(
      tester,
      const Scaffold(
        leading: Text('nav'),
        trailing: Text('inspector'),
        body: Text('body'),
      ),
      width: style.minBodyWidth + style.sidebarWidth + 40,
    );

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.close(ScaffoldSide.leading);
    await tester.pumpAndSettle();
    expect(scaffold.isDrawer(ScaffoldSide.trailing), isTrue);
  });

  testWidgets('the toggle works the sidebar it points at', (tester) async {
    await pump(
      tester,
      const Scaffold(
        toolbars: [ScaffoldSidebarToggle(ScaffoldSide.leading)],
        leading: Text('nav'),
        body: Text('body'),
      ),
    );

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(panelWidth(tester, 'nav'), style.sidebarWidth);

    await tester.tap(find.byType(ScaffoldSidebarToggle));
    await tester.pumpAndSettle();
    expect(scaffold.isOpen(ScaffoldSide.leading), isFalse);
    expect(panelWidth(tester, 'nav'), 0);

    await tester.tap(find.byType(ScaffoldSidebarToggle));
    await tester.pumpAndSettle();
    expect(scaffold.isOpen(ScaffoldSide.leading), isTrue);
    expect(panelWidth(tester, 'nav'), style.sidebarWidth);
  });

  testWidgets('a toggle pointed at an empty slot draws nothing', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(
        toolbars: [ScaffoldSidebarToggle(ScaffoldSide.trailing)],
        leading: Text('nav'),
        body: Text('body'),
      ),
    );

    expect(find.byType(Button), findsNothing);
  });

  testWidgets('the drawer opens over the body and the scrim shuts it', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(
        toolbars: [ScaffoldSidebarToggle(ScaffoldSide.leading)],
        leading: Text('nav'),
        body: Text('body'),
      ),
      width: style.minBodyWidth + 100,
    );

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isDrawer(ScaffoldSide.leading), isTrue);
    // Shut, it's parked off the left edge.
    expect(tester.getTopLeft(find.text('nav')).dx, lessThan(0));

    await tester.tap(find.byType(ScaffoldSidebarToggle));
    await tester.pumpAndSettle();
    expect(scaffold.isOpen(ScaffoldSide.leading), isTrue);
    expect(tester.getTopLeft(find.text('nav')).dx, greaterThanOrEqualTo(0));

    // The scrim covers the body: a tap on the far side lands on it.
    await tester.tapAt(tester.getCenter(find.text('body')));
    await tester.pumpAndSettle();
    expect(scaffold.isOpen(ScaffoldSide.leading), isFalse);
  });

  testWidgets('a shut drawer is clipped to the scaffold, not painted beside '
      'it', (tester) async {
    await pump(
      tester,
      const Scaffold(leading: Text('nav'), body: Text('body')),
      width: style.minBodyWidth + 100,
    );

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isDrawer(ScaffoldSide.leading), isTrue);
    // Parked off the left edge — and it slides there on a paint-time
    // transform, which layout never sees, so something has to clip it or
    // it draws over whatever sits beside the scaffold.
    expect(tester.getTopLeft(find.text('nav')).dx, lessThan(0));
    expect(
      find.ancestor(of: find.text('nav'), matching: find.byType(ClipRect)),
      findsWidgets,
    );
  });

  testWidgets('escape shuts an open drawer', (tester) async {
    await pump(
      tester,
      const Scaffold(
        toolbars: [ScaffoldSidebarToggle(ScaffoldSide.leading)],
        leading: Text('nav'),
        body: Text('body'),
      ),
      width: style.minBodyWidth + 100,
    );

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.open(ScaffoldSide.leading);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(scaffold.isOpen(ScaffoldSide.leading), isFalse);
  });

  testWidgets('each presentation remembers its own answer', (tester) async {
    const page = Scaffold(leading: Text('nav'), body: Text('body'));

    // Shut it while it's a drawer.
    await pump(tester, page, width: style.minBodyWidth + 100);
    var scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.open(ScaffoldSide.leading);
    await tester.pumpAndSettle();
    scaffold.close(ScaffoldSide.leading);
    await tester.pumpAndSettle();

    // Widening restores what was true of the *inline* sidebar, which is
    // that nobody ever closed it.
    await pump(tester, page);
    scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isDrawer(ScaffoldSide.leading), isFalse);
    expect(scaffold.isOpen(ScaffoldSide.leading), isTrue);
  });

  testWidgets('initialLeadingOpen holds an inline sidebar shut', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(
        leading: Text('nav'),
        body: Text('body'),
        initialLeadingOpen: false,
      ),
    );

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isOpen(ScaffoldSide.leading), isFalse);
    // Settled from the first frame rather than animated shut.
    expect(panelWidth(tester, 'nav'), 0);
  });

  testWidgets('ScaffoldStateProvider.of explains itself when there is no '
      'scaffold', (tester) async {
    await tester.pumpWidget(
      TomeApp(
        home: Builder(
          builder: (context) {
            expect(
              () => ScaffoldStateProvider.of(context),
              throwsA(
                isA<FlutterError>().having(
                  (error) => error.message,
                  'message',
                  contains('No Scaffold found'),
                ),
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('a TitleBar dresses its own band: no gutter holds it in', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(
        toolbars: [TitleBar(title: Text('Manifest'), windowControls: true)],
        body: SizedBox(),
      ),
    );

    final scaffold = tester.getRect(find.byType(Scaffold));
    final bar = tester.getRect(find.byType(TitleBar));
    expect(bar.left, scaffold.left);
    expect(bar.right, scaffold.right);

    expect(
      tester.getRect(find.byType(WindowControls)).right,
      scaffold.right,
      reason: 'the window buttons reach the window corner',
    );
  });

  testWidgets('the hairline frames the body, not the chrome', (tester) async {
    await pump(
      tester,
      const Scaffold(
        toolbars: [Text('bar')],
        leading: Text('nav'),
        body: Text('body'),
      ),
    );

    final frame =
        tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(
                        of: find.text('body'),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    final border = frame.border! as BorderDirectional;
    expect(border.top, isNot(BorderSide.none), reason: 'under the toolbar');
    expect(border.start, isNot(BorderSide.none), reason: 'along the sidebar');
    expect(border.bottom, BorderSide.none, reason: 'no status bars');
    expect(border.end, BorderSide.none, reason: 'no trailing sidebar');
  });

  testWidgets('an inline sidebar panel fills its full height', (tester) async {
    await pump(
      tester,
      const Scaffold(leading: Text('nav'), body: Text('body')),
    );

    // Shrink-wrapped, the panel would float vertically centerd; full
    // height, its contents start at the top.
    expect(
      tester.getTopLeft(find.text('nav')).dy,
      lessThan(50),
      reason: 'the nav starts at the top of the window, not mid-air',
    );
    final panel = tester.getRect(
      find.ancestor(of: find.text('nav'), matching: find.byType(Surface)).first,
    );
    expect(panel.height, 800, reason: 'the panel spans the window');
  });

  testWidgets('a bar that is not self-dressed keeps the gutter', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(toolbars: [Text('plain')], body: SizedBox()),
    );

    expect(
      tester.getRect(find.text('plain')).left,
      style.barPadding.resolve(TextDirection.ltr).left,
    );
  });
}
