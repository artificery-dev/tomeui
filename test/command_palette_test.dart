import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  List<Command> commands(List<String> ran) => [
    Command(
      name: 'Save',
      section: 'File',
      hint: '⌘S',
      onInvoke: () => ran.add('Save'),
    ),
    Command(
      name: 'Save as…',
      section: 'File',
      onInvoke: () => ran.add('Save as…'),
    ),
    Command(
      name: 'Toggle sidebar',
      section: 'View',
      keywords: const ['panel', 'drawer'],
      onInvoke: () => ran.add('Toggle sidebar'),
    ),
    Command(
      name: 'Close',
      enabled: false,
      onInvoke: () => ran.add('Close'),
    ),
  ];

  Future<void> pump(WidgetTester tester, List<String> ran) => tester.pumpWidget(
    TomeApp(
      home: Center(child: CommandPalette(commands: commands(ran))),
    ),
  );

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }

  testWidgets('everything is offered until something is typed', (
    tester,
  ) async {
    await pump(tester, []);

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Toggle sidebar'), findsOneWidget);
    expect(find.text('File'), findsOneWidget, reason: 'the section label');
    expect(find.text('⌘S'), findsOneWidget, reason: 'the shortcut hint');
  });

  testWidgets('typing narrows it, and what starts with the query leads', (
    tester,
  ) async {
    await pump(tester, []);
    await type(tester, 'sa');

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Toggle sidebar'), findsNothing);

    // "Save" starts with it; "Save as…" does too — both stay, in order.
    expect(
      tester.getRect(find.text('Save as…')).top,
      greaterThan(tester.getRect(find.text('Save')).top),
    );
  });

  testWidgets('a keyword finds a command its name does not', (tester) async {
    await pump(tester, []);
    await type(tester, 'drawer');

    expect(find.text('Toggle sidebar'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('nothing matching says so', (tester) async {
    await pump(tester, []);
    await type(tester, 'zzz');

    expect(find.text(const Labels().noMatches), findsOneWidget);
  });

  testWidgets('clicking a command runs it', (tester) async {
    final ran = <String>[];
    await pump(tester, ran);

    await tester.tap(find.text('Toggle sidebar'));
    await tester.pumpAndSettle();
    expect(ran, ['Toggle sidebar']);
  });

  testWidgets('the arrows walk it and Enter runs the one you are on', (
    tester,
  ) async {
    final ran = <String>[];
    await pump(tester, ran);

    // The field holds the keyboard; the arrows are what it doesn't use.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(ran, ['Save as…']);
  });

  testWidgets('a disabled command cannot be run', (tester) async {
    final ran = <String>[];
    await pump(tester, ran);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(ran, isEmpty);
  });

  testWidgets('shown over the page, escape dismisses it and a command '
      'closes it', (tester) async {
    final ran = <String>[];
    late BuildContext pageContext;
    await tester.pumpWidget(
      TomeApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );

    var closed = false;
    unawaited(
      showCommandPalette(
        pageContext,
        commands: commands(ran),
      ).then((_) => closed = true),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CommandPalette), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CommandPalette), findsNothing);
    expect(closed, isTrue);

    // And again, this time leaving by way of a command.
    unawaited(showCommandPalette(pageContext, commands: commands(ran)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(CommandPalette), findsNothing);
    expect(ran, ['Save'], reason: 'run once the palette is out of the way');
  });
}
