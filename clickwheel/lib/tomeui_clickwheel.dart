/// The click wheel behind Tome UI.
///
/// An iPod's grammar for a device that is a wheel, five buttons, a volume
/// rocker, a power button, and a small screen:
///
///  * [ClickWheelInput] wraps the app once and turns the hardware's keys
///    into intents - jog, activate, back, media, volume - plus the power
///    button's tap-and-hold chords, and dresses every scrollable in the
///    cupertino feel.
///  * [JogIntent] walks widget focus by default, so ordinary screens are
///    wheel-driven for free.
///  * [WheelList] is the list the wheel deserves: one selection model in a
///    fixed shape (a main menu, rows given whole) and a lazy shape (a
///    library of thousands), identical mechanics in both.
///  * [WheelRail] is a short track of options with a box the wheel slides
///    along it, which gives at its ends and lets go when pushed.
library;

export 'src/click_wheel_input.dart';
export 'src/intents.dart';
export 'src/wheel_grid.dart';
export 'src/wheel_list.dart';
export 'src/wheel_rail.dart';
