import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';

void main() {
  const theme = Theme();
  final style = theme.widgets.segmented.resolve();

  const watches = ['Morning', 'Forenoon', 'Dog'];

  Future<void> pump(WidgetTester tester, Widget control) async {
    await tester.pumpWidget(TomeApp(home: Center(child: control)));
    await tester.pumpAndSettle();
  }

  SegmentedControl<String> control({
    String? value = 'Morning',
    ValueChanged<String>? onChanged,
    List<String> disabled = const [],
  }) => SegmentedControl<String>(
    value: value,
    onChanged: onChanged ?? (_) {},
    segments: [
      for (final watch in watches)
        SegmentOption(
          value: watch,
          label: Text(watch),
          enabled: !disabled.contains(watch),
        ),
    ],
  );

  /// The indicator itself — the child of the fractional box, since the box
  /// fills the track and only sizes what's inside it.
  Finder indicator() => find.descendant(
    of: find.byType(FractionallySizedBox),
    matching: find.byType(Surface),
  );

  testWidgets('every segment is the width of the widest', (tester) async {
    await pump(tester, control());

    final widths = {
      for (final watch in watches)
        watch: tester
            .getSize(
              find
                  .ancestor(
                    of: find.text(watch),
                    matching: find.byType(Surface),
                  )
                  .first,
            )
            .width,
    };
    // One distance for the indicator to travel, and no reflow when the
    // answer changes.
    expect(widths.values.toSet(), hasLength(1));
  });

  testWidgets('the indicator is one segment wide and sits on the answer', (
    tester,
  ) async {
    await pump(tester, control(value: 'Forenoon'));

    final box = tester.getRect(indicator());
    final segment = tester.getRect(
      find
          .ancestor(of: find.text('Forenoon'), matching: find.byType(Surface))
          .first,
    );
    expect(box.width, moreOrLessEquals(segment.width, epsilon: 0.5));
    expect(box.center.dx, moreOrLessEquals(segment.center.dx, epsilon: 0.5));
  });

  testWidgets('the indicator travels to the end segments too', (tester) async {
    for (final watch in watches) {
      await pump(tester, control(value: watch));
      final box = tester.getRect(indicator());
      final segment = tester.getRect(
        find
            .ancestor(of: find.text(watch), matching: find.byType(Surface))
            .first,
      );
      expect(
        box.center.dx,
        moreOrLessEquals(segment.center.dx, epsilon: 0.5),
        reason: 'indicator missed $watch',
      );
    }
  });

  testWidgets('a null value shows no indicator', (tester) async {
    await pump(tester, control(value: null));
    expect(indicator(), findsNothing);
  });

  testWidgets('tapping a segment reports it', (tester) async {
    String? chosen;
    await pump(tester, control(onChanged: (value) => chosen = value));

    await tester.tap(find.text('Dog'));
    await tester.pump();
    expect(chosen, 'Dog');
  });

  testWidgets('tapping the answer again reports nothing', (tester) async {
    var calls = 0;
    await pump(tester, control(onChanged: (_) => calls++));

    await tester.tap(find.text('Morning'));
    await tester.pump();
    // Something has to be the answer, so re-choosing it is not a change.
    expect(calls, 0);
  });

  testWidgets('a disabled segment cannot be tapped or landed on', (
    tester,
  ) async {
    String? chosen;
    await pump(
      tester,
      control(
        onChanged: (value) => chosen = value,
        disabled: const ['Forenoon'],
      ),
    );

    await tester.tap(find.text('Forenoon'));
    await tester.pump();
    expect(chosen, isNull);
  });

  testWidgets('the arrows move the answer, stepping over disabled segments', (
    tester,
  ) async {
    String? value = 'Morning';
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SegmentedControl<String>(
          value: value,
          onChanged: (next) => setState(() => value = next),
          segments: [
            for (final watch in watches)
              SegmentOption(
                value: watch,
                label: Text(watch),
                enabled: watch != 'Forenoon',
              ),
          ],
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 'Dog', reason: 'Forenoon is disabled and gets stepped over');

    // The row does not wrap: falling off a control you can see all of
    // would only surprise.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 'Dog');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value, 'Morning');
  });

  testWidgets('Home and End take the first and last landable segments', (
    tester,
  ) async {
    String? value = 'Forenoon';
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SegmentedControl<String>(
          value: value,
          onChanged: (next) => setState(() => value = next),
          segments: [
            for (final watch in watches)
              SegmentOption(
                value: watch,
                label: Text(watch),
                enabled: watch != 'Dog',
              ),
          ],
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(value, 'Forenoon', reason: 'Dog is disabled, so it is not the end');

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(value, 'Morning');
  });

  testWidgets('a null onChanged disables the whole control', (tester) async {
    await pump(
      tester,
      SegmentedControl<String>(
        value: 'Morning',
        onChanged: null,
        segments: [
          for (final watch in watches)
            SegmentOption(value: watch, label: Text(watch)),
        ],
      ),
    );

    final opacity = tester
        .widgetList<AnimatedOpacity>(
          find.descendant(
            of: find.byType(SegmentedControl<String>),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .first;
    expect(opacity.opacity, style.disabledOpacity);
  });

  testWidgets('the chosen segment reads against the indicator', (tester) async {
    await pump(tester, control(value: 'Morning'));

    TextStyle styleOf(String label) => tester
        .widget<AnimatedDefaultTextStyle>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedDefaultTextStyle),
              )
              .first,
        )
        .style;

    expect(styleOf('Morning').color, style.selectedStyle.color);
    expect(styleOf('Dog').color, style.unselectedStyle.color);
  });

  testWidgets('each segment says it is one of several', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, control(value: 'Morning'));

    expect(
      tester.getSemantics(find.text('Morning')),
      isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
    );
    expect(
      tester.getSemantics(find.text('Dog')),
      isSemantics(isSelected: false, isInMutuallyExclusiveGroup: true),
    );
    handle.dispose();
  });
}
