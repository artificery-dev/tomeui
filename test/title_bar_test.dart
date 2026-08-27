import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Column(children: [child])));

  testWidgets('the slots read leading, title, actions', (tester) async {
    await pump(
      tester,
      TitleBar(
        leading: const [Text('back')],
        title: const Text('Manifest'),
        subtitle: const Text('Endeavour'),
        actions: [Button(onPressed: () {}, center: const Text('Sign'))],
      ),
    );

    final leading = tester.getRect(find.text('back'));
    final title = tester.getRect(find.text('Manifest'));
    final action = tester.getRect(find.text('Sign'));
    expect(title.left, greaterThan(leading.right));
    expect(action.left, greaterThan(title.right));
    expect(
      tester.getRect(find.text('Endeavour')).top,
      greaterThan(title.top),
      reason: 'the subtitle sits under the title',
    );
  });

  testWidgets('the actions finish in the trailing corner', (tester) async {
    await pump(
      tester,
      TitleBar(
        leading: const [Text('back')],
        title: const Text('Manifest'),
        actions: [Button(onPressed: () {}, center: const Text('Sign'))],
      ),
    );

    final style = const Theme().widgets.titleBar.resolve();
    final bar = tester.getRect(find.byType(TitleBar));
    final action = tester.getRect(
      find.ancestor(of: find.text('Sign'), matching: find.byType(Button)).first,
    );
    expect(
      action.right,
      moreOrLessEquals(
        bar.right - style.padding.resolve(TextDirection.ltr).right,
        epsilon: 1,
      ),
    );
  });

  testWidgets('a press on the bar\'s own children is not held by the '
      'window\'s double-tap', (tester) async {
    // Wrapped around the bar, the double-tap-to-maximise recognizer joins
    // the arena of every press its children take and holds it for
    // kDoubleTapTimeout — a third of a second between clicking a menu and
    // seeing it open.
    var pressed = 0;
    await pump(
      tester,
      TitleBar(
        dragToMove: true,
        windowControls: false,
        leading: [
          Button(onPressed: () => pressed++, center: const Text('File')),
        ],
        title: const Text('Manifest'),
      ),
    );

    await tester.tap(find.text('File'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(pressed, 1, reason: 'the press lands on the frame after it');
  });

  testWidgets('the bar is the height the style says', (tester) async {
    await pump(tester, const TitleBar(title: Text('Manifest')));

    final style = const Theme().widgets.titleBar.resolve();
    expect(tester.getSize(find.byType(TitleBar)).height, style.height);
  });

  testWidgets('centred, the title sits on the window’s middle', (tester) async {
    await pump(
      tester,
      const TitleBar(
        centerTitle: true,
        leading: [Text('back')],
        title: Text('Manifest'),
      ),
    );

    expect(
      tester.getCenter(find.text('Manifest')).dx,
      moreOrLessEquals(tester.getCenter(find.byType(TitleBar)).dx, epsilon: 1),
    );
  });

  testWidgets('off desktop there are no window buttons and nothing to drag', (
    tester,
  ) async {
    await pump(tester, const TitleBar(title: Text('Manifest')));

    expect(find.byType(WindowControls), findsNothing);
    expect(
      find.descendant(
        of: find.byType(TitleBar),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
      reason: 'a phone has no window to move',
    );
  });

  testWidgets('asked for them outright, the window buttons are there', (
    tester,
  ) async {
    await pump(
      tester,
      const TitleBar(title: Text('Manifest'), windowControls: true),
    );

    const labels = Labels();
    expect(find.byType(WindowControls), findsOneWidget);
    expect(find.bySemanticsLabel(labels.minimizeWindow), findsOneWidget);
    expect(find.bySemanticsLabel(labels.maximizeWindow), findsOneWidget);
    expect(find.bySemanticsLabel(labels.closeWindow), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'no window to ask, and it says so quietly',
    );
  });

  testWidgets('on a desktop it draws them itself, except on macOS', (
    tester,
  ) async {
    for (final platform in [TargetPlatform.linux, TargetPlatform.windows]) {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await pump(tester, const TitleBar(title: Text('Manifest')));
      expect(find.byType(WindowControls), findsOneWidget, reason: '$platform');
    }

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await pump(tester, const TitleBar(title: Text('Manifest')));
    expect(
      find.byType(WindowControls),
      findsNothing,
      reason: 'the system draws them there',
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the window buttons bleed into the corner, square', (
    tester,
  ) async {
    await pump(
      tester,
      TitleBar(
        windowControls: true,
        title: const Text('Manifest'),
        actions: [Button(onPressed: () {}, center: const Text('Sign'))],
      ),
    );

    final bar = tester.getRect(find.byType(TitleBar));
    final controls = tester.getRect(find.byType(WindowControls));
    expect(controls.right, bar.right, reason: 'no padding holds them in');
    expect(controls.top, bar.top);
    expect(controls.bottom, bar.bottom);

    final buttons = find.descendant(
      of: find.byType(WindowControls),
      matching: find.byType(AspectRatio),
    );
    expect(buttons, findsNWidgets(3));
    for (final button in buttons.evaluate()) {
      final box = tester.getRect(find.byWidget(button.widget));
      expect(box.size, Size.square(bar.height), reason: 'square with the bar');
    }
  });

  testWidgets('the close glyph is drawn in the bar\'s voice, not its fill', (
    tester,
  ) async {
    await pump(tester, const TitleBar(windowControls: true));

    final style = const Theme().widgets.titleBar.resolve();
    final painters = [
      for (final paint in tester.widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(WindowControls),
          matching: find.byType(CustomPaint),
        ),
      ))
        if (paint.painter != null) paint.painter! as dynamic,
    ].where((painter) => painter.runtimeType.toString().contains('Glyph'));

    // A wash at rest is the hover colour at zero alpha rather than null, so
    // asking whether there *is* a wash painted the close cross in the bar's
    // own fill: a button nobody could see.
    expect(painters.length, 3);
    for (final painter in painters) {
      expect(painter.color, style.surface.foreground);
      expect(painter.color, isNot(style.surface.fill));
    }
  });

  testWidgets('a glyph named in the theme is drawn instead of the shape', (
    tester,
  ) async {
    await tester.pumpWidget(
      TomeApp(
        theme: Theme(icons: Icons(windowClose: const Icons().close)),
        home: const Column(children: [TitleBar(windowControls: true)]),
      ),
    );

    expect(find.byIcon(const Icons().close), findsOneWidget);
  });
}
