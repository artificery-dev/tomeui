import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// The one answer a set of grouped [Switch]es share, handed down the tree.
///
/// Same shape as [RadioGroup], and it changes what a [Switch] *is*: inside
/// one, switches built with [Switch.grouped] are exclusive — turning one on
/// turns the others off — where a standalone [Switch] is its own yes or no.
///
/// [value] may be null — everything off. A null [onChanged] disables every
/// switch in the group at once.
class SwitchGroup<T> extends InheritedWidget {
  const SwitchGroup({
    required this.value,
    required this.onChanged,
    required super.child,
    super.key,
  });

  /// The group's current answer, or null when nothing is on.
  final T? value;

  /// Called with a switch's value when it's turned on. Null disables the
  /// whole group.
  final ValueChanged<T>? onChanged;

  /// The enclosing group, or null if there isn't one — which is how a
  /// [Switch] tells which kind of switch it is.
  static SwitchGroup<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SwitchGroup<T>>();

  @override
  bool updateShouldNotify(SwitchGroup<T> oldWidget) =>
      oldWidget.value != value || oldWidget.onChanged != onChanged;
}

/// A standalone switch is its own yes or no, so its value has to be one.
/// Anything else means the group that would have given it meaning is
/// missing.
FlutterError _notBool<T>(Object? value) => FlutterError.fromParts([
  ErrorSummary('A standalone Switch<$T> has a ${value.runtimeType} value.'),
  ErrorDescription(
    'On its own a switch is a yes or no, so its value must be a bool. With '
    'a SwitchGroup<$T> above it, a value of any type is fine — the switch '
    "is on when it equals the group's answer.",
  ),
  ErrorHint(
    'Wrap these switches in a SwitchGroup<$T>, or check that the group and '
    'the switches agree on their type.',
  ),
]);

/// A yes or a no you flip, as a thumb riding a track.
///
/// What a switch *is* depends on where it stands. On its own it's a
/// checkbox in another shape — a `bool` [value] of its own, reported
/// through [onChanged]:
///
/// ```dart
/// Switch(value: lanternLit, onChanged: (on) => setState(() => lanternLit = on))
/// ```
///
/// Inside a [SwitchGroup] it's a radio button in another shape — one of
/// several, exclusive, on when [value] is the group's answer. No second
/// constructor: the group above decides, and [value] takes whatever type
/// the choice is made of.
///
/// ```dart
/// SwitchGroup<Watch>(
///   value: watch,
///   onChanged: (value) => setState(() => watch = value),
///   child: Column(
///     children: [
///       for (final w in Watch.values) Switch(value: w, label: Text(w.name)),
///     ],
///   ),
/// )
/// ```
///
/// Either way it wears the usual grammar — a [SemanticSwatch] in a
/// [SurfaceVariant] — and the shared [Interactive] core's hover wash, press
/// sink, focus ring, and keyboard activation.
class Switch<T> extends StatelessWidget {
  const Switch({
    required this.value,
    this.onChanged,
    this.label,
    this.enabled = true,
    this.variant = SurfaceVariant.solid,
    this.swatch = SemanticSwatch.primary,
    super.key,
  }) : style = null;

  /// Custom everything: paints [style] exactly as given, resolving nothing.
  const Switch.custom({
    required this.value,
    required SwitchStyle this.style,
    this.onChanged,
    this.label,
    this.enabled = true,
    super.key,
  }) : variant = SurfaceVariant.solid,
       swatch = SemanticSwatch.primary;

  /// Standalone, this is the switch's own state, and must be a `bool`.
  /// Grouped, it's what turning this switch on means — the switch is on
  /// when the group's answer equals it.
  final T value;

  /// Called with the flipped value, standalone only — a grouped switch
  /// reports to its [SwitchGroup] instead. Null disables a standalone
  /// switch.
  final ValueChanged<T>? onChanged;

  /// This one switch's availability. A group disables all of its switches
  /// at once by taking a null `onChanged`.
  final bool enabled;

  /// Words beside the track, and part of it: clicking them flips too.
  final Widget? label;

  final SurfaceVariant variant;

  /// The meaning to wear when on — the palette says which colour.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme — set only by [Switch.custom].
  final SwitchStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.switch_.resolve(swatch, variant);

    // Which switch this is, is a question about its surroundings: a group
    // above makes it one of several, its absence leaves it its own answer.
    final group = SwitchGroup.maybeOf<T>(context);

    final bool isOn;
    final bool live;
    final VoidCallback? activate;
    if (group != null) {
      isOn = group.value == value;
      live = enabled && group.onChanged != null;
      // Grouped, like a radio: flipping the one that's on changes nothing,
      // because something has to be the answer.
      activate = live ? () => group.onChanged!(value) : null;
    } else {
      if (value is! bool) throw _notBool<T>(value);
      isOn = value as bool;
      live = enabled && onChanged != null;
      activate = live ? () => onChanged!(!isOn as T) : null;
    }

    return Semantics(
      toggled: isOn,
      inMutuallyExclusiveGroup: group != null,
      enabled: live,
      // A control keeps its own size in a slot that would stretch it — and
      // this sits outside Interactive so the focus ring hugs the track.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Interactive(
          onActivate: activate,
          ring: style.ring,
          ringRadius: style.on.radius,
          hover: style.hover,
          pressed: style.pressed,
          lift: style.lift,
          disabledOpacity: style.disabledOpacity,
          label: label,
          labelGap: style.gap,
          builder: (context, state) => TweenAnimationBuilder<double>(
            tween: Tween(end: isOn ? 1.0 : 0.0),
            duration: theme.motion.fast,
            curve: theme.motion.move,
            builder: (context, presence, _) {
              final fill = Color.lerp(
                style.off.fill ?? style.on.fill?.withValues(alpha: 0),
                style.on.fill ?? style.off.fill?.withValues(alpha: 0),
                presence,
              );
              // Booleans can't lerp: the dominant state carries them.
              final dress = presence < 0.5 ? style.off : style.on;
              final thumbColor = Color.lerp(
                style.off.foreground,
                style.on.foreground,
                presence,
              )!;
              return SizedBox(
                width: style.width,
                height: style.height,
                child: Surface.custom(
                  style: SurfaceStyle(
                    foreground: thumbColor,
                    fill: state.wash == null || fill == null
                        ? (state.wash ?? fill)
                        : Color.alphaBlend(state.wash!, fill),
                    border: Color.lerp(
                      style.off.border,
                      style.on.border,
                      presence,
                    ),
                    dashed: dress.dashed,
                    striped: dress.striped,
                    radius: style.on.radius,
                  ),
                  padding: EdgeInsets.all(style.inset),
                  child: Align(
                    // The thumb rides from one end to the other.
                    alignment: Alignment.lerp(
                      Alignment.centerLeft,
                      Alignment.centerRight,
                      presence,
                    )!,
                    child: SizedBox.square(
                      dimension: style.thumb,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: thumbColor,
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
