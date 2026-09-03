import 'package:tomeui/tomeui.dart';

import 'intents.dart';

/// One of the words the wheel says, named so a widget can ask for it.
///
/// This is the vocabulary [InputCapture] is configured in: what a capture
/// takes for itself, and what a user can say to end it.
enum WheelInput {
  /// The ring turned: [JogIntent].
  wheel,

  /// The center button pressed: [ActivateIntent].
  select,

  /// The center button held: [ActivateHoldIntent].
  selectHold,

  /// The menu button: [WheelBackIntent].
  menu,

  /// The ring's left and right - previous and next, pressed or held:
  /// [MediaIntent] with [MediaCommand.previous] or [MediaCommand.next].
  skip,

  /// The ring's bottom - play and pause, pressed or held: [MediaIntent]
  /// with [MediaCommand.toggle].
  play,

  /// The rocker on the side: [VolumeIntent].
  volume;

  /// Which word an intent is, or null for one that is nobody's to capture.
  static WheelInput? of(Intent intent) => switch (intent) {
    JogIntent() => WheelInput.wheel,
    ActivateIntent() => WheelInput.select,
    ActivateHoldIntent() => WheelInput.selectHold,
    WheelBackIntent() => WheelInput.menu,
    MediaIntent(command: MediaCommand.toggle) => WheelInput.play,
    MediaIntent() => WheelInput.skip,
    VolumeIntent() => WheelInput.volume,
    _ => null,
  };
}

/// Takes some of the wheel's words for as long as it is [active], and
/// leaves the rest alone.
///
/// The player has one wheel and everything wants it. A list wants the jog
/// to walk its rows; the slider on the row the list has landed on wants the
/// jog to move its value. Both are right, so the wheel has to be *taken* -
/// for a while, deliberately, and given back.
///
/// That is this widget. Wrap the thing that wants the wheel, say what it
/// [captures], and turn [active] on:
///
/// ```dart
/// InputCapture(
///   active: index == _capturedRow,
///   captures: const {WheelInput.wheel},
///   onCapture: (intent) {
///     if (intent case JogIntent(:final amount)) _nudge(amount);
///   },
///   onRelease: (by) => setState(() => _capturedRow = null),
///   child: SettingSliderTile(...),
/// )
/// ```
///
/// ## How it takes them
///
/// By holding focus, not by reaching over anyone. [ClickWheelInput]
/// dispatches every intent from the focused node and lets it walk up
/// ([Actions.maybeInvoke]), so a capture that has focus is simply the first
/// [Actions] the intent meets: the words in [captures] stop here, and every
/// other word carries on up to the list, the screen, and the player's own
/// defaults above them all. A volume key still changes the volume while a
/// slider has the wheel, unless that slider asked for [WheelInput.volume]
/// too.
///
/// Focus goes back where it was when the capture ends, so the list it sits
/// in is driving again on the next detent. A [WheelList] stays dressed
/// throughout: the capture's node is inside the list's, and a node whose
/// descendant holds focus still reads as focused.
///
/// ## How it ends
///
/// [releaseOn] is what a user can say to end it - the center button and
/// menu, by default, which is "yes, that one" and "leave it alone". A word
/// in both [captures] and [releaseOn] is captured and does not release:
/// asking for [WheelInput.select] means the capture wants the press for
/// something of its own.
///
/// A capture that is going to be ended by its owner instead - a timer, a
/// value reaching an end - just takes [active] away. [onRelease] is not
/// called then: it reports what the *user* said, and its argument is the
/// word they said it with.
class InputCapture extends StatefulWidget {
  const InputCapture({
    required this.active,
    required this.child,
    this.captures = const {WheelInput.wheel},
    this.releaseOn = const {WheelInput.select, WheelInput.menu},
    this.onCapture,
    this.onRelease,
    this.debugLabel,
    super.key,
  });

  /// Whether the capture is on. Turning it on takes focus; turning it off
  /// gives it back.
  final bool active;

  final Widget child;

  /// The words this capture takes while it is [active]. Everything else
  /// carries on up the tree.
  final Set<WheelInput> captures;

  /// The words that end the capture. A word here that is also in
  /// [captures] is captured instead - [captures] wins.
  final Set<WheelInput> releaseOn;

  /// A captured word, as the intent it arrived as: switch on it for the
  /// amount of a jog, the command of a media button, the direction of a
  /// volume key.
  final ValueChanged<Intent>? onCapture;

  /// The user ended the capture, with this word. Not called when the
  /// capture ends because [active] went away.
  final ValueChanged<WheelInput>? onRelease;

  /// For the focus tree, when a screen has several of these.
  final String? debugLabel;

  @override
  State<InputCapture> createState() => _InputCaptureState();
}

class _InputCaptureState extends State<InputCapture> {
  late final FocusNode _node = FocusNode(
    debugLabel: widget.debugLabel ?? 'InputCapture',
    // Nothing walks onto a capture: it is entered by being switched on,
    // never by a jog landing on it.
    skipTraversal: true,
  );

  /// Who had focus when the capture began, to give it back to. Held as the
  /// node rather than as a context: the list that had it is still there,
  /// and it is the node that takes focus back.
  FocusNode? _returnTo;

  /// The focus this capture sits inside - the list's, as a rule. Where the
  /// wheel goes back to when there was nothing else holding it, which is
  /// the case on the first frame: a capture built already active can take
  /// focus before the list around it has claimed any.
  ///
  /// Read here rather than on the way out: a dependency cannot be looked
  /// up from [dispose].
  FocusNode? _enclosing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enclosing = Focus.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    // A capture that is born active - a screen built with one already on -
    // has no node in the tree yet to give focus to, and the list it sits in
    // is autofocusing this same frame. Ask once the frame is up, and only
    // if it is still wanted.
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active) _take();
      });
    }
  }

  @override
  void didUpdateWidget(InputCapture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _take();
    } else {
      _give();
    }
  }

  @override
  void dispose() {
    // No hand-back here, deliberately. A capture is torn down either
    // because its screen is going (there is nobody to hand the wheel to,
    // and the focus manager may already be on its way out) or because its
    // row was rebuilt away - and disposing a focused node already moves
    // focus up to the nearest scope, which is the list's.
    _node.dispose();
    super.dispose();
  }

  void _take() {
    final held = FocusManager.instance.primaryFocus;
    // Not ourselves, and never nothing: with nobody holding the wheel the
    // enclosing focus is who should have it back.
    _returnTo = (held == null || identical(held, _node))
        ? (_returnTo ?? _enclosing)
        : held;
    // The node is told directly rather than waiting for the rebuild that
    // sets it: this runs from didUpdateWidget, before build, and a node
    // that cannot request focus yet would refuse - the capture would come
    // up a frame late and eat the detent that opened it.
    _node.canRequestFocus = true;
    _node.requestFocus();
  }

  void _give() {
    final returnTo = _returnTo ?? _enclosing;
    _returnTo = null;
    if (returnTo != null && returnTo.context != null) {
      returnTo.requestFocus();
    } else if (_node.hasFocus) {
      // Nobody to give it back to: let the enclosing scope decide, rather
      // than sitting on a focus nothing can use.
      _node.unfocus();
    }
  }

  /// The words this capture answers: what it takes, and what ends it.
  ///
  /// One action per intent class, and the class is not always one word:
  /// previous, next and play-pause all arrive as a [MediaIntent], so which
  /// of them this is has to be decided when the intent lands rather than
  /// when the map is built ([wants], [captures]).
  Map<Type, Action<Intent>> get _actions {
    final actions = <Type, Action<Intent>>{};
    for (final input in {...widget.captures, ...widget.releaseOn}) {
      for (final type in _intentTypes(input)) {
        actions[type] = _CaptureAction(this);
      }
    }
    return actions;
  }

  /// The intent classes a word arrives as.
  static List<Type> _intentTypes(WheelInput input) => switch (input) {
    WheelInput.wheel => [JogIntent],
    WheelInput.select => [ActivateIntent],
    WheelInput.selectHold => [ActivateHoldIntent],
    WheelInput.menu => [WheelBackIntent],
    WheelInput.skip || WheelInput.play => [MediaIntent],
    WheelInput.volume => [VolumeIntent],
  };

  /// Whether this word is this capture's business at all - taken, or a
  /// release. Anything else falls through to whoever is above.
  bool wants(Intent intent) {
    final input = WheelInput.of(intent);
    return input != null &&
        (widget.captures.contains(input) || widget.releaseOn.contains(input));
  }

  /// Whether this word is taken, rather than a release. A word in both
  /// sets is taken: asking for it means wanting it.
  bool captures(Intent intent) {
    final input = WheelInput.of(intent);
    return input != null && widget.captures.contains(input);
  }

  /// A word arrived: taken, a release, or somebody else's.
  ///
  /// The last of those has to be *re-dispatched* rather than declined.
  /// [Actions.maybeInvoke] stops walking at the first [Actions] whose map
  /// has the intent's type, enabled or not, so an action that says no does
  /// not let the word through - it swallows it. Media is the case that
  /// needs this: previous, next and play-pause are all one [MediaIntent],
  /// so a capture that took the skip keys has an entry for the class that
  /// play-pause lands on too, and has to hand that one on.
  void handle(Intent intent) {
    if (!wants(intent)) {
      _passUp(intent);
      return;
    }
    if (captures(intent)) {
      widget.onCapture?.call(intent);
    } else {
      widget.onRelease?.call(WheelInput.of(intent)!);
    }
  }

  /// Send a word on to whoever would have answered it: the list this
  /// capture sits in, the screen, the player's own ears above them.
  void _passUp(Intent intent) {
    final above = _above;
    if (above != null && above.mounted) Actions.maybeInvoke(above, intent);
  }

  /// A context outside our own [Actions], so [_passUp] walks past us
  /// instead of straight back into us.
  BuildContext? _above;

  @override
  Widget build(BuildContext context) {
    // Inactive, the capture is not in the way at all: no Actions, and a
    // node nothing can focus.
    if (!widget.active) {
      return Focus(
        focusNode: _node,
        canRequestFocus: false,
        skipTraversal: true,
        child: widget.child,
      );
    }
    // Actions *above* the node, not below it: an intent is dispatched from
    // the focused node's own context and walks up from there, so an
    // Actions inside the Focus would never be met. This is the order
    // [WheelList] uses for the same reason. The Builder over them both is
    // the context a word is handed on from ([_passUp]), since a walk from
    // there passes us by instead of coming straight back in.
    return Builder(
      builder: (context) {
        _above = context;
        return Actions(
          actions: _actions,
          child: Focus(
            focusNode: _node,
            skipTraversal: true,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Every word that lands on a capture, sorted by it: taken (to
/// [InputCapture.onCapture]), a release (to [InputCapture.onRelease]), or
/// somebody else's, and handed on.
///
/// Always enabled, deliberately. Declining is not the same as letting
/// through - see [_InputCaptureState.handle].
class _CaptureAction extends Action<Intent> {
  _CaptureAction(this.state);

  final _InputCaptureState state;

  @override
  Object? invoke(Intent intent) {
    state.handle(intent);
    return null;
  }
}
