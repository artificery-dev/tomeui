import 'package:tomeui/tomeui.dart';

/// The wheel turned.
///
/// [amount] is signed detents: positive jogs forward (clockwise, down the
/// screen), negative back. [page] marks the fast-spin tier - the hardware
/// reports a spin too quick for detent-by-detent as page steps, and a
/// consumer that can't page treats one page as several detents.
///
/// The default handler ([ClickWheelActions]) walks widget focus; anything
/// with a selection model of its own ([WheelList]) overrides this intent in
/// its subtree and consumes the turn itself.
class JogIntent extends Intent {
  const JogIntent(this.amount, {this.page = false});

  final int amount;
  final bool page;
}

/// The menu button: up one level.
///
/// Default handler pops the nearest [Navigator]; a screen with its own
/// notion of "back" (a fold to close, an edit to cancel) overrides it.
class WheelBackIntent extends Intent {
  const WheelBackIntent();
}

/// The centre button held: the long word of select. Where a press opens
/// or chooses, the hold is the alternative - more about the thing, or
/// the thing done another way. Default handler: nothing, so a screen with
/// no alternative stays quiet rather than choosing twice.
class ActivateHoldIntent extends Intent {
  const ActivateHoldIntent();
}

/// What the media buttons say. They speak past focus entirely - the player
/// hears them from any screen.
enum MediaCommand { toggle, previous, next }

/// A media button, pressed or held. [held] is the long word: the button
/// kept down past [ClickWheelInput.longPress] - seek rather than skip,
/// stop rather than pause - and a hold is never also a press.
class MediaIntent extends Intent {
  const MediaIntent(this.command, {this.held = false});

  final MediaCommand command;
  final bool held;
}

/// The volume rocker. [direction] is +1 up, -1 down.
class VolumeIntent extends Intent {
  const VolumeIntent(this.direction);

  final int direction;
}
