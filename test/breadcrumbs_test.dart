import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  testWidgets('a chevron between every pair, and none at the ends', (
    tester,
  ) async {
    await pump(
      tester,
      Breadcrumbs(
        crumbs: [
          Crumb(label: const Text('Fleet'), onPressed: () {}),
          Crumb(label: const Text('Endeavour'), onPressed: () {}),
          const Crumb(label: Text('Manifest')),
        ],
      ),
    );

    expect(find.byIcon(const Icons().chevronRight), findsNWidgets(2));
  });

  testWidgets('the separator can be anything', (tester) async {
    await pump(
      tester,
      Breadcrumbs(
        separator: const Text('/'),
        crumbs: [
          Crumb(label: const Text('Fleet'), onPressed: () {}),
          const Crumb(label: Text('Endeavour')),
        ],
      ),
    );

    expect(find.text('/'), findsOneWidget);
    expect(find.byIcon(const Icons().chevronRight), findsNothing);
  });

  testWidgets('a crumb takes an icon of its own', (tester) async {
    await pump(
      tester,
      Breadcrumbs(
        crumbs: [
          Crumb(
            label: const Text('Fleet'),
            icon: const Icons().home,
            onPressed: () {},
          ),
          const Crumb(label: Text('Endeavour')),
        ],
      ),
    );

    expect(find.byIcon(const Icons().home), findsOneWidget);
  });

  testWidgets('the way back is pressable; where you are is not', (
    tester,
  ) async {
    final went = <String>[];
    await pump(
      tester,
      Breadcrumbs(
        crumbs: [
          Crumb(label: const Text('Fleet'), onPressed: () => went.add('Fleet')),
          Crumb(
            label: const Text('Manifest'),
            onPressed: () => went.add('Manifest'),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Fleet'));
    await tester.pump();
    expect(went, ['Fleet']);

    // The last crumb keeps its words but not its press: it's where you
    // already are.
    await tester.tap(find.text('Manifest'));
    await tester.pump();
    expect(went, ['Fleet']);
  });

  testWidgets('the current crumb speaks in the fuller voice', (tester) async {
    await pump(
      tester,
      Breadcrumbs(
        crumbs: [
          Crumb(label: const Text('Fleet'), onPressed: () {}),
          const Crumb(label: Text('Manifest')),
        ],
      ),
    );

    const style = Theme();
    final resolved = style.widgets.breadcrumbs.resolve();
    Color? colorOf(String label) => DefaultTextStyle.of(
      tester.element(find.text(label)),
    ).style.color;

    expect(colorOf('Manifest'), resolved.currentStyle.color);
    expect(colorOf('Fleet'), resolved.textStyle.color);
    expect(
      colorOf('Fleet'),
      isNot(colorOf('Manifest')),
      reason: 'the way back is quieter than where you are',
    );
  });
}
