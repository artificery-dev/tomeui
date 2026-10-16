import 'package:flutter/gestures.dart';
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

  /// The grab strip on a side's inner edge: the one pointer target that
  /// asks for a column-resize cursor.
  Finder handle(ScaffoldSide side) {
    final handles = find.byWidgetPredicate(
      (w) => w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn,
    );
    return side == ScaffoldSide.leading ? handles.first : handles.last;
  }

  Future<void> drag(WidgetTester tester, Finder target, double dx) async {
    await tester.drag(target, Offset(dx, 0), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
  }

  testWidgets('dragging a resizable sidebar\'s inner edge changes its width '
      'and reports it', (tester) async {
    final resized = <(ScaffoldSide, double)>[];
    await pump(
      tester,
      Scaffold(
        resizable: true,
        leading: const Text('nav'),
        trailing: const Text('inspector'),
        body: const Text('body'),
        onSidebarResized: (side, width) => resized.add((side, width)),
      ),
    );
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.width(ScaffoldSide.leading), style.sidebarWidth);

    // Leading grows to the right; trailing grows to the left.
    await drag(tester, handle(ScaffoldSide.leading), 40);
    expect(scaffold.width(ScaffoldSide.leading), style.sidebarWidth + 40);
    expect(panelWidth(tester, 'nav'), style.sidebarWidth + 40);

    await drag(tester, handle(ScaffoldSide.trailing), -30);
    expect(scaffold.width(ScaffoldSide.trailing), style.sidebarWidth + 30);
    expect(panelWidth(tester, 'inspector'), style.sidebarWidth + 30);

    expect(resized.last, (ScaffoldSide.trailing, style.sidebarWidth + 30));
    expect(resized.first.$1, ScaffoldSide.leading);
  });

  testWidgets('the grab strip lights while hovered and while dragging', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(resizable: true, leading: Text('nav'), body: Text('body')),
    );
    final strip = handle(ScaffoldSide.leading);
    double lit() => tester
        .widget<AnimatedOpacity>(
          find.descendant(of: strip, matching: find.byType(AnimatedOpacity)),
        )
        .opacity;
    expect(lit(), 0);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(strip));
    await tester.pumpAndSettle();
    expect(lit(), 1);

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(lit(), 0);

    // A drag that started on the strip keeps it lit even once the pointer
    // has run ahead of the (still catching up) edge.
    await mouse.down(tester.getCenter(strip));
    await mouse.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(lit(), 1);
    await mouse.up();
    await tester.pumpAndSettle();
    // Still hovered: the strip moved with the edge, under the pointer.
    expect(lit(), 1);
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(lit(), 0);
  });

  testWidgets('a drag stops at the style\'s bounds', (tester) async {
    await pump(
      tester,
      const Scaffold(resizable: true, leading: Text('nav'), body: Text('body')),
      width: 2400,
    );
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));

    await drag(tester, handle(ScaffoldSide.leading), -1000);
    expect(scaffold.width(ScaffoldSide.leading), style.sidebarMinWidth);

    await drag(tester, handle(ScaffoldSide.leading), 2000);
    expect(scaffold.width(ScaffoldSide.leading), style.sidebarMaxWidth);
  });

  testWidgets('a drag never takes the body below its minimum width', (
    tester,
  ) async {
    // Room for both sidebars at their default plus a little, not for a
    // sidebar at its maximum.
    final width = style.minBodyWidth + style.sidebarWidth * 2 + 20;
    await pump(
      tester,
      const Scaffold(
        resizable: true,
        leading: Text('nav'),
        trailing: Text('inspector'),
        body: Text('body'),
      ),
      width: width,
    );
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));

    await drag(tester, handle(ScaffoldSide.leading), 500);
    expect(scaffold.width(ScaffoldSide.leading), style.sidebarWidth + 20);
    expect(
      tester.getSize(find.text('body').first).width,
      greaterThanOrEqualTo(style.minBodyWidth - 2),
    );
    // Still inline: the drag could not push its own side into a drawer.
    expect(scaffold.isDrawer(ScaffoldSide.leading), isFalse);
    expect(scaffold.isDrawer(ScaffoldSide.trailing), isFalse);
  });

  testWidgets('initial widths are honoured and a non-resizable scaffold has '
      'no handle', (tester) async {
    await pump(
      tester,
      const Scaffold(
        leading: Text('nav'),
        body: Text('body'),
        initialLeadingWidth: 200,
      ),
    );
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.width(ScaffoldSide.leading), 200);
    expect(panelWidth(tester, 'nav'), 200);
    expect(
      find.byWidgetPredicate(
        (w) => w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn,
      ),
      findsNothing,
    );
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
