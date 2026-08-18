import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(TomeApp(home: Center(child: child)));

  /// Catches what the widget hands the platform, so the copy can be proved
  /// without a real clipboard.
  List<MethodCall> watchClipboard(WidgetTester tester) {
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
    return calls;
  }

  testWidgets('wears the monospace token on a quiet chip', (tester) async {
    await pump(tester, const CodeText('pub get'));

    // First paragraph in the chip: the code itself. (An icon is a glyph in
    // a paragraph too, so the copy button brings a second one.)
    final style = tester
        .widget<RichText>(
          find
              .descendant(
                of: find.byType(CodeText),
                matching: find.byType(RichText),
              )
              .first,
        )
        .text
        .style!;
    expect(style.fontFamily, const Typography().code.fontFamily);
    expect(style.fontSize, const Typography().code.fontSize);

    final decoration =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(CodeText),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration?;
    expect(
      decoration?.color,
      const Theme().widgets.code.resolve().surface.fill,
    );
  });

  testWidgets('copying puts the code on the clipboard', (tester) async {
    final calls = watchClipboard(tester);
    await pump(tester, const CodeText('flutter pub add tomeui'));

    await tester.tap(find.byIcon(const Icons().copy));
    await tester.pump();

    final copies = calls.where((c) => c.method == 'Clipboard.setData');
    expect(copies, hasLength(1));
    expect((copies.single.arguments as Map)['text'], 'flutter pub add tomeui');

    // Let the confirmation time out rather than leaving its timer pending.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the button confirms, then goes back to offering', (
    tester,
  ) async {
    watchClipboard(tester);
    await pump(tester, const CodeText('pub get'));

    await tester.tap(find.byIcon(const Icons().copy));
    await tester.pump();
    expect(find.byIcon(const Icons().confirm), findsOneWidget);
    expect(find.byIcon(const Icons().copy), findsNothing);

    await tester.pump(const Theme().widgets.code.resolve().confirmFor);
    await tester.pump();
    expect(find.byIcon(const Icons().copy), findsOneWidget);
  });

  testWidgets('a second copy restarts the confirmation', (tester) async {
    watchClipboard(tester);
    await pump(tester, const CodeText('pub get'));
    final confirmFor = const Theme().widgets.code.resolve().confirmFor;

    await tester.tap(find.byIcon(const Icons().copy));
    await tester.pump(confirmFor ~/ 2);
    await tester.tap(find.byIcon(const Icons().confirm));
    await tester.pump(confirmFor ~/ 2);

    // The first timer would have fired by now; the second one hasn't.
    expect(find.byIcon(const Icons().confirm), findsOneWidget);
    await tester.pump(confirmFor);
  });

  testWidgets('copyable: false leaves the affordance off', (tester) async {
    await pump(tester, const CodeText('pub get', copyable: false));

    expect(find.byIcon(const Icons().copy), findsNothing);
  });

  testWidgets('the copy button says what it is', (tester) async {
    final semantics = tester.ensureSemantics();
    watchClipboard(tester);
    await pump(tester, const CodeText('pub get'));

    expect(find.bySemanticsLabel('Copy'), findsOneWidget);

    await tester.tap(find.byIcon(const Icons().copy));
    await tester.pump();
    expect(find.bySemanticsLabel('Copied'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    semantics.dispose();
  });
}
