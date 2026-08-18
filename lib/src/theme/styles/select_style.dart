import 'package:tomeui/tomeui.dart';

/// The resolved values a [Select] actually paints: the closed control, and
/// the rows of the list it opens. The choosing happened in
/// [SelectResolver], at `theme.widgets.select`.
@immutable
class SelectStyle {
  const SelectStyle({
    required this.trigger,
    required this.placeholder,
    this.optionPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.optionGap = 8,
    this.optionRadius = const BorderRadius.all(Radius.circular(6)),
    required this.highlight,
    required this.selected,
    this.maxListHeight = 280,
  });

  /// The closed control — a button in everything but name, so it wears a
  /// button's resolved style.
  final ButtonStyle trigger;

  /// What the trigger's text wears when nothing is chosen yet.
  final TextStyle placeholder;

  /// Inside one row of the list.
  final EdgeInsetsGeometry optionPadding;

  /// Between a row's leading icon, its label, and the tick.
  final double optionGap;

  final BorderRadius optionRadius;

  /// Behind the row the pointer or the keyboard is on.
  final Color highlight;

  /// Behind the row that is the current answer.
  final Color selected;

  /// How tall the list grows before it scrolls instead.
  final double maxListHeight;

  SelectStyle copyWith({
    ButtonStyle? trigger,
    TextStyle? placeholder,
    EdgeInsetsGeometry? optionPadding,
    double? optionGap,
    BorderRadius? optionRadius,
    Color? highlight,
    Color? selected,
    double? maxListHeight,
  }) => SelectStyle(
    trigger: trigger ?? this.trigger,
    placeholder: placeholder ?? this.placeholder,
    optionPadding: optionPadding ?? this.optionPadding,
    optionGap: optionGap ?? this.optionGap,
    optionRadius: optionRadius ?? this.optionRadius,
    highlight: highlight ?? this.highlight,
    selected: selected ?? this.selected,
    maxListHeight: maxListHeight ?? this.maxListHeight,
  );

  @override
  bool operator ==(Object other) =>
      other is SelectStyle &&
      other.trigger == trigger &&
      other.placeholder == placeholder &&
      other.optionPadding == optionPadding &&
      other.optionGap == optionGap &&
      other.optionRadius == optionRadius &&
      other.highlight == highlight &&
      other.selected == selected &&
      other.maxListHeight == maxListHeight;

  @override
  int get hashCode => Object.hash(
    trigger,
    placeholder,
    optionPadding,
    optionGap,
    optionRadius,
    highlight,
    selected,
    maxListHeight,
  );
}
