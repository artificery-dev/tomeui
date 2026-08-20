import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  testWidgets('a measured bar fills the share it was given', (tester) async {
    await pump(tester, const SizedBox(width: 200, child: Progress.bar(value: 0.25)));

    final fill = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(Progress),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(fill.widthFactor, 0.25);
  });

  testWidgets('a value outside nought and one is brought back inside', (
    tester,
  ) async {
    await pump(tester, const SizedBox(width: 200, child: Progress.bar(value: 4)));

    final fill = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(Progress),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(fill.widthFactor, 1);
  });

  testWidgets('work of unknown length moves; measured work does not', (
    tester,
  ) async {
    await pump(tester, const SizedBox(width: 200, child: Progress.bar()));
    await tester.pump(const Duration(milliseconds: 100));
    final moving = tester
        .widget<FractionallySizedBox>(
          find.descendant(
            of: find.byType(Progress),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .alignment;
    await tester.pump(const Duration(milliseconds: 300));
    final later = tester
        .widget<FractionallySizedBox>(
          find.descendant(
            of: find.byType(Progress),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .alignment;
    expect(later, isNot(moving), reason: 'the sweep travelled');

    // A measured bar has nothing to animate: pumping settles it.
    await pump(tester, const SizedBox(width: 200, child: Progress.bar(value: 0.5)));
    await tester.pumpAndSettle();
  });

  testWidgets('the bar fills a slot that has a width, and takes the style’s '
      'where there is none', (tester) async {
    await pump(
      tester,
      const SizedBox(width: 300, child: Progress.bar(value: 0.5)),
    );
    expect(tester.getSize(find.byType(Progress)).width, 300);

    // A row hands its children all the width in the world, which is no
    // width at all to lay a bar along.
    await pump(
      tester,
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Progress.bar(value: 0.5)],
      ),
    );
    expect(
      tester.getSize(find.byType(Progress)).width,
      const Theme().widgets.progress.resolve().minWidth,
    );
  });

  testWidgets('the spinner is square and the size the style says', (
    tester,
  ) async {
    await pump(tester, const Progress.spinner());

    final style = const Theme().widgets.progress.resolve();
    expect(
      tester.getSize(find.byType(Progress)),
      Size(style.spinnerSize, style.spinnerSize),
    );
  });

  testWidgets('it says what it is doing, and how far along when it knows', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Progress.bar(value: 0.4));

    expect(
      tester.getSemantics(find.byType(Progress)),
      matchesSemantics(label: const Labels().loading, value: '40%'),
    );
    handle.dispose();
  });
}
