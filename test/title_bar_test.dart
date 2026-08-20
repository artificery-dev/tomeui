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

  testWidgets('the bar is the height the style says', (tester) async {
    await pump(tester, const TitleBar(title: Text('Manifest')));

    final style = const Theme().widgets.titleBar.resolve();
    expect(tester.getSize(find.byType(TitleBar)).height, style.height);
  });

  testWidgets('centred, the title sits on the window’s middle', (
    tester,
  ) async {
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
}
