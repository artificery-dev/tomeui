import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  /// A page with a button that opens a dialog and remembers its answer.
  Future<List<String?>> pumpPage(
    WidgetTester tester, {
    bool barrierDismissible = true,
  }) async {
    final answers = <String?>[];
    await tester.pumpWidget(
      TomeApp(
        home: Builder(
          builder: (context) => Center(
            child: Button(
              onPressed: () async {
                answers.add(
                  await showDialog<String>(
                    context,
                    barrierDismissible: barrierDismissible,
                    builder: (context) => Dialog(
                      title: const Text('Sign the manifest?'),
                      message: const Text('Nothing sails until it is signed.'),
                      actions: [
                        Button(
                          onPressed: () => Navigator.of(context).pop('no'),
                          variant: SurfaceVariant.ghost,
                          center: const Text('Not yet'),
                        ),
                        Button(
                          onPressed: () => Navigator.of(context).pop('yes'),
                          center: const Text('Sign'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              center: const Text('open'),
            ),
          ),
        ),
      ),
    );
    return answers;
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a tall dialog scrolls its title, content, and actions together',
    (tester) async {
      tester.view.physicalSize = const Size(480, 240);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TomeApp(
          home: Builder(
            builder: (context) => Center(
              child: Button(
                center: const Text('open'),
                onPressed: () => showDialog<void>(
                  context,
                  builder: (context) => Dialog(
                    title: const Text('Long dialog'),
                    content: const SizedBox(
                      height: 400,
                      child: Text('Contents'),
                    ),
                    actions: [
                      Button(
                        center: const Text('Done'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await open(tester);
      final titleTop = tester.getTopLeft(find.text('Long dialog')).dy;
      expect(tester.getSize(find.byType(Dialog)).height, greaterThan(240));
      await tester.dragFrom(const Offset(240, 160), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Long dialog')).dy,
        lessThan(titleTop),
      );
      expect(tester.getRect(find.text('Done')).bottom, lessThanOrEqualTo(240));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    },
  );

  testWidgets('the slots read title, message, actions', (tester) async {
    await pumpPage(tester);
    await open(tester);

    final title = tester.getRect(find.text('Sign the manifest?'));
    final message = tester.getRect(
      find.text('Nothing sails until it is signed.'),
    );
    final action = tester.getRect(find.text('Sign'));
    expect(message.top, greaterThan(title.top));
    expect(action.top, greaterThan(message.top));
    expect(
      tester.getRect(find.text('Not yet')).left,
      lessThan(action.left),
      reason: 'the answer to take last finishes the row',
    );
  });

  testWidgets('an action pops the answer back to whoever asked', (
    tester,
  ) async {
    final answers = await pumpPage(tester);
    await open(tester);

    await tester.tap(find.text('Sign'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(answers, ['yes']);
  });

  testWidgets('the scrim dismisses it, and the answer is nothing', (
    tester,
  ) async {
    final answers = await pumpPage(tester);
    await open(tester);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(answers, [null]);
  });

  testWidgets('escape dismisses it too', (tester) async {
    final answers = await pumpPage(tester);
    await open(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(answers, [null]);
  });

  testWidgets('an undismissible dialog stays put until it is answered', (
    tester,
  ) async {
    final answers = await pumpPage(tester, barrierDismissible: false);
    await open(tester);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(answers, ['no']);
  });

  testWidgets('the keyboard is inside it: tabbing reaches its answers and '
      'not the page behind', (tester) async {
    final answers = await pumpPage(tester);
    await open(tester);

    // Tab, then Enter. If the focus had stayed on the page, this would
    // press the button that opened the dialog and open a second one.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(answers, isNotEmpty);
    expect(answers.single, isIn(['yes', 'no']));
  });

  testWidgets('a dialog can wear an icon, in the swatch it was given', (
    tester,
  ) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(
          child: Dialog(
            icon: const Icons().warning,
            swatch: SemanticSwatch.warning,
            title: const Text('Careful'),
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(const Icons().warning));
    expect(
      icon.color,
      const Theme().widgets.surface
          .resolve(SemanticSwatch.warning, SurfaceVariant.solid)
          .fill,
    );
  });
}
