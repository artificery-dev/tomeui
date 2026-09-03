import 'package:flutter/foundation.dart';

/// One adjustable input on a story: a labeled value the Widget tab renders
/// a control for.
///
/// A story creates its knobs once, closes over them in its builder, and
/// reads `value` on every rebuild — the knob is the single source of truth
/// for that input, and notifies whenever a control changes it.
sealed class Knob<T> extends ValueNotifier<T> {
  Knob(this.label, super.initial);

  final String label;
}

/// A yes/no knob — rendered as a switch.
class BoolKnob extends Knob<bool> {
  BoolKnob(super.label, super.initial);
}

/// A number in a range — rendered as a slider.
class DoubleKnob extends Knob<double> {
  DoubleKnob(super.label, super.initial, {this.min = 0, this.max = 1});

  final double min;
  final double max;
}

/// Free text — rendered as a text field.
class StringKnob extends Knob<String> {
  StringKnob(super.label, super.initial);
}

/// One of a fixed list — rendered as a row of pills.
class ListKnob<T> extends Knob<T> {
  ListKnob(super.label, super.initial, {required this.options, this.describe});

  final List<T> options;

  /// Names an option for display; enum stories pass `(o) => o.name`.
  final String Function(T option)? describe;

  String describeOption(T option) => describe?.call(option) ?? '$option';
}
