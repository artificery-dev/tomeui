import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// The one answer a set of [RadioButton]s share, handed down the tree.
///
/// The group owns the choice; the buttons only report. Anything below it
/// can be a [RadioButton] of the same type — nested in rows, cards, list
/// tiles — without the buttons being siblings or knowing about each other:
///
/// ```dart
/// RadioGroup<Ration>(
///   value: ration,
///   onChanged: (value) => setState(() => ration = value),
///   child: Column(
///     children: [
///       for (final option in Ration.values) RadioButton(value: option),
///     ],
///   ),
/// )
/// ```
///
/// [value] may be null — nothing chosen yet. A null [onChanged] disables
/// every button in the group at once.
class RadioGroup<T> extends InheritedWidget {
  const RadioGroup({
    required this.value,
    required this.onChanged,
    required super.child,
    super.key,
  });

  /// The group's current answer, or null when nothing is chosen.
  final T? value;

  /// Called with a button's value when it's chosen. Null disables the whole
  /// group.
  final ValueChanged<T>? onChanged;

  /// The enclosing group, or null if there isn't one.
  static RadioGroup<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RadioGroup<T>>();

  /// The enclosing group. Throws if a [RadioButton] is floating free —
  /// a radio without a group has nothing to be exclusive *with*.
  static RadioGroup<T> of<T>(BuildContext context) {
    final group = maybeOf<T>(context);
    if (group == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No RadioGroup<$T> found above this RadioButton<$T>.'),
        ErrorDescription(
          'A RadioButton reads its selected state from an enclosing '
          'RadioGroup of the same type, and reports its choice back to it.',
        ),
        ErrorHint(
          'Wrap the buttons in a RadioGroup<$T>, and check that the group '
          "and the buttons agree on their type — a RadioGroup<Object> won't "
          'answer a RadioButton<$T>.',
        ),
      ]);
    }
    return group;
  }

  @override
  bool updateShouldNotify(RadioGroup<T> oldWidget) =>
      oldWidget.value != value || oldWidget.onChanged != onChanged;
}

/// One answer among several, in a small [Surface] circle.
///
/// Wears the same grammar as everything else — a [SemanticSwatch] in a
/// [SurfaceVariant] — with a dot growing in when this is the group's
/// choice. State comes from the enclosing [RadioGroup]: the button compares
/// its [value] to the group's and reports back on tap, painting nothing
/// until the group says so.
class RadioButton<T> extends StatelessWidget {
  const RadioButton({
    required this.value,
    this.label,
    this.enabled = true,
    this.variant = SurfaceVariant.solid,
    this.swatch = SemanticSwatch.primary,
    super.key,
  }) : style = null;

  /// Custom everything: paints [style] exactly as given, resolving nothing.
  const RadioButton.custom({
    required this.value,
    required RadioStyle this.style,
    this.label,
    this.enabled = true,
    super.key,
  }) : variant = SurfaceVariant.solid,
       swatch = SemanticSwatch.primary;

  /// What choosing this button means. Selected when it equals the group's.
  final T value;

  /// Words beside the circle, and part of it: clicking them chooses too.
  final Widget? label;

  /// This one button's availability. The group disables all of them at once
  /// by taking a null `onChanged`.
  final bool enabled;

  final SurfaceVariant variant;

  /// The meaning to wear when selected — the palette says which colour.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme — set only by
  /// [RadioButton.custom].
  final RadioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.radio.resolve(swatch, variant);
    final group = RadioGroup.of<T>(context);
    final selected = group.value == value;
    final live = enabled && group.onChanged != null;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: live,
      // A control keeps its own size in a slot that would stretch it — and
      // this sits outside Interactive so the focus ring hugs the circle,
      // not the slot.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Interactive(
          // Choosing the chosen changes nothing, but stays live: a radio
          // can't be un-chosen by tapping it again.
          onActivate: live ? () => group.onChanged!(value) : null,
          label: label,
          labelGap: style.gap,
          ring: style.ring,
          ringRadius: style.selected.radius,
          hover: style.hover,
          pressed: style.pressed,
          lift: style.lift,
          disabledOpacity: style.disabledOpacity,
          builder: (context, state) => TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1.0 : 0.0),
            duration: theme.motion.fast,
            curve: theme.motion.move,
            builder: (context, presence, _) {
              // Each state's fill stands in for the other's absence, at zero
              // alpha, so the bloom passes through the right hue.
              final fill = Color.lerp(
                style.unselected.fill ??
                    style.selected.fill?.withValues(alpha: 0),
                style.selected.fill ??
                    style.unselected.fill?.withValues(alpha: 0),
                presence,
              );
              // Booleans can't lerp: the dominant state carries them.
              final dress = presence < 0.5 ? style.unselected : style.selected;
              final dotColor = Color.lerp(
                style.unselected.foreground,
                style.selected.foreground,
                presence,
              )!;
              return SizedBox(
                width: style.size,
                height: style.size,
                child: Surface.custom(
                  style: SurfaceStyle(
                    foreground: dotColor,
                    fill: state.wash == null || fill == null
                        ? (state.wash ?? fill)
                        : Color.alphaBlend(state.wash!, fill),
                    border: Color.lerp(
                      style.unselected.border,
                      style.selected.border,
                      presence,
                    ),
                    dashed: dress.dashed,
                    striped: dress.striped,
                    radius: style.selected.radius,
                  ),
                  child: Center(
                    child: SizedBox.square(
                      dimension: style.dot * presence,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
