import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

/// The rail is heavy: a weight of detents lies between options, and the
/// same weight carries the box off an end and lets go. What is checked is
/// the arithmetic of that weight - where the box is part way, that the
/// option clicks over as the box's centre crosses the line and not before,
/// that resting settles the box onto the side it is on, that the give caps
/// how far out it goes - and that the rail only ever speaks for the wheel
/// and the centre.
void main() {
  const options = ['left', 'middle', 'right'];

  /// Light, so a test can turn a whole weight in one line.
  const light = WheelRailPhysics(weight: 4, give: 10);

  late ClickWheelController wheel;
  late List<String> changes;
  late List<int> releases;
  late List<String> activations;
  late List<MediaCommand> media;
  late int backs;

  Future<void> pumpRail(
    WidgetTester tester, {
    WheelRailPhysics physics = light,
    String? initial = 'left',
    bool releasable = true,
  }) async {
    wheel = ClickWheelController();
    changes = [];
    releases = [];
    activations = [];
    media = [];
    backs = 0;
    var value = initial;
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ClickWheelInput(
          controller: wheel,
          child: Actions(
            // Whatever the rail does not answer to comes up here.
            actions: {
              MediaIntent: CallbackAction<MediaIntent>(
                onInvoke: (intent) => media.add(intent.command),
              ),
              WheelBackIntent: CallbackAction<WheelBackIntent>(
                onInvoke: (_) => backs++,
              ),
            },
            child: child!,
          ),
        ),
        home: StatefulBuilder(
          builder: (context, setState) => Center(
            child: SizedBox(
              width: 200,
              child: WheelRail<String>(
                value: value,
                autofocus: true,
                physics: physics,
                onChanged: (next) {
                  changes.add(next);
                  setState(() => value = next);
                },
                onActivate: activations.add,
                onRelease: releasable ? releases.add : null,
                segments: [
                  for (final option in options)
                    SegmentOption(value: option, label: Text(option)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> jog(
    WidgetTester tester,
    int detents, {
    bool page = false,
  }) async {
    wheel.jog(detents, page: page);
    await tester.pump();
  }

  /// Where the box is along the track: -1 is flush left, +1 flush right.
  double boxAlignment(WidgetTester tester) => tester
      .widget<FractionallySizedBox>(
        find.descendant(
          of: find.byType(WheelRail<String>),
          matching: find.byType(FractionallySizedBox),
        ),
      )
      .alignment
      .resolve(TextDirection.ltr)
      .x;

  /// How far the box is out past the track, in pixels.
  double boxOffset(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byType(WheelRail<String>),
          matching: find.byType(Transform),
        ),
      )
      .transform
      .getTranslation()
      .x;

  testWidgets('an option is a whole weight away, and clicks over half way', (
    tester,
  ) async {
    await pumpRail(tester);
    expect(boxAlignment(tester), -1);

    await jog(tester, 1);
    await jog(tester, 1);
    expect(changes, isEmpty, reason: 'on the line, not over it');
    expect(boxAlignment(tester), -0.5, reason: 'half way to the middle');
    await jog(tester, 1);
    expect(changes, ['middle'], reason: 'the centre crossed the line');
    expect(
      boxAlignment(tester),
      -0.25,
      reason: 'and the box is still on its way',
    );
    await jog(tester, 1);
    expect(changes, ['middle']);
    expect(boxAlignment(tester), 0, reason: 'arrived');

    // A whole weight in one turn is one option; two weights, two.
    await jog(tester, 4);
    expect(changes, ['middle', 'right']);
    await jog(tester, -8);
    expect(changes, ['middle', 'right', 'left']);
    expect(releases, isEmpty);
  });

  testWidgets('a fast spin is one detent, whatever it says', (tester) async {
    await pumpRail(tester);
    await jog(tester, 3, page: true);
    expect(changes, isEmpty);
    expect(boxAlignment(tester), -0.75);
  });

  testWidgets('a rest settles the box onto the side it is on', (tester) async {
    await pumpRail(tester);
    // Short of the line: back to where it was, and the turn starts over.
    await jog(tester, 2);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(boxAlignment(tester), -1, reason: 'home');
    expect(changes, isEmpty);
    await jog(tester, 2);
    expect(changes, isEmpty, reason: 'two of four again, not four');
    // Just over it: the click - onto the new option, the rest of the way.
    await jog(tester, 1);
    expect(changes, ['middle']);
    expect(boxAlignment(tester), closeTo(-0.25, 1e-9));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(boxAlignment(tester), 0, reason: 'settled on the middle');
  });

  testWidgets('turning back unwinds the way, and back over the line clicks '
      'back', (tester) async {
    await pumpRail(tester, initial: 'middle');
    await jog(tester, 2);
    await jog(tester, -2);
    expect(boxAlignment(tester), 0);
    expect(changes, isEmpty);
    await jog(tester, 3);
    expect(changes, ['right']);
    // One back is on the line - the box is exactly between, and stays on
    // the side it came from; the next is over it.
    await jog(tester, -1);
    expect(changes, ['right'], reason: 'on the line');
    await jog(tester, -1);
    expect(changes, ['right', 'middle'], reason: 'back over the same line');
    await jog(tester, -4);
    expect(changes, ['right', 'middle', 'left']);
  });

  testWidgets('off an end the box goes out to the give, and the weight lets '
      'go', (tester) async {
    await pumpRail(tester, initial: 'right');

    await jog(tester, 2);
    expect(changes, isEmpty);
    expect(boxAlignment(tester), 1, reason: 'still on the last option');
    expect(boxOffset(tester), 5, reason: 'half the give of ten');
    await jog(tester, 1);
    expect(releases, isEmpty);
    await jog(tester, 1);
    expect(releases, [1]);
    await tester.pumpAndSettle();
    expect(boxOffset(tester), 0, reason: 'snapped home as it let go');

    // And off the start, the other way: two weights in one turn, reported
    // once where they land.
    await jog(tester, -8);
    expect(changes, ['left']);
    await jog(tester, -2);
    expect(boxOffset(tester), -5);
    await jog(tester, -2);
    expect(releases, [1, -1]);
    await tester.pumpAndSettle();
  });

  testWidgets('a rest part way out springs the box home', (tester) async {
    await pumpRail(tester, initial: 'right');
    await jog(tester, 3);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(boxOffset(tester), 0);
    await jog(tester, 3);
    expect(releases, isEmpty, reason: 'the turn started over');
    await jog(tester, 1);
    expect(releases, [1]);
    await tester.pumpAndSettle();
  });

  testWidgets('one long turn can cross an option and go on out', (
    tester,
  ) async {
    await pumpRail(tester, initial: 'middle');
    await jog(tester, 8);
    expect(changes, ['right']);
    expect(releases, [1]);
    await tester.pumpAndSettle();
  });

  testWidgets('the physics set the weight', (tester) async {
    await pumpRail(tester, physics: const WheelRailPhysics(weight: 1));
    await jog(tester, 1);
    expect(changes, ['middle']);
    await jog(tester, 2);
    expect(changes, ['middle', 'right']);
    expect(releases, [1]);
    await tester.pumpAndSettle();

    // The default is half a revolution of a twenty-detent wheel between
    // options, so the line is a quarter turn out.
    await pumpRail(tester, physics: const WheelRailPhysics());
    await jog(tester, 5);
    expect(changes, isEmpty, reason: 'on the line');
    await jog(tester, 1);
    expect(changes, ['middle']);
  });

  testWidgets('a rail nobody catches holds on at the give', (tester) async {
    await pumpRail(tester, initial: 'right', releasable: false);
    await jog(tester, 9);
    expect(changes, isEmpty);
    expect(releases, isEmpty);
    expect(boxOffset(tester), 10, reason: 'out to the give, and no further');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(boxOffset(tester), 0);
  });

  testWidgets('the centre activates the option under the box', (tester) async {
    await pumpRail(tester);
    wheel.press(WheelButton.select);
    await tester.pump();
    await jog(tester, 4);
    wheel.press(WheelButton.select);
    await tester.pump();
    expect(activations, ['left', 'middle']);
  });

  testWidgets('with nothing chosen the first detent lands on the near end', (
    tester,
  ) async {
    await pumpRail(tester, initial: null);
    await jog(tester, 1);
    expect(changes, ['left']);

    await pumpRail(tester, initial: null);
    await jog(tester, -1);
    expect(changes, ['right']);
  });

  testWidgets('the ring buttons and menu pass the rail by', (tester) async {
    await pumpRail(tester);
    wheel.press(WheelButton.next);
    wheel.press(WheelButton.previous);
    wheel.press(WheelButton.playPause);
    wheel.press(WheelButton.menu);
    await tester.pump();
    expect(media, [
      MediaCommand.next,
      MediaCommand.previous,
      MediaCommand.toggle,
    ]);
    expect(backs, 1);
    expect(changes, isEmpty);
  });
}
