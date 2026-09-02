import 'dart:async';

import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import 'intents.dart';

/// What the power button did. Taps are counted within a short window -
/// [PowerPress.taps] is 1, 2, 3... - and a hold is its own word.
sealed class PowerPress {
  const PowerPress();
}

class PowerTaps extends PowerPress {
  const PowerTaps(this.taps);

  final int taps;
}

class PowerHold extends PowerPress {
  const PowerHold();
}

/// The ring's five buttons and the pair on the side: everything on the
/// device that is pressed rather than turned.
enum WheelButton {
  /// The ring's top: back, one screen at a time.
  menu,

  /// The middle of the wheel: enter, choose, play.
  select,

  /// The ring's left and right.
  previous,
  next,

  /// The ring's bottom.
  playPause,

  volumeUp,
  volumeDown,
}

/// A hand on the hardware: what the wheel and the ring do, done by hand.
///
/// The device needs none of this - its keys arrive on their own - but an
/// emulator drawing a wheel does, and so does a test. Hand one to a
/// [ClickWheelInput] and it becomes that input's second mouth, speaking the
/// same grammar down the same path:
///
/// ```dart
/// final wheel = ClickWheelController();
/// ...
/// ClickWheelInput(controller: wheel, child: child)
/// ...
/// onTap: () => wheel.press(WheelButton.select),
/// ```
class ClickWheelController {
  _ClickWheelInputState? _input;

  /// Whether a [ClickWheelInput] is listening. Presses go nowhere until one
  /// is mounted.
  bool get attached => _input != null;

  /// Turn the wheel: negative is up the list, positive is down. [page] is
  /// the fast tier the hardware reports when the wheel is spun hard.
  void jog(int detents, {bool page = false}) =>
      _input?._dispatch(JogIntent(detents, page: page));

  /// Press and release one of the buttons: its short word, said at once.
  void press(WheelButton button) =>
      _input?._dispatch(_ClickWheelInputState._short(button));

  /// Hold one of the buttons past its threshold: its long word, said at
  /// once. The volume keys have no long word - held, they repeat - so a
  /// hold of those is one press.
  void hold(WheelButton button) =>
      _input?._dispatch(_ClickWheelInputState._long(button));

  /// A button going down and coming back up, for a hand that wants the
  /// timing to be real: the short word comes on a release in time, the
  /// long word at the threshold, a volume key repeats while down. [press]
  /// and [hold] are the same two words said without the wait.
  void buttonDown(WheelButton button) => _input?._button(button, down: true);

  void buttonUp(WheelButton button) => _input?._button(button, down: false);

  /// The power button, going down and coming back up. Taps and holds are
  /// counted from these two exactly as they are from the real key, so a
  /// hold has to be held.
  void powerDown() => _input?._power(down: true);

  void powerUp() => _input?._power(down: false);

  /// The menu button as a key going down and coming up, for the hold: a
  /// short press is back on release, a hold is [ClickWheelInput.onMenuHold].
  /// [press] with [WheelButton.menu] is the short press said at once.
  void menuDown() => _input?._menu(down: true);

  void menuUp() => _input?._menu(down: false);
}

/// The whole device, spoken into Flutter: install once around the app's
/// home (inside the router, so Back can pop it).
///
/// ```dart
/// TomeApp(
///   builder: (context, child) => ClickWheelInput(
///     onMedia: player.handle,
///     onPower: power.handle,
///     child: child!,
///   ),
///   home: const HomeScreen(),
/// )
/// ```
///
/// Keys are matched on their *physical* identity (the evdev scancode's HID
/// translation), so the mapping holds no matter what the console keymap
/// thinks a "menu" key means. What arrives becomes intents:
///
///  * wheel detents -> [JogIntent] (fast-spin tier -> page jogs). The
///    default action walks widget focus; a [WheelList] in focus overrides
///    it and moves its own selection instead.
///  * centre -> [ActivateIntent] on a press, [ActivateHoldIntent] on a
///    hold past [longPress], to whatever holds focus.
///  * menu -> [WheelBackIntent] on a press; a hold is [onMenuHold].
///  * prev / next / play-pause -> [MediaIntent], focus-independent, with
///    `held` for the long press.
///  * volume -> [VolumeIntent], likewise; held, it repeats.
///  * power -> tap-counting and hold detection, delivered as [PowerPress].
///
/// Every button has two words, and a press speaks on release so that a
/// hold is never also a press - except the volume keys, which speak on the
/// way down and keep speaking while held.
///
/// The widget also dresses every scrollable below it in bouncing physics -
/// the cupertino feel, which is the right one for a wheel.
class ClickWheelInput extends StatefulWidget {
  const ClickWheelInput({
    required this.child,
    this.controller,
    this.onMedia,
    this.onMediaHold,
    this.onVolume,
    this.onPower,
    this.onMenuHold,
    this.muted = false,
    this.holdThreshold = const Duration(milliseconds: 1500),
    this.longPress = const Duration(milliseconds: 600),
    this.tapWindow = const Duration(milliseconds: 350),
    super.key,
  });

  final Widget child;

  /// A hand that presses the same buttons the hardware does - for an
  /// emulator's drawn wheel, or a test's.
  final ClickWheelController? controller;

  /// The player's ear. Null lets the intents fall through to any screen
  /// that wants them.
  final ValueChanged<MediaCommand>? onMedia;

  /// The player's ear for the long words: a media button held past
  /// [longPress] - seek rather than skip, stop rather than pause. Null
  /// lets a held [MediaIntent] fall through like a pressed one.
  final ValueChanged<MediaCommand>? onMediaHold;

  /// The mixer's ear: +1 up, -1 down.
  final ValueChanged<int>? onVolume;

  /// The power button's grammar, already parsed.
  final ValueChanged<PowerPress>? onPower;

  /// The menu button held for [holdThreshold]. With a listener the button
  /// speaks on release - back, if it was let go in time - so a hold is
  /// never also a press; without one it speaks on press, as it always did.
  final VoidCallback? onMenuHold;

  /// Whether the wheel is to say nothing. Its keys are still claimed -
  /// nothing above or below hears them either - but no intent is
  /// dispatched and the media ear stays quiet. Two things still speak: the
  /// power chord, because it is how a muted player wakes, and the volume
  /// rocker, because a press on it in a pocket means what it says. For a screen
  /// that is dark: a thumb on the wheel in a pocket must not walk the
  /// menus blind.
  final bool muted;

  /// How long a press becomes a hold, for the power chord and the menu
  /// key: the two whose holds reach past the screen.
  final Duration holdThreshold;

  /// How long a press of the ring's other buttons - centre, previous,
  /// next, play - becomes their long word: [ActivateHoldIntent], or a
  /// [MediaIntent] with `held`. Shorter than [holdThreshold]: these holds
  /// are gestures in a screen, not chords on the player.
  final Duration longPress;

  /// How long after a release another tap still joins the count.
  final Duration tapWindow;

  @override
  State<ClickWheelInput> createState() => _ClickWheelInputState();
}

class _ClickWheelInputState extends State<ClickWheelInput> {
  /// The appliance's own focus scope.
  ///
  /// An emulator runs this app inside a window with chrome of its own, and
  /// a click on that chrome takes the platform's focus with it - after
  /// which the wheel would be dispatching into somebody else's widget tree.
  /// The scope is what makes that impossible: whatever the desktop thinks
  /// is focused, the wheel speaks to the screen *it* is wrapped around.
  ///
  /// It also claims the wheel's keys on their way up the focus chain (see
  /// [_claim]): the framework hands every key to the focused widget's
  /// ancestors *as well as* to the global ear above, whether or not that ear
  /// took it, and [WidgetsApp]'s own shortcuts sit above the navigator ready
  /// to turn Enter into a second [ActivateIntent] and an arrow into a focus
  /// move. On the player that doubled every activation - two pushes of a
  /// screen for one press of the centre, two presses of back to leave it.
  late final _scope = FocusScopeNode(
    debugLabel: 'ClickWheelInput',
    onKeyEvent: _claim,
  );

  /// Stop a key the wheel speaks from travelling any further: the intent
  /// for it has already been dispatched from [_onKey].
  KeyEventResult _claim(FocusNode node, KeyEvent event) =>
      _handles(event.physicalKey) ||
          event.physicalKey == PhysicalKeyboardKey.power
      ? KeyEventResult.handled
      : KeyEventResult.ignored;

  Timer? _powerTimer;
  int _powerTaps = 0;
  bool _powerDown = false;
  bool _powerHeld = false;

  Timer? _menuTimer;
  bool _menuDown = false;
  bool _menuHeld = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._input = this;
    // The global ear, not a Focus handler: key events only visit focus
    // ancestors when something below holds focus, and an appliance's whole
    // input must work from the first frame, focus or none.
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didUpdateWidget(ClickWheelInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller?._input == this) {
        oldWidget.controller!._input = null;
      }
      widget.controller?._input = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._input == this) widget.controller!._input = null;
    _scope.dispose();
    HardwareKeyboard.instance.removeHandler(_onKey);
    _powerTimer?.cancel();
    _menuTimer?.cancel();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  // -- the ring's buttons, pressed and held ---------------------------------

  /// The short word of a button: what a press says.
  static Intent _short(WheelButton button) => switch (button) {
    WheelButton.menu => const WheelBackIntent(),
    WheelButton.select => const ActivateIntent(),
    WheelButton.previous => const MediaIntent(MediaCommand.previous),
    WheelButton.next => const MediaIntent(MediaCommand.next),
    WheelButton.playPause => const MediaIntent(MediaCommand.toggle),
    WheelButton.volumeUp => const VolumeIntent(1),
    WheelButton.volumeDown => const VolumeIntent(-1),
  };

  /// The long word of a button: what a hold says. Menu's is not an
  /// intent but [ClickWheelInput.onMenuHold]; the volume keys' is a
  /// repeat of the short one.
  static Intent _long(WheelButton button) => switch (button) {
    WheelButton.select => const ActivateHoldIntent(),
    WheelButton.previous => const MediaIntent(
      MediaCommand.previous,
      held: true,
    ),
    WheelButton.next => const MediaIntent(MediaCommand.next, held: true),
    WheelButton.playPause => const MediaIntent(
      MediaCommand.toggle,
      held: true,
    ),
    WheelButton.menu ||
    WheelButton.volumeUp ||
    WheelButton.volumeDown => _short(button),
  };

  /// Which buttons are down, and whether their hold has spoken.
  final _down = <WheelButton>{};
  final _held = <WheelButton>{};
  final _timers = <WheelButton, Timer>{};

  /// How often a held volume key repeats, once held past [ClickWheelInput.longPress].
  static const _repeat = Duration(milliseconds: 150);

  /// A button of the ring, or a volume key, going down or coming up.
  ///
  /// Down starts the clock; a release in time says the short word, the
  /// clock running out says the long one and a release after that says
  /// nothing more. The volume keys speak on the way down and again on
  /// every tick while held.
  void _button(WheelButton button, {required bool down}) {
    if (button == WheelButton.menu) return _menu(down: down);
    final volume =
        button == WheelButton.volumeUp || button == WheelButton.volumeDown;
    if (down) {
      if (!_down.add(button)) return; // a repeat of a key already down
      _held.remove(button);
      _timers.remove(button)?.cancel();
      if (volume) {
        _dispatch(_short(button));
        _timers[button] = Timer(widget.longPress, () {
          _timers[button] = Timer.periodic(_repeat, (_) {
            if (!_down.contains(button)) return;
            _dispatch(_short(button));
          });
        });
        return;
      }
      _timers[button] = Timer(widget.longPress, () {
        if (!_down.contains(button) || widget.muted) return;
        _held.add(button);
        _dispatch(_long(button));
      });
    } else {
      if (!_down.remove(button)) return;
      _timers.remove(button)?.cancel();
      if (volume || _held.remove(button)) return; // already spoken
      _dispatch(_short(button));
    }
  }

  static WheelButton? _buttonOf(PhysicalKeyboardKey key) => switch (key) {
    PhysicalKeyboardKey.enter || PhysicalKeyboardKey.select =>
      WheelButton.select,
    PhysicalKeyboardKey.arrowLeft ||
    PhysicalKeyboardKey.mediaTrackPrevious => WheelButton.previous,
    PhysicalKeyboardKey.arrowRight ||
    PhysicalKeyboardKey.mediaTrackNext => WheelButton.next,
    PhysicalKeyboardKey.mediaPlayPause => WheelButton.playPause,
    PhysicalKeyboardKey.audioVolumeUp => WheelButton.volumeUp,
    PhysicalKeyboardKey.audioVolumeDown => WheelButton.volumeDown,
    _ => null,
  };

  // -- menu hold -----------------------------------------------------------

  /// The menu key, when a hold means something: back on a release that
  /// comes in time, the hold at the threshold, and nothing twice.
  void _menu({required bool down}) {
    if (widget.onMenuHold == null) {
      if (down) _dispatch(const WheelBackIntent());
      return;
    }
    if (down) {
      if (_menuDown) return; // a repeat of a key already down
      _menuDown = true;
      _menuHeld = false;
      _menuTimer?.cancel();
      _menuTimer = Timer(widget.holdThreshold, () {
        if (!_menuDown || widget.muted) return;
        _menuHeld = true;
        widget.onMenuHold!();
      });
    } else {
      if (!_menuDown) return;
      _menuDown = false;
      _menuTimer?.cancel();
      if (_menuHeld) return; // the hold already spoke
      _dispatch(const WheelBackIntent());
    }
  }

  // -- power chord ---------------------------------------------------------

  void _powerKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      _power(down: true);
    } else if (event is KeyUpEvent) {
      _power(down: false);
    }
  }

  void _power({required bool down}) {
    if (down) {
      _powerDown = true;
      _powerHeld = false;
      _powerTimer?.cancel();
      _powerTimer = Timer(widget.holdThreshold, () {
        if (!_powerDown) return;
        _powerHeld = true;
        _powerTaps = 0;
        widget.onPower?.call(const PowerHold());
      });
    } else {
      _powerDown = false;
      _powerTimer?.cancel();
      if (_powerHeld) return; // the hold already spoke
      _powerTaps += 1;
      _powerTimer = Timer(widget.tapWindow, () {
        final taps = _powerTaps;
        _powerTaps = 0;
        if (taps > 0) widget.onPower?.call(PowerTaps(taps));
      });
    }
  }

  // -- key translation -----------------------------------------------------

  /// One table from the hardware's keys to the grammar. Repeats count for
  /// the wheel (a held direction keeps jogging); every button, the volume
  /// keys included, is timed from its own down and up.
  bool _onKey(KeyEvent event) {
    final key = event.physicalKey;

    if (key == PhysicalKeyboardKey.power) {
      _powerKey(event);
      return true;
    }

    // Muted, the wheel is claimed and says nothing - but the volume
    // rocker still speaks: a press in a pocket means what it says, and
    // the screen need not wake for it.
    if (widget.muted && !_isVolume(key)) {
      // Claimed, and that is all - but a button that went down before the
      // mute is let go of, so it cannot speak its short word at a wake.
      final button = _buttonOf(key);
      if (button != null && event is KeyUpEvent) {
        _timers.remove(button)?.cancel();
        _down.remove(button);
        _held.remove(button);
      }
      return _handles(key);
    }

    if (key == PhysicalKeyboardKey.escape ||
        key == PhysicalKeyboardKey.browserBack) {
      if (event is KeyDownEvent) {
        _menu(down: true);
      } else if (event is KeyUpEvent) {
        _menu(down: false);
      }
      return true;
    }

    // The ring's buttons have two words each, told apart by how long the
    // key stays down: the machine counts them from the key's own edges.
    // The volume keys go the same way for their repeat - the machine's
    // own clock, since not every host repeats a held key (flutter-pi
    // over libinput does not).
    final button = _buttonOf(key);
    if (button != null) {
      if (event is KeyDownEvent) {
        _button(button, down: true);
      } else if (event is KeyUpEvent) {
        _button(button, down: false);
      }
      return true; // a repeat is a key still down
    }

    if (event is KeyUpEvent) {
      // Everything below acts on press (and repeat); releases are only the
      // chords' business.
      return _handles(key);
    }

    final intent = switch (key) {
      PhysicalKeyboardKey.arrowUp => const JogIntent(-1),
      PhysicalKeyboardKey.arrowDown => const JogIntent(1),
      PhysicalKeyboardKey.pageUp => const JogIntent(-1, page: true),
      PhysicalKeyboardKey.pageDown => const JogIntent(1, page: true),
      _ => null,
    };
    if (intent == null) return false;

    // Repeats count for the wheel: a held direction keeps jogging.
    _dispatch(intent);
    return true;
  }

  /// Where every intent goes, however it was raised: to the screen the
  /// wheel is wrapped around, and failing that to our own defaults.
  ///
  /// The scope's own idea of what is focused, not the platform's - see
  /// [_scope]. On the device the two are the same node.
  void _dispatch(Intent intent) {
    if (widget.muted && intent is! VolumeIntent) return;
    Actions.maybeInvoke(_focused() ?? _actionsContext ?? context, intent);
  }

  /// The focused node inside our scope, descending through the scopes the
  /// navigator nests on the way, so an intent lands on the screen rather
  /// than on the route that holds it.
  BuildContext? _focused() {
    FocusNode node = _scope;
    while (node is FocusScopeNode) {
      final child = node.focusedChild;
      if (child == null) break;
      node = child;
    }
    return identical(node, _scope) ? null : node.context;
  }

  /// Where intents land when nothing holds focus: just inside our own
  /// [Actions], so the defaults still answer.
  BuildContext? _actionsContext;

  bool _isVolume(PhysicalKeyboardKey key) =>
      key == PhysicalKeyboardKey.audioVolumeUp ||
      key == PhysicalKeyboardKey.audioVolumeDown;

  bool _handles(PhysicalKeyboardKey key) =>
      key == PhysicalKeyboardKey.arrowUp ||
      key == PhysicalKeyboardKey.arrowDown ||
      key == PhysicalKeyboardKey.pageUp ||
      key == PhysicalKeyboardKey.pageDown ||
      key == PhysicalKeyboardKey.enter ||
      key == PhysicalKeyboardKey.select ||
      key == PhysicalKeyboardKey.browserBack ||
      key == PhysicalKeyboardKey.escape ||
      key == PhysicalKeyboardKey.mediaPlayPause ||
      key == PhysicalKeyboardKey.arrowLeft ||
      key == PhysicalKeyboardKey.arrowRight ||
      key == PhysicalKeyboardKey.mediaTrackPrevious ||
      key == PhysicalKeyboardKey.mediaTrackNext ||
      key == PhysicalKeyboardKey.audioVolumeUp ||
      key == PhysicalKeyboardKey.audioVolumeDown;

  // -- default actions -----------------------------------------------------

  void _defaultJog(JogIntent intent) {
    final manager = FocusManager.instance;
    final steps = intent.page ? intent.amount * 4 : intent.amount;
    for (var i = 0; i < steps.abs(); i++) {
      // With nothing focused yet, the root scope's next is the first
      // focusable on screen - the first detent always lights something.
      final node = manager.primaryFocus ?? manager.rootScope;
      if (steps > 0) {
        node.nextFocus();
      } else {
        node.previousFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _scope,
      child: ScrollConfiguration(
        behavior: const WheelScrollBehavior(),
        child: Actions(
          actions: {
            JogIntent: CallbackAction<JogIntent>(
              onInvoke: (intent) {
                _defaultJog(intent);
                return null;
              },
            ),
            // A ContextAction: the pop must resolve the Navigator from where
            // the intent was dispatched (the focused screen, inside the
            // navigator) - this widget itself stands above it.
            WheelBackIntent: _WheelBackAction(),
            if (widget.onMedia != null || widget.onMediaHold != null)
              MediaIntent: CallbackAction<MediaIntent>(
                onInvoke: (intent) {
                  if (intent.held) {
                    widget.onMediaHold?.call(intent.command);
                  } else {
                    widget.onMedia?.call(intent.command);
                  }
                  return null;
                },
              ),
            if (widget.onVolume != null)
              VolumeIntent: CallbackAction<VolumeIntent>(
                onInvoke: (intent) {
                  widget.onVolume!(intent.direction);
                  return null;
                },
              ),
          },
          child: Builder(
            builder: (context) {
              _actionsContext = context;
              return widget.child;
            },
          ),
        ),
      ),
    );
  }
}

class _WheelBackAction extends ContextAction<WheelBackIntent> {
  @override
  Object? invoke(WheelBackIntent intent, [BuildContext? context]) {
    final from = context ?? primaryFocus?.context;
    if (from != null) Navigator.maybeOf(from)?.maybePop();
    return null;
  }
}

/// Every scrollable under the wheel rides cupertino physics: detents land
/// exactly, edges answer with a spring, and no platform ever swaps the
/// feel out from under the hardware - nor dresses it. On a desktop
/// platform (which is what flutter-pi says it is) Flutter would add its own
/// scrollbar to every scrollable, one that appears while scrolling; the
/// wheel's lists draw a persistent bar of their own, and two bars is one
/// too many.
class WheelScrollBehavior extends ScrollBehavior {
  const WheelScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
