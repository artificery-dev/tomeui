import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  const theme = Theme();
  final style = theme.widgets.code.resolve();

  /// One row of monospace at the block's own metrics.
  double oneLineHeight(WidgetTester tester) =>
      tester.getSize(find.text('1')).height;

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      TomeApp(
        home: Center(child: SizedBox(width: 600, child: child)),
      ),
    );
    await tester.pump();
  }

  /// Every run of text a paragraph is made of, with the color it wears —
  /// which is what "highlighted" means once it's on screen.
  List<(String, Color?)> runs(WidgetTester tester, String text) {
    final paragraph = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((widget) => widget.text.toPlainText().contains(text));
    final found = <(String, Color?)>[];
    paragraph.text.visitChildren((span) {
      if (span is TextSpan && span.text != null && span.text!.isNotEmpty) {
        found.add((span.text!, span.style?.color));
      }
      return true;
    });
    return found;
  }

  testWidgets('numbers every line, from one', (tester) async {
    await pump(tester, const CodeText.block('one\ntwo\nthree'));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('firstLine numbers an excerpt from where it starts', (
    tester,
  ) async {
    await pump(tester, const CodeText.block('a\nb', firstLine: 41));

    expect(find.text('41'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('line numbers keep their line, however many digits', (
    tester,
  ) async {
    double heightOf(int first) => tester.getSize(find.text('$first')).height;

    await pump(tester, const CodeText.block('a\nb\nc'));
    final oneLine = heightOf(1);

    // The gutter is sized from a measurement, and the rule and the padding
    // sit outside that box. Fold them into it and every number wide enough
    // to need the room wraps to a second row.
    for (final first in [9, 99, 200, 9999]) {
      await pump(tester, CodeText.block('a\nb\nc', firstLine: first));
      expect(heightOf(first), oneLine, reason: 'line $first folded');
    }
  });

  testWidgets('the rule runs the whole of a folded line', (tester) async {
    const long =
        'a line long enough that folding it takes several whole rows inside '
        'a narrow block, which is the case the rule has to survive';

    await pump(tester, const CodeText.block('short\n$long\nshort', wrap: true));

    final code = find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().startsWith('a line'),
    );
    final row = find.ancestor(of: code, matching: find.byType(Row)).first;
    // The rule hangs off whichever side of the row is the tall one, so on
    // a folded line it has to be the code — on the gutter it would stop
    // after the first row and leave the rule in pieces.
    final ruled = find
        .ancestor(of: code, matching: find.byType(Container))
        .first;

    expect(tester.getSize(row).height, greaterThan(oneLineHeight(tester)));
    expect(tester.getSize(ruled).height, tester.getSize(row).height);
  });

  testWidgets('lineNumbers: false leaves the gutter off', (tester) async {
    await pump(tester, const CodeText.block('a\nb', lineNumbers: false));

    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('one trailing newline is not a blank last line', (tester) async {
    await pump(tester, const CodeText.block('one\ntwo\n'));

    expect(find.text('3'), findsNothing);
  });

  testWidgets('an unknown language still gets a numbered block', (
    tester,
  ) async {
    await pump(
      tester,
      const CodeText.block('SELECT 1;', language: 'no-such-language'),
    );

    expect(find.text('1'), findsOneWidget);
    // Plain: every run wears the same color the body monospace does.
    expect(runs(tester, 'SELECT').map((run) => run.$2).toSet(), {
      style.textStyle.color,
    });
  });

  test('every grammar re_highlight ships is known, aliases included', () {
    expect(CodeSyntax.knows('dart'), isTrue);
    expect(CodeSyntax.knows('javascript'), isTrue);
    expect(CodeSyntax.knows('js'), isTrue);
    expect(CodeSyntax.knows('yml'), isTrue);
    expect(CodeSyntax.knows('no-such-language'), isFalse);
    expect(CodeSyntax.knows(null), isFalse);
    expect(CodeSyntax.languages.length, greaterThan(150));
  });

  testWidgets('a known language colors its scopes from the palette', (
    tester,
  ) async {
    await pump(
      tester,
      const CodeText.block("const name = 'tome';", language: 'dart'),
    );

    Color? colorOf(String text) =>
        runs(tester, 'const').firstWhere((run) => run.$1.contains(text)).$2;

    // Keywords speak in the brand, strings in the success swatch — the
    // mapping the resolver lays down, not a scheme from an editor.
    expect(colorOf('const'), style.syntax['keyword']!.color);
    expect(colorOf("'tome'"), style.syntax['string']!.color);
    expect(colorOf('const'), isNot(colorOf("'tome'")));
  });

  testWidgets('a construct spanning lines stays one construct', (tester) async {
    await pump(
      tester,
      const CodeText.block(
        '/* open\n   still a comment */\nvar x = 1;',
        language: 'dart',
      ),
    );

    // The second line is inside the block comment the first line opened.
    // Highlighting line by line would have called it code.
    final second = runs(tester, 'still a comment');
    expect(
      second.every((run) => run.$2 == style.syntax['comment']!.color),
      isTrue,
    );
  });

  testWidgets('highlightLines washes the lines it names', (tester) async {
    Iterable<Color> washes() => tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .map((box) => box.color)
        .where((color) => color == style.lineHighlight);

    await pump(tester, const CodeText.block('a\nb\nc'));
    expect(washes(), isEmpty);

    // One wash for the gutter cell and one for the code, so the call-out
    // runs unbroken across the rule.
    await pump(tester, const CodeText.block('a\nb\nc', highlightLines: {2}));
    expect(washes().length, 2);
  });

  testWidgets('highlightLines counts in firstLine terms', (tester) async {
    await pump(
      tester,
      const CodeText.block('a\nb', firstLine: 10, highlightLines: {11}),
    );

    final washed = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((box) => box.color == style.lineHighlight);
    expect(washed.length, 2);
  });

  testWidgets('scrolls sideways by default and folds when told to', (
    tester,
  ) async {
    const long =
        'a very long line of code that will not fit inside six hundred '
        'logical pixels no matter how hard it tries to';

    RichText codeParagraph(WidgetTester tester) => tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((widget) => widget.text.toPlainText().contains('very'));

    await pump(tester, const CodeText.block(long));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(codeParagraph(tester).softWrap, isFalse);

    await pump(tester, const CodeText.block(long, wrap: true));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(codeParagraph(tester).softWrap, isTrue);
  });

  testWidgets('the block keeps the copy affordance', (tester) async {
    await pump(tester, const CodeText.block('a\nb'));
    expect(find.byType(Icon), findsOneWidget);

    await pump(tester, const CodeText.block('a\nb', copyable: false));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('the block wears the card, the chip wears the chip', (
    tester,
  ) async {
    await pump(tester, const CodeText.block('a'));
    expect(style.block.radius, theme.radii.medium);
    expect(style.block.border, theme.palette.divider);
    // The inline shape is unchanged by any of this.
    expect(style.surface.radius, theme.radii.small);
  });
}
