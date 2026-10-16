import 'package:flutter/foundation.dart';

/// Letter browsing is measured in physical turns, before clicks-per-row.
/// The host supplies its measured controller resolution and velocity thresholds.
@immutable
class WheelScrollConfig {
  const WheelScrollConfig({
    required this.ticksPerRevolution,
    required this.enterRevolutionsPerSecond,
    this.velocityWindow = const Duration(milliseconds: 250),
    this.letterIdle = const Duration(milliseconds: 1500),
    this.minimumScreens = 3,
  }) : assert(ticksPerRevolution > 0),
       assert(enterRevolutionsPerSecond > 0),
       assert(minimumScreens > 0);

  /// Y2 calibration, 2026-09-16: 57 normal frames over three hand-counted
  /// revolutions (19/turn; nominal emulator resolution is 20). With this
  /// resolution 1.4 turns/s = 26.6 frames/s: a 250 ms window needs seven
  /// frames (28 frames/s). Fine-adjustment capture peaked at six frames;
  /// fast scrolling commonly supplied seven or eight. Keep angular thresholds
  /// independent of rows-per-detent; other hardware supplies its own config.
  static const y2 = WheelScrollConfig(
    ticksPerRevolution: 19,
    enterRevolutionsPerSecond: 1.4,
  );

  /// Controller frames per physical turn, NOT rows per turn. Changing UI
  /// sensitivity must not change this. One normal/page key-down is one frame;
  /// do not multiply the firmware's page code by the visible page size.
  final double ticksPerRevolution;

  /// Physical revolutions/second averaged over [velocityWindow]. Multiply by
  /// [ticksPerRevolution] to obtain controller frames/second for this device.
  final double enterRevolutionsPerSecond;
  final Duration velocityWindow;

  /// Resets on EVERY raw detent while letters are visible, even at low speed.
  /// The list regains wheel focus only after the overlay finishes closing.
  final Duration letterIdle;

  /// Lists shorter than this many viewports never enter letter mode.
  final int minimumScreens;
}
