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

/// Menu held: open the focused app's menu. Unhandled, this does nothing.
/// This is separate from Back and from holding the selected item.
class WheelMenuIntent extends Intent {
  const WheelMenuIntent();
}

/// The center button held: the long word of select. Where a press opens
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

/// How a turn of the ring becomes movement.
///
/// The hardware reports detents, and a detent has always been a row. That
/// is a fine default and a poor rule: the ring on this player is small,
/// and how far a thumb has to drag it to cross a list is the difference
/// between the thing being pleasant and being work. Settings > Controls >
/// Wheel sets it.
@immutable
class WheelFeel {
  const WheelFeel({
    this.rowsPerDetent = 1,
    this.acceleration = true,
    this.reversed = false,
  });

  /// How far one detent carries. Above one a light turn goes further;
  /// below it the ring has to be turned further to move at all, and the
  /// fraction is carried rather than dropped, so a firm wheel still
  /// arrives - it just takes the turning.
  final double rowsPerDetent;

  /// Whether a fast spin moves further per detent than a slow one. The
  /// hardware reports the fast tier itself; off, it is treated as an
  /// ordinary turn.
  final bool acceleration;

  /// Clockwise goes up the list rather than down.
  final bool reversed;

  /// What the player ships with: a detent is a row, a spin is faster, and
  /// clockwise goes down.
  static const WheelFeel standard = WheelFeel();

  WheelFeel copyWith({
    double? rowsPerDetent,
    bool? acceleration,
    bool? reversed,
  }) => WheelFeel(
    rowsPerDetent: rowsPerDetent ?? this.rowsPerDetent,
    acceleration: acceleration ?? this.acceleration,
    reversed: reversed ?? this.reversed,
  );

  @override
  bool operator ==(Object other) =>
      other is WheelFeel &&
      other.rowsPerDetent == rowsPerDetent &&
      other.acceleration == acceleration &&
      other.reversed == reversed;

  @override
  int get hashCode => Object.hash(rowsPerDetent, acceleration, reversed);
}

/// What still speaks while the screen is dark.
///
/// A dark player is still a player: it is in a pocket, and a thumb finds
/// the rocker or the play key without looking. Which of those a person
/// wants answered is a matter of taste and of trousers, so it is set
/// rather than decided - Settings > Display, at the bottom.
///
/// Menu is not here. In either of its words it says nothing while the
/// screen is dark: back would move the player blind, and an app menu would
/// come up over a screen nobody can see. Nor is the center button, which
/// is how a dark player wakes and has no second meaning to give away.
@immutable
class DarkInput {
  const DarkInput({this.media = true, this.wheel = false, this.volume = true});

  /// Play, next and previous act while the screen sleeps.
  final bool media;

  /// The wheel is the volume, rather than saying nothing. Off by
  /// default: a thumb resting on the wheel in a pocket would otherwise be
  /// turning the music up.
  final bool wheel;

  /// The rocker acts. A press on it in a pocket means what it says.
  final bool volume;

  /// What the player ships with.
  static const DarkInput standard = DarkInput();

  DarkInput copyWith({bool? media, bool? wheel, bool? volume}) => DarkInput(
    media: media ?? this.media,
    wheel: wheel ?? this.wheel,
    volume: volume ?? this.volume,
  );

  @override
  bool operator ==(Object other) =>
      other is DarkInput &&
      other.media == media &&
      other.wheel == wheel &&
      other.volume == volume;

  @override
  int get hashCode => Object.hash(media, wheel, volume);
}

/// The kinds of thing the wheel says, for whatever answers each with a
/// sound or a shake: a detent of the wheel, a press of a button, a hold.
enum WheelWord {
  detent,
  press,
  hold;

  static WheelWord of(Intent intent) => switch (intent) {
    JogIntent() => WheelWord.detent,
    ActivateHoldIntent() || WheelMenuIntent() => WheelWord.hold,
    MediaIntent(held: true) => WheelWord.hold,
    _ => WheelWord.press,
  };
}
