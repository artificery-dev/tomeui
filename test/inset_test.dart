import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Theme theme = const Theme(),
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    TomeApp(
      theme: theme,
      home: Directionality(
        textDirection: direction,
        child: Center(child: child),
      ),
    ),
  );

  testWidgets('a step on every side', (tester) async {
    await pump(tester, const Inset.all(SpaceStep.x4, child: Text('x')));

    final text = tester.getSize(find.text('x'));
    expect(
      tester.getSize(find.byType(Inset)),
      Size(text.width + 32, text.height + 32),
      reason: 'x4 is 16 a side',
    );
  });

  testWidgets('symmetric takes one step each way, none where unsaid', (
    tester,
  ) async {
    await pump(
      tester,
      const Inset.symmetric(horizontal: SpaceStep.x6, child: Text('x')),
    );

    final text = tester.getSize(find.text('x'));
    expect(
      tester.getSize(find.byType(Inset)),
      Size(text.width + 48, text.height),
    );
  });

  testWidgets('start and end follow the reading direction', (tester) async {
    await pump(tester, const Inset.only(start: SpaceStep.x4, child: Text('x')));
    expect(
      tester.getTopLeft(find.text('x')).dx -
          tester.getTopLeft(find.byType(Inset)).dx,
      16,
    );

    await pump(
      tester,
      const Inset.only(start: SpaceStep.x4, child: Text('x')),
      direction: TextDirection.rtl,
    );
    expect(
      tester.getTopRight(find.byType(Inset)).dx -
          tester.getTopRight(find.text('x')).dx,
      16,
      reason: 'the start edge is the right one now',
    );
  });

  testWidgets('the scale is the theme’s, so a denser one re-inks it', (
    tester,
  ) async {
    await pump(
      tester,
      const Inset.all(SpaceStep.x4, child: Text('x')),
      theme: const Theme(space: Space(x4: 4)),
    );

    final text = tester.getSize(find.text('x'));
    expect(
      tester.getSize(find.byType(Inset)),
      Size(text.width + 8, text.height + 8),
    );
  });
}
