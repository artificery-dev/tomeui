import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

/// The wheel's keys arrive twice unless somebody stops them: once at
/// [ClickWheelInput]'s global ear, and once more down the focus chain, where
/// [WidgetsApp]'s default shortcuts turn Enter into a second [ActivateIntent]
/// and the arrows into focus moves. On the player that doubled every
/// activation - two pushes of each screen, so two presses of back to leave
/// it - so the test presses the real keys, not the controller.
void main() {
  Future<int Function()> pumpMenu(WidgetTester tester) async {
    var activations = 0;
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ClickWheelInput(child: child!),
        home: WheelList(
          itemExtent: 40,
          autofocus: true,
          onActivate: (_) => activations++,
          children: const [Text('one'), Text('two'), Text('three')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => activations;
  }

  testWidgets('a physical select press activates exactly once', (tester) async {
    final activations = await pumpMenu(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activations(), 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(activations(), 2);
  });

  testWidgets('a physical jog moves the selection by one detent', (
    tester,
  ) async {
    await pumpMenu(tester);

    // The fixed shape dresses the selected row in the primary's subtle
    // wash; an unselected row sits on the page.
    bool selected(String label) {
      final wash = ThemeProvider.of(tester.element(find.text(label)))
          .widgets
          .surface
          .resolve(SemanticSwatch.primary, SurfaceVariant.subtle)
          .fill;
      return find
          .ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is DecoratedBox &&
                  (widget.decoration as BoxDecoration).color == wash,
            ),
          )
          .evaluate()
          .isNotEmpty;
    }

    expect(selected('one'), isTrue);
    expect(selected('two'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(selected('one'), isFalse);
    expect(selected('two'), isTrue);
    expect(selected('three'), isFalse, reason: 'one detent, one row');
  });

  testWidgets('the controller speaks the same grammar, once', (tester) async {
    var activations = 0;
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            ClickWheelInput(controller: wheel, child: child!),
        home: WheelList(
          itemExtent: 40,
          autofocus: true,
          onActivate: (_) => activations++,
          children: const [Text('one'), Text('two')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(wheel.attached, isTrue);

    wheel.press(WheelButton.select);
    await tester.pumpAndSettle();
    expect(activations, 1);
  });

  mutedTests();
  asleepTests();
  holdTests();
}

/// Asleep, the wheel is silent, the center and menu only wake, and the
/// media buttons still speak.
void asleepTests() {
  testWidgets('asleep: jog and menu say nothing, select wakes, media and '
      'volume speak', (tester) async {
    var activations = 0;
    var wakes = 0;
    var backs = 0;
    var holds = 0;
    final media = <MediaCommand>[];
    final volume = <int>[];
    final words = <WheelWord>[];
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ClickWheelInput(
          controller: wheel,
          asleep: true,
          onWake: () => wakes++,
          onMedia: media.add,
          onVolume: volume.add,
          onWord: words.add,
          onMenuHold: () => holds++,
          child: Actions(
            actions: {
              WheelBackIntent: CallbackAction<WheelBackIntent>(
                onInvoke: (_) => backs++,
              ),
            },
            child: child!,
          ),
        ),
        home: WheelList(
          itemExtent: 40,
          autofocus: true,
          onActivate: (_) => activations++,
          children: const [Text('one'), Text('two')],
        ),
      ),
    );

    wheel.jog(1);
    await tester.pump();
    wheel.press(WheelButton.select);
    wheel.hold(WheelButton.select);
    wheel.press(WheelButton.menu);
    await tester.pump();
    expect(activations, 0);
    expect(backs, 0);
    expect(wakes, 2, reason: 'the center and its hold wake; menu does not');
    expect(words, everyElement(WheelWord.press));

    wheel.menuDown();
    await tester.pump(const Duration(milliseconds: 1600));
    wheel.menuUp();
    await tester.pump();
    expect(holds, 0, reason: 'no dock over a dark screen');
    expect(backs, 0, reason: 'and no back on the release either');

    wheel.press(WheelButton.playPause);
    wheel.press(WheelButton.next);
    wheel.press(WheelButton.volumeUp);
    await tester.pump();
    expect(media, [MediaCommand.toggle, MediaCommand.next]);
    expect(volume, [1]);
    expect(wakes, 2, reason: 'none of those woke it');
  });
}

/// Muted, the wheel is claimed but silent - and the power chord is not.
void mutedTests() {
  testWidgets('menu is back on release, and a hold is its own word', (
    tester,
  ) async {
    var backs = 0;
    var holds = 0;
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ClickWheelInput(
          controller: wheel,
          onMenuHold: () => holds++,
          child: Actions(
            actions: {
              WheelBackIntent: CallbackAction<WheelBackIntent>(
                onInvoke: (_) => backs++,
              ),
            },
            child: child!,
          ),
        ),
        home: const Focus(autofocus: true, child: SizedBox.expand()),
      ),
    );
    await tester.pumpAndSettle();

    // A press: nothing on the way down, back on the way up.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(backs, 0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(backs, 1);

    // A hold: the hold at the threshold, and no back on release.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(holds, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(backs, 1);

    // The controller's hand does the same.
    wheel.menuDown();
    await tester.pump();
    wheel.menuUp();
    await tester.pump();
    expect(backs, 2);
    wheel.menuDown();
    await tester.pump(const Duration(milliseconds: 1600));
    wheel.menuUp();
    await tester.pump();
    expect(holds, 2);
    expect(backs, 2);
    // And the short form is still the short form.
    wheel.press(WheelButton.menu);
    await tester.pump();
    expect(backs, 3);
  });

  testWidgets('a muted wheel says nothing but power', (tester) async {
    var activations = 0;
    final presses = <PowerPress>[];
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ClickWheelInput(
          controller: wheel,
          muted: true,
          onPower: presses.add,
          child: child!,
        ),
        home: WheelList(
          itemExtent: 40,
          autofocus: true,
          onActivate: (_) => activations++,
          children: const [Text('one'), Text('two')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Both mouths: the real key and the controller.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    wheel.press(WheelButton.select);
    wheel.jog(1);
    await tester.pumpAndSettle();
    expect(activations, 0);

    wheel.powerDown();
    await tester.pump(const Duration(milliseconds: 50));
    wheel.powerUp();
    await tester.pump(const Duration(milliseconds: 400));
    expect(presses, [isA<PowerTaps>().having((p) => p.taps, 'taps', 1)]);
  });
}

/// Every button of the ring has two words: the short one on a release in
/// time, the long one at the threshold - and never both. The volume keys
/// have one word that repeats while held.
void holdTests() {
  Future<ClickWheelController> pumpRing(
    WidgetTester tester, {
    required void Function(Intent) heard,
    void Function(MediaCommand)? onMedia,
    void Function(MediaCommand)? onMediaHold,
  }) async {
    final wheel = ClickWheelController();
    await tester.pumpWidget(
      TomeApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ClickWheelInput(
          controller: wheel,
          onMedia: onMedia,
          onMediaHold: onMediaHold,
          onVolume: (d) => heard(VolumeIntent(d)),
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (i) => heard(i),
              ),
              ActivateHoldIntent: CallbackAction<ActivateHoldIntent>(
                onInvoke: (i) => heard(i),
              ),
              // Only when no ear is given: an action here would sit
              // nearer the focus than the input's own and take the word.
              if (onMedia == null && onMediaHold == null)
                MediaIntent: CallbackAction<MediaIntent>(
                  onInvoke: (i) => heard(i),
                ),
            },
            child: child!,
          ),
        ),
        home: const Focus(autofocus: true, child: SizedBox.expand()),
      ),
    );
    await tester.pumpAndSettle();
    return wheel;
  }

  testWidgets('the center: a press on release, a hold at the threshold', (
    tester,
  ) async {
    final heard = <Intent>[];
    final wheel = await pumpRing(tester, heard: heard.add);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 100));
    expect(heard, isEmpty, reason: 'nothing on the way down');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(heard, [isA<ActivateIntent>()]);

    heard.clear();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 700));
    expect(heard, [isA<ActivateHoldIntent>()], reason: 'the hold speaks');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(heard.length, 1, reason: 'and the release says nothing more');

    // The controller's hands: the words without the wait, and with it.
    heard.clear();
    wheel.press(WheelButton.select);
    wheel.hold(WheelButton.select);
    await tester.pump();
    expect(heard, [isA<ActivateIntent>(), isA<ActivateHoldIntent>()]);
    heard.clear();
    wheel.buttonDown(WheelButton.select);
    await tester.pump(const Duration(milliseconds: 700));
    wheel.buttonUp(WheelButton.select);
    await tester.pump();
    expect(heard, [isA<ActivateHoldIntent>()]);
  });

  testWidgets('media buttons carry the hold, and the ears tell them apart', (
    tester,
  ) async {
    final pressed = <MediaCommand>[];
    final held = <MediaCommand>[];
    final wheel = await pumpRing(
      tester,
      heard: (_) {},
      onMedia: pressed.add,
      onMediaHold: held.add,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlayPause);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlayPause);
    await tester.pump();
    expect(held, [MediaCommand.toggle]);
    expect(pressed, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(pressed, [MediaCommand.next]);

    // A repeat while down is the key still down, not a second press.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(pressed, [MediaCommand.next, MediaCommand.previous]);

    wheel.hold(WheelButton.next);
    await tester.pump();
    expect(held, [MediaCommand.toggle, MediaCommand.next]);
  });

  testWidgets('a volume key speaks on the way down and repeats while held', (
    tester,
  ) async {
    final heard = <Intent>[];
    final wheel = await pumpRing(tester, heard: heard.add);

    wheel.buttonDown(WheelButton.volumeUp);
    await tester.pump();
    expect(heard.length, 1, reason: 'at once');
    await tester.pump(const Duration(milliseconds: 500));
    expect(heard.length, 1, reason: 'not yet held');
    await tester.pump(const Duration(milliseconds: 400));
    expect(heard.length, greaterThan(1), reason: 'held, it repeats');
    final whileHeld = heard.length;
    wheel.buttonUp(WheelButton.volumeUp);
    await tester.pump(const Duration(milliseconds: 500));
    expect(heard.length, whileHeld, reason: 'let go, it stops');
    expect(heard.every((i) => i is VolumeIntent && i.direction == 1), isTrue);

    // The real key: down speaks at once, the hardware's repeats (if any)
    // are the key still down, and the hold repeats on the input's own
    // clock - not every host repeats a held key.
    heard.clear();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.audioVolumeDown);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.audioVolumeDown);
    await tester.pump();
    expect(heard.length, 1);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(heard.length, greaterThan(2));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.audioVolumeDown);
    final released = heard.length;
    await tester.pump(const Duration(milliseconds: 500));
    expect(heard.length, released);
  });
}
