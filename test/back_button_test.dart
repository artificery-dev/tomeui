import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  testWidgets('on the first page there is nothing to go back to, and so '
      'nothing drawn', (tester) async {
    await tester.pumpWidget(
      const TomeApp(home: Center(child: BackButton())),
    );

    expect(find.byType(Button), findsNothing);
    expect(tester.getSize(find.byType(BackButton)), Size.zero);
  });

  testWidgets('pushed onto a stack it appears, and pops what pushed it', (
    tester,
  ) async {
    await tester.pumpWidget(
      TomeApp(
        home: Builder(
          builder: (context) => Center(
            child: Button(
              onPressed: () => Navigator.of(context).push(
                TomePageRoute<void>(
                  builder: (_) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [BackButton(), Text('second')],
                    ),
                  ),
                ),
              ),
              center: const Text('go'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    expect(find.byType(Button), findsOneWidget, reason: 'the back button');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsNothing);
    expect(find.text('go'), findsOneWidget);
  });

  testWidgets('given a press of its own it shows regardless, and does that '
      'instead', (tester) async {
    var went = 0;
    await tester.pumpWidget(
      TomeApp(
        home: Center(child: BackButton(onPressed: () => went++)),
      ),
    );

    expect(find.byType(Button), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(went, 1);
  });

  testWidgets('words beside the glyph, when a bar has room for them', (
    tester,
  ) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: BackButton(onPressed: () {}, label: const Text('Fleet')),
        ),
      ),
    );

    expect(find.text('Fleet'), findsOneWidget);
    expect(find.byIcon(const Icons().back), findsOneWidget);
  });
}
