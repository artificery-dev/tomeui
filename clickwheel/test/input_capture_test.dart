import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

/// The player has one wheel and everything wants it, so a capture takes
/// some of its words for a while and leaves the rest alone: a slider on a
/// list's row moves on the jog while the volume keys still work, and the
/// list is driving again the moment the capture lets go.
void main() {
  /// A capture inside a list, the way a settings row sits in one.
  ///
  /// [captures] and [releaseOn] are the widget's own; everything the
  /// capture does not answer falls through to the list (which walks its
  /// rows) and to [ClickWheelInput]'s own defaults above it (which are the
  /// player's media and volume ears).
  Future<ClickWheelController> pump(
    WidgetTester tester, {
    required bool active,
    Set<WheelInput> captures = const {WheelInput.wheel},
    Set<WheelInput> releaseOn = const {WheelInput.select, WheelInput.menu},
    required List<String> captured,
    required List<String> released,
    required List<String> passedThrough,
    int capturedRow = 1,
    ClickWheelController? controller,
  }) async {
    // The same controller across a re-pump: a new one would leave the old
    // one talking to an input that has let go of it.
    final wheel = controller ?? ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ClickWheelInput(
          controller: wheel,
          onMedia: (command) => passedThrough.add('media ${command.name}'),
          onVolume: (direction) => passedThrough.add('volume $direction'),
          child: child!,
        ),
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 300,
            width: 200,
            child: WheelList(
              itemExtent: 40,
              autofocus: true,
              onActivate: (index) => passedThrough.add('activate $index'),
              children: [
                for (var i = 0; i < 4; i++)
                  i == capturedRow
                      ? InputCapture(
                          active: active,
                          captures: captures,
                          releaseOn: releaseOn,
                          onCapture: (intent) => captured.add(switch (intent) {
                            JogIntent(:final amount) => 'jog $amount',
                            MediaIntent(:final command, :final held) =>
                              'media ${command.name}${held ? ' held' : ''}',
                            VolumeIntent(:final direction) =>
                              'volume $direction',
                            ActivateIntent() => 'select',
                            ActivateHoldIntent() => 'select held',
                            WheelBackIntent() => 'menu',
                            _ => 'other',
                          }),
                          onRelease: (by) => released.add(by.name),
                          child: Text('Row $i', key: ValueKey('row.$i')),
                        )
                      : Text('Row $i', key: ValueKey('row.$i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return wheel;
  }

  /// Which row the list has landed on, read off the list's own dress.
  int selectedRow(WidgetTester tester) {
    final list = tester.widget<WheelList>(find.byType(WheelList));
    // The list keeps its index privately; the scroll offset and the
    // dressing are what it shows. Reading the dress is the honest test:
    // find the row whose ancestor DecoratedBox is the selection wash.
    for (var i = 0; i < list.itemCount; i++) {
      final row = find.byKey(ValueKey('row.$i'));
      if (row.evaluate().isEmpty) continue;
      final dressed = find.ancestor(
        of: row,
        matching: find.byType(DecoratedBox),
      );
      if (dressed.evaluate().isNotEmpty) return i;
    }
    return -1;
  }

  group('while it is active', () {
    testWidgets('the words it asked for come to it, and the list stays '
        'still', (tester) async {
      final captured = <String>[];
      final released = <String>[];
      final through = <String>[];
      final wheel = await pump(
        tester,
        active: true,
        captured: captured,
        released: released,
        passedThrough: through,
      );

      wheel.jog(2);
      await tester.pump();
      expect(captured, ['jog 2']);
      expect(
        selectedRow(tester),
        0,
        reason: 'the list did not walk: the jog never reached it',
      );
    });

    testWidgets('the words it did not ask for carry on up to the player', (
      tester,
    ) async {
      final captured = <String>[];
      final released = <String>[];
      final through = <String>[];
      final wheel = await pump(
        tester,
        active: true,
        captured: captured,
        released: released,
        passedThrough: through,
      );

      wheel.press(WheelButton.volumeUp);
      wheel.press(WheelButton.playPause);
      await tester.pump();
      expect(through, ['volume 1', 'media toggle']);
      expect(captured, isEmpty, reason: 'it only asked for the wheel');
    });

    testWidgets('a capture can take the skip keys and leave play alone, '
        'though both arrive as one intent', (tester) async {
      final captured = <String>[];
      final released = <String>[];
      final through = <String>[];
      final wheel = await pump(
        tester,
        active: true,
        captures: const {WheelInput.skip},
        captured: captured,
        released: released,
        passedThrough: through,
      );

      wheel.press(WheelButton.next);
      wheel.press(WheelButton.previous);
      wheel.press(WheelButton.playPause);
      await tester.pump();
      expect(captured, ['media next', 'media previous']);
      expect(through, ['media toggle']);
    });

    testWidgets('a held media button keeps its long word', (tester) async {
      final captured = <String>[];
      final released = <String>[];
      final through = <String>[];
      final wheel = await pump(
        tester,
        active: true,
        captures: const {WheelInput.skip},
        captured: captured,
        released: released,
        passedThrough: through,
      );

      wheel.hold(WheelButton.next);
      await tester.pump();
      expect(captured, ['media next held']);
    });
  });

  group('ending it', () {
    testWidgets('the center button and menu release it, and say which', (
      tester,
    ) async {
      final captured = <String>[];
      final released = <String>[];
      final through = <String>[];
      final wheel = await pump(
        tester,
        active: true,
        captured: captured,
        released: released,
        passedThrough: through,
      );

      wheel.press(WheelButton.select);
      await tester.pump();
      expect(released, ['select']);
      expect(
        through,
        isEmpty,
        reason: 'the release is not also an activation of the row',
      );

      wheel.press(WheelButton.menu);
      await tester.pump();
      expect(released, ['select', 'menu']);
    });

    testWidgets('a word in both sets is taken, not a release', (tester) async {
      final captured = <String>[];
      final released = <String>[];
      final through = <String>[];
      final wheel = await pump(
        tester,
        active: true,
        captures: const {WheelInput.wheel, WheelInput.select},
        captured: captured,
        released: released,
        passedThrough: through,
      );

      wheel.press(WheelButton.select);
      await tester.pump();
      expect(captured, ['select']);
      expect(released, isEmpty);
    });

    testWidgets('the list is driving again once the capture lets go', (
      tester,
    ) async {
      final captured = <String>[];
      final released = <String>[];
      final through = <String>[];
      final wheel = await pump(
        tester,
        active: true,
        captured: captured,
        released: released,
        passedThrough: through,
      );

      wheel.jog(1);
      await tester.pump();
      expect(captured, ['jog 1']);

      // The owner takes the capture away, as a screen would on the release.
      await pump(
        tester,
        active: false,
        captured: captured,
        released: released,
        passedThrough: through,
        controller: wheel,
      );
      wheel.jog(2);
      await tester.pumpAndSettle();

      expect(captured, ['jog 1'], reason: 'nothing more came to it');
      expect(selectedRow(tester), 2, reason: 'the list walked instead');
    });
  });

  group('while it is inactive', () {
    testWidgets('it is not in the way at all', (tester) async {
      final captured = <String>[];
      final released = <String>[];
      final through = <String>[];
      final wheel = await pump(
        tester,
        active: false,
        captured: captured,
        released: released,
        passedThrough: through,
      );

      wheel.jog(1);
      await tester.pumpAndSettle();
      expect(captured, isEmpty);
      expect(selectedRow(tester), 1);

      // Even sitting on the capture's own row, the center activates the
      // row rather than being eaten.
      wheel.press(WheelButton.select);
      await tester.pump();
      expect(through, ['activate 1']);
      expect(released, isEmpty);
    });
  });
}
