import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  /// The ring rides in the foreground decoration — painted, never laid out.
  BoxDecoration? ringOf(WidgetTester tester) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byType(Surface),
                  matching: find.byType(Container),
                ),
              )
              .foregroundDecoration
          as BoxDecoration?;

  testWidgets('types, and reports what was typed', (tester) async {
    final seen = <String>[];
    await pump(tester, TextField(onChanged: seen.add));

    await tester.enterText(find.byType(TextField), 'Valparaíso');
    await tester.pump();

    expect(seen.last, 'Valparaíso');
    expect(find.text('Valparaíso'), findsOneWidget);
  });

  testWidgets('a controller owns the text when one is given', (tester) async {
    final controller = TextEditingController(text: 'Callao');
    addTearDown(controller.dispose);
    await pump(tester, TextField(controller: controller));

    expect(find.text('Callao'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Lima');
    expect(controller.text, 'Lima');
  });

  testWidgets('the placeholder stands in only while it is empty', (
    tester,
  ) async {
    await pump(tester, const TextField(placeholder: Text('Port of call')));
    expect(find.text('Port of call'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'V');
    await tester.pump();
    expect(find.text('Port of call'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Port of call'), findsOneWidget);
  });

  testWidgets('a controller that arrives with text keeps the placeholder '
      'out', (tester) async {
    final full = TextEditingController(text: '/home/you/Music');
    addTearDown(full.dispose);
    await pump(
      tester,
      TextField(controller: full, placeholder: const Text('Port of call')),
    );
    expect(find.text('/home/you/Music'), findsOneWidget);
    expect(find.text('Port of call'), findsNothing);

    // Swapped for an empty one, the placeholder comes back.
    final empty = TextEditingController();
    addTearDown(empty.dispose);
    await pump(
      tester,
      TextField(controller: empty, placeholder: const Text('Port of call')),
    );
    expect(find.text('Port of call'), findsOneWidget);
  });

  testWidgets('a tap puts the keyboard in it, and rings it', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await pump(tester, TextField(focusNode: focus));

    /// The ring is painted, not laid out — so it shows up as a foreground
    /// painter rather than as a box anyone can measure.
    bool ringed() => tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(TextField),
            matching: find.byType(CustomPaint),
          ),
        )
        .any((paint) => paint.foregroundPainter != null);

    expect(focus.hasFocus, isFalse);
    expect(ringed(), isFalse);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(focus.hasFocus, isTrue);
    expect(ringed(), isTrue);
  });

  testWidgets('label above, helper below', (tester) async {
    await pump(
      tester,
      const TextField(
        label: Text('Port of call'),
        helper: Text('Where the cargo leaves the ship.'),
      ),
    );

    expect(
      tester.getCenter(find.text('Port of call')).dy,
      lessThan(tester.getCenter(find.byType(Surface)).dy),
    );
    expect(
      tester.getCenter(find.text('Where the cargo leaves the ship.')).dy,
      greaterThan(tester.getCenter(find.byType(Surface)).dy),
    );
  });

  testWidgets('an error replaces the helper and turns the whole box', (
    tester,
  ) async {
    await pump(
      tester,
      const TextField(
        helper: Text('Where the cargo leaves the ship.'),
        error: Text('Nowhere by that name.'),
      ),
    );

    expect(find.text('Where the cargo leaves the ship.'), findsNothing);
    expect(find.text('Nowhere by that name.'), findsOneWidget);

    final errored = const Theme().widgets.textField
        .resolve(SemanticSwatch.error)
        .surface
        .border;
    expect((ringOf(tester)?.border as Border?)?.top.color, errored);
  });

  testWidgets('what is typed keeps the page’s text color', (tester) async {
    await pump(tester, const TextField(swatch: SemanticSwatch.error));

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).style.color,
      const Palette().text,
      reason: 'the swatch dresses the chrome, not the content',
    );
  });

  testWidgets('disabled: dimmed, and out of reach', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await pump(tester, TextField(focusNode: focus, enabled: false));

    await tester.tap(find.byType(TextField), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
    expect(focus.canRequestFocus, isFalse);

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(TextField),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      const Opacities().disabled,
    );
  });

  testWidgets('read-only takes no typing but still takes focus', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Callao');
    addTearDown(controller.dispose);
    await pump(tester, TextField(controller: controller, readOnly: true));

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('obscured text hides what it holds', (tester) async {
    await pump(tester, const TextField(obscureText: true));

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isTrue);
    expect(
      editable.enableInteractiveSelection,
      isFalse,
      reason: 'and a password is not there to be selected out',
    );
  });

  testWidgets('the keyboard’s done key reports', (tester) async {
    String? submitted;
    await pump(tester, TextField(onSubmitted: (value) => submitted = value));

    await tester.enterText(find.byType(TextField), 'Valparaíso');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, 'Valparaíso');
  });

  testWidgets('one line stands at control height; more lines grow', (
    tester,
  ) async {
    await pump(tester, const TextField());
    final single = tester.getSize(find.byType(Surface)).height;
    expect(single, const Sizes().control);

    await pump(tester, const TextField(maxLines: 3, minLines: 3));
    expect(tester.getSize(find.byType(Surface)).height, greaterThan(single));
  });

  testWidgets('the slots sit either side of the text', (tester) async {
    await pump(
      tester,
      TextField(
        leading: Icon(const Icons().search),
        trailing: Icon(const Icons().close),
      ),
    );

    final text = tester.getCenter(find.byType(EditableText)).dx;
    expect(
      tester.getCenter(find.byIcon(const Icons().search)).dx,
      lessThan(text),
    );
    expect(
      tester.getCenter(find.byIcon(const Icons().close)).dx,
      greaterThan(text),
    );
  });
}
