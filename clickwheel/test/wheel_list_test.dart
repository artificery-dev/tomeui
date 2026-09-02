import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

/// The rubber band past a list's ends and the scrollbar beside them
/// belong to lists that scroll: a list that fits on the screen is simply
/// at its end, stays still, and wears no bar.
void main() {
  Future<ClickWheelController> pumpList(
    WidgetTester tester, {
    required int rows,
  }) async {
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            ClickWheelInput(controller: wheel, child: child!),
        home: SizedBox(
          height: 300,
          child: WheelList(
            itemExtent: 40,
            autofocus: true,
            children: [for (var i = 0; i < rows; i++) Text('Row $i')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return wheel;
  }

  double pull(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(WheelList),
            matching: find.byType(Transform),
          )
          .first,
    );
    return transform.transform.getTranslation().y;
  }

  testWidgets('a list that fits does not stretch past its ends', (
    tester,
  ) async {
    final wheel = await pumpList(tester, rows: 3);
    wheel.jog(-2);
    await tester.pump();
    expect(pull(tester), 0);
    wheel.jog(6);
    await tester.pump();
    expect(pull(tester), 0);
  });

  testWidgets('a list longer than the screen stretches, and lets go', (
    tester,
  ) async {
    final wheel = await pumpList(tester, rows: 40);
    wheel.jog(-2);
    await tester.pump();
    expect(pull(tester), greaterThan(0), reason: 'pulled past the top');
    // The wheel goes still, the band lets go and springs home.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(pull(tester).abs(), lessThan(0.5), reason: 'let go');
  });

  testWidgets('a list that scrolls wears a scrollbar with a track and a '
      'thumb no shorter than a row; one that fits wears none', (tester) async {
    await pumpList(tester, rows: 3);
    expect(find.byType(RawScrollbar), findsNothing);

    await pumpList(tester, rows: 40);
    final bar = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
    expect(bar.thumbVisibility, isTrue);
    expect(bar.trackVisibility, isTrue);
    expect(bar.minThumbLength, 40);
  });
}
