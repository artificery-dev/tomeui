import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  late TextEditingController controller;

  Future<void> pump(
    WidgetTester tester, {
    Theme theme = const Theme(),
    EditableTextContextMenuBuilder? contextMenuBuilder,
  }) async {
    controller = TextEditingController(text: 'Valparaiso harbour');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TomeApp(
        theme: theme,
        home: Center(
          child: SizedBox(
            width: 300,
            child: TextField(
              controller: controller,
              contextMenuBuilder: contextMenuBuilder,
            ),
          ),
        ),
      ),
    );
  }

  EditableText editable(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText));

  /// A point on the first word, rather than the middle of the box — past the
  /// end of the text there is no word to take.
  Offset onTheWord(WidgetTester tester) {
    final box = tester.getRect(find.byType(EditableText));
    return Offset(box.left + 20, box.center.dy);
  }

  /// The touch gesture that raises the bar.
  Future<void> longPress(WidgetTester tester) async {
    await tester.longPressAt(onTheWord(tester));
    await tester.pumpAndSettle();
  }

  /// The desktop gesture: a right-click on the words.
  Future<void> rightClick(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      onTheWord(tester),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// Raises the menu over a selection both platforms can agree on, so what's
  /// offered can be compared without the gestures getting a vote.
  Future<void> showOver(WidgetTester tester, TextSelection selection) async {
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    controller.selection = selection;
    await tester.pump();
    tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
    await tester.pumpAndSettle();
  }

  /// Whichever presentation is up, the verbs it offers.
  List<String> verbs(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .nonNulls
      .where((word) => word != controller.text)
      .toList();

  group('on a touch screen', () {
    testWidgets('a long press raises a bar of verbs', (tester) async {
      await pump(tester);
      expect(find.text('Copy'), findsNothing);

      await longPress(tester);

      expect(find.text('Copy'), findsOneWidget);
      expect(
        find.byType(Button),
        findsWidgets,
        reason: 'the touch presentation is a row of buttons, not a list',
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('the verbs do what they say', (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pump(tester);
      await longPress(tester);
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      final copies = calls.where((c) => c.method == 'Clipboard.setData');
      expect(copies, hasLength(1));
      expect((copies.single.arguments as Map)['text'], 'Valparaiso');
      expect(find.text('Copy'), findsNothing, reason: 'and it closes behind');
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('the selection wears grips', (tester) async {
      await pump(tester);
      expect(editable(tester).showSelectionHandles, isFalse);

      await longPress(tester);

      expect(editable(tester).selectionControls, isA<TextSelectionHandles>());
      expect(editable(tester).showSelectionHandles, isTrue);
      expect(
        (editable(tester).selectionControls! as TextSelectionHandles).size,
        const Sizes().iconLarge,
      );
    }, variant: TargetPlatformVariant.mobile());
  });

  group('on a desktop', () {
    testWidgets('a right-click raises a menu, not a bar', (tester) async {
      await pump(tester);
      expect(find.text('Select all'), findsNothing);

      await rightClick(tester);

      expect(find.text('Select all'), findsOneWidget);
      expect(
        find.byType(Button),
        findsNothing,
        reason: 'the desktop presentation is a menu, not a row of buttons',
      );
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('and no grips: a cursor drags nothing', (tester) async {
      await pump(tester);
      await rightClick(tester);

      expect(editable(tester).selectionControls, isNull);
      expect(editable(tester).showSelectionHandles, isFalse);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('the menu leaves the keyboard where it found it', (
      tester,
    ) async {
      await pump(tester);
      await rightClick(tester);

      expect(
        editable(tester).focusNode.hasFocus,
        isTrue,
        reason: 'a menu that took focus would collapse the selection',
      );
    }, variant: TargetPlatformVariant.desktop());
  });

  testWidgets('one list, two presentations', (tester) async {
    // Handed the same entries, each platform renders them its own way and
    // offers exactly what it was given.
    List<MenuEntry> entries(BuildContext context, EditableTextState state) => [
      MenuItem(label: const Text('Weigh'), onPressed: () {}),
      MenuItem(label: const Text('Anchor'), onPressed: () {}),
    ];
    const word = TextSelection(baseOffset: 0, extentOffset: 10);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await pump(
      tester,
      contextMenuBuilder: (context, state) => TextSelectionMenu(
        editableTextState: state,
        entries: entries(context, state),
      ),
    );
    await showOver(tester, word);
    expect(verbs(tester), ['Weigh', 'Anchor']);
    expect(find.byType(Button), findsNWidgets(2), reason: 'a bar of buttons');

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await pump(
      tester,
      contextMenuBuilder: (context, state) => TextSelectionMenu(
        editableTextState: state,
        entries: entries(context, state),
      ),
    );
    await showOver(tester, word);
    expect(verbs(tester), ['Weigh', 'Anchor']);
    expect(find.byType(Button), findsNothing, reason: 'a menu of rows');

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('what the editor can do reaches both', (tester) async {
    // The default list is the editor's own: what it offers varies by
    // platform — Android shares, Apple looks up — but both presentations ask
    // the same question to get it.
    const word = TextSelection(baseOffset: 0, extentOffset: 10);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await pump(tester);
    await showOver(tester, word);
    final touch = verbs(tester);

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await pump(tester);
    await showOver(tester, word);
    final desktop = verbs(tester);
    debugDefaultTargetPlatformOverride = null;

    for (final offered in [touch, desktop]) {
      expect(offered, contains('Cut'));
      expect(offered, contains('Copy'));
      expect(offered, contains('Select all'));
    }
  });

  testWidgets('the words come from the theme', (tester) async {
    await pump(
      tester,
      theme: const Theme(labels: Labels(copy: 'Copiar')),
    );
    await showOver(
      tester,
      const TextSelection(baseOffset: 0, extentOffset: 10),
    );

    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Copy'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'a field can bring its own list, and both presentations take it',
    (tester) async {
      await pump(
        tester,
        contextMenuBuilder: (context, state) => TextSelectionMenu(
          editableTextState: state,
          entries: [
            ...textSelectionEntries(context, state),
            MenuItem(label: const Text('Translate'), onPressed: () {}),
          ],
        ),
      );
      await showOver(
        tester,
        const TextSelection(baseOffset: 0, extentOffset: 10),
      );

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
    },
    variant: TargetPlatformVariant.all(),
  );
}
