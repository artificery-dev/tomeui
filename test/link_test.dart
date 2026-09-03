import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.dark,
  }) => tester.pumpWidget(
    TomeApp(
      theme: Theme(palette: Palette(brightness: brightness)),
      home: Center(child: child),
    ),
  );

  TextStyle painted(WidgetTester tester) => tester
      .widget<RichText>(
        find.descendant(of: find.byType(Link), matching: find.byType(RichText)),
      )
      .text
      .style!;

  /// Puts a mouse over the link and leaves it there. Hover highlights only
  /// show in traditional (pointer) highlight mode; the test platform
  /// defaults to touch.
  Future<void> hover(WidgetTester tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(Link)));
    await tester.pumpAndSettle();
  }

  testWidgets('follows on tap', (tester) async {
    var followed = 0;
    await pump(tester, Link('the manifest', onPressed: () => followed++));

    await tester.tap(find.byType(Link));
    expect(followed, 1);
  });

  testWidgets('a null onPressed disables it', (tester) async {
    await pump(tester, const Link('the manifest', onPressed: null));

    await tester.tap(find.byType(Link), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(Link),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      const Opacities().disabled,
    );
  });

  testWidgets('wears the swatch at the link stop, per brightness', (
    tester,
  ) async {
    await pump(
      tester,
      Link('x', swatch: SemanticSwatch.error, onPressed: () {}),
      brightness: Brightness.light,
    );
    expect(painted(tester).color, const Palette().error[600]);

    await pump(
      tester,
      Link('x', swatch: SemanticSwatch.error, onPressed: () {}),
    );
    expect(painted(tester).color, const Palette().error[400]);
  });

  testWidgets('takes the type of the role it sits in', (tester) async {
    await pump(tester, Link('x', role: TextRole.caption, onPressed: () {}));

    expect(painted(tester).fontSize, const Typography().caption.fontSize);
  });

  testWidgets('underlines under the pointer, and not at rest', (tester) async {
    await pump(tester, Link('x', onPressed: () {}));
    expect(painted(tester).decoration, TextDecoration.none);

    await hover(tester);
    expect(painted(tester).decoration, TextDecoration.underline);
    // The underline is the link's color, not the page's.
    expect(painted(tester).decorationColor, painted(tester).color);
  });

  testWidgets('brightens under the pointer', (tester) async {
    await pump(tester, Link('x', onPressed: () {}));
    final resting = painted(tester).color;

    await hover(tester);
    expect(painted(tester).color, isNot(resting));
    expect(painted(tester).color, const Palette().primary[300]);
  });

  testWidgets('LinkUnderline.always underlines at rest', (tester) async {
    await pump(
      tester,
      Link('x', underline: LinkUnderline.always, onPressed: () {}),
    );

    expect(painted(tester).decoration, TextDecoration.underline);
  });

  testWidgets('LinkUnderline.never stays bare under the pointer', (
    tester,
  ) async {
    await pump(
      tester,
      Link('x', underline: LinkUnderline.never, onPressed: () {}),
    );
    await hover(tester);

    expect(painted(tester).decoration, TextDecoration.none);
  });

  testWidgets('an external link carries the glyph', (tester) async {
    await pump(tester, Link('x', external: true, onPressed: () {}));
    expect(find.byIcon(const Icons().externalLink), findsOneWidget);

    await pump(tester, Link('x', onPressed: () {}));
    expect(find.byIcon(const Icons().externalLink), findsNothing);
  });

  testWidgets('announces itself as a link', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, Link('the manifest', onPressed: () {}));

    expect(
      tester.getSemantics(find.byType(Link)),
      matchesSemantics(
        label: 'the manifest',
        isLink: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });
}
