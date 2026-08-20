import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  /// An app with a toaster over it, and a context under it to speak from.
  Future<BuildContext> pumpToaster(
    WidgetTester tester, {
    ToastStyle? style,
  }) async {
    late BuildContext page;
    await tester.pumpWidget(
      TomeApp(
        home: Toaster(
          style: style,
          child: Builder(
            builder: (context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return page;
  }

  testWidgets('what is said shows, and takes itself away', (tester) async {
    final context = await pumpToaster(tester);

    showToast(context, message: const Text('Manifest signed'));
    await tester.pumpAndSettle();
    expect(find.text('Manifest signed'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Manifest signed'), findsNothing);
  });

  testWidgets('the close button takes it away early', (tester) async {
    final context = await pumpToaster(tester);

    showToast(context, message: const Text('Saved'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(const Icons().close));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('and so does the handle it hands back', (tester) async {
    final context = await pumpToaster(tester);

    final dismiss = showToast(context, message: const Text('Uploading'));
    await tester.pumpAndSettle();
    expect(find.text('Uploading'), findsOneWidget);

    dismiss();
    await tester.pumpAndSettle();
    expect(find.text('Uploading'), findsNothing);
  });

  testWidgets('past the most it shows at once, the rest wait their turn', (
    tester,
  ) async {
    final context = await pumpToaster(tester);

    for (var i = 1; i <= 4; i++) {
      showToast(context, message: Text('toast $i'));
    }
    await tester.pumpAndSettle();

    for (final showing in ['toast 1', 'toast 2', 'toast 3']) {
      expect(find.text(showing), findsOneWidget, reason: showing);
    }
    expect(find.text('toast 4'), findsNothing, reason: 'queued');

    // As the first goes, the queued one takes its place.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('toast 1'), findsNothing);
    expect(find.text('toast 4'), findsOneWidget);
  });

  testWidgets('a toast being read stays put', (tester) async {
    final context = await pumpToaster(tester);

    showToast(context, message: const Text('Read me'));
    await tester.pumpAndSettle();

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.text('Read me'))),
    );
    await tester.pump();

    // Long past its life, and still there because the pointer is on it.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Read me'), findsOneWidget);

    // The pointer leaves and the clock starts again.
    await tester.sendEventToBinding(pointer.hover(const Offset(5, 5)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Read me'), findsNothing);
  });

  testWidgets('one with something to do about it stays longer', (
    tester,
  ) async {
    final context = await pumpToaster(tester);
    var undone = 0;

    showToast(
      context,
      message: const Text('Manifest deleted'),
      swatch: SemanticSwatch.error,
      action: (context, dismiss) => Button(
        onPressed: () {
          undone++;
          dismiss();
        },
        variant: SurfaceVariant.ghost,
        center: const Text('Undo'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget, reason: 'still offered');

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('Manifest deleted'), findsNothing);
  });

  testWidgets('the swatch colours the glyph, not the card', (tester) async {
    final context = await pumpToaster(tester);

    showToast(
      context,
      message: const Text('Went wrong'),
      swatch: SemanticSwatch.error,
    );
    await tester.pumpAndSettle();

    const theme = Theme();
    final icon = tester.widget<Icon>(find.byIcon(const Icons().error));
    expect(
      icon.color,
      theme.widgets.surface
          .resolve(SemanticSwatch.error, SurfaceVariant.solid)
          .fill,
    );
    // The card first; the close button has a surface of its own.
    final surface = tester.widget<Surface>(
      find
          .descendant(of: find.byType(Toast), matching: find.byType(Surface))
          .first,
    );
    expect(
      surface.style!.fill,
      theme.widgets.toast.resolve().surface.fill,
      reason: 'the card stays the card',
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('a neutral toast has no glyph to colour', (tester) async {
    final context = await pumpToaster(tester);

    showToast(context, message: const Text('Just so you know'));
    await tester.pumpAndSettle();

    expect(find.byIcon(const Icons().info), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('the stack sits where the style says', (tester) async {
    const style = ToastStyle(
      surface: SurfaceStyle(foreground: Color(0xFF000000)),
      messageStyle: TextStyle(),
      position: ToastPosition.topCenter,
    );
    final context = await pumpToaster(tester, style: style);

    showToast(context, message: const Text('Up top'));
    await tester.pumpAndSettle();

    final toast = tester.getRect(find.byType(Toast));
    final screen = tester.getRect(find.byType(TomeApp));
    expect(toast.top, lessThan(screen.height / 2));
    expect(
      toast.center.dx,
      moreOrLessEquals(screen.center.dx, epsilon: 1),
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
