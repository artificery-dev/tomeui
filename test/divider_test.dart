import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: child));

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(
                find.descendant(
                  of: find.byType(Divider),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .decoration
          as BoxDecoration;

  testWidgets('a hairline across the width it is given', (tester) async {
    await pump(tester, const Column(children: [Divider()]));

    final size = tester.getSize(find.byType(Divider));
    expect(size.height, 1, reason: 'the hairline stroke');
    expect(size.width, tester.getSize(find.byType(TomeApp)).width);
    expect(decorationOf(tester).color, const Palette().divider);
  });

  testWidgets('vertical is the same rule turned, filling the height', (
    tester,
  ) async {
    await pump(tester, const Row(children: [Divider(axis: Axis.vertical)]));

    final size = tester.getSize(find.byType(Divider));
    expect(size.width, 1);
    expect(size.height, tester.getSize(find.byType(TomeApp)).height);
  });

  testWidgets('fading trades the flat line for one that dissolves at both '
      'ends', (tester) async {
    await pump(tester, const Column(children: [Divider(fade: true)]));

    final decoration = decorationOf(tester);
    expect(decoration.color, isNull, reason: 'the gradient is the paint');
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors.first.a, 0);
    expect(gradient.colors[1], const Palette().divider);
    expect(gradient.colors.last.a, 0);
  });

  testWidgets('the indents are steps on the scale, and shorten the run', (
    tester,
  ) async {
    await pump(
      tester,
      const Column(
        children: [Divider(indent: SpaceStep.x4, endIndent: SpaceStep.x2)],
      ),
    );

    final line = tester.getSize(
      find.descendant(of: find.byType(Divider), matching: find.byType(SizedBox)),
    );
    expect(line.width, tester.getSize(find.byType(Divider)).width - 24);
  });

  testWidgets('a style given outright bypasses the theme', (tester) async {
    await pump(
      tester,
      const Column(
        children: [
          Divider(style: DividerStyle(color: Color(0xFF00FF00), thickness: 3)),
        ],
      ),
    );

    expect(tester.getSize(find.byType(Divider)).height, 3);
    expect(decorationOf(tester).color, const Color(0xFF00FF00));
  });
}
