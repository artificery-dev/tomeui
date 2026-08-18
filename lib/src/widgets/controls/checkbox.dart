import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// A yes or a no, in a small square [Surface].
///
/// Wears the same grammar as the surface it's made of — a [SemanticSwatch]
/// in a [SurfaceVariant] — with the check glyph ([Icons.confirm]) growing
/// in when checked. The variant dresses both states: checked wears the
/// swatch, unchecked wears neutral, so a `soft` checkbox rests as a faint
/// grey box and a `ghost` one is invisible until ticked.
///
/// The value belongs to the caller: tapping reports `!value` through
/// [onChanged] and paints nothing until told. Interaction — hover wash,
/// press sink, focus ring, keyboard toggling — comes from the shared
/// [Interactive] core.
class Checkbox extends StatelessWidget {
  const Checkbox({
    required this.value,
    required this.onChanged,
    this.label,
    this.variant = SurfaceVariant.solid,
    this.swatch = SemanticSwatch.primary,
    super.key,
  }) : style = null;

  /// Custom everything: paints [style] exactly as given, resolving nothing.
  const Checkbox.custom({
    required this.value,
    required this.onChanged,
    required CheckboxStyle this.style,
    this.label,
    super.key,
  }) : variant = SurfaceVariant.solid,
       swatch = SemanticSwatch.primary;

  final bool value;

  /// Called with `!value` on toggle. Null disables the checkbox: it dims,
  /// ignores the pointer, and leaves the focus order.
  final ValueChanged<bool>? onChanged;

  /// Words beside the box, and part of it: clicking them toggles too.
  final Widget? label;

  final SurfaceVariant variant;

  /// The meaning to wear when checked — the palette says which colour.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme — set only by
  /// [Checkbox.custom].
  final CheckboxStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.checkbox.resolve(swatch, variant);
    final enabled = onChanged != null;

    return Semantics(
      checked: value,
      enabled: enabled,
      // A control keeps its own size in a slot that would stretch it — and
      // this sits outside Interactive so the focus ring hugs the box, not
      // the slot.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Interactive(
          onActivate: enabled ? () => onChanged!(!value) : null,
          label: label,
          labelGap: style.gap,
          ring: style.ring,
          ringRadius: style.checked.radius,
          hover: style.hover,
          pressed: style.pressed,
          lift: style.lift,
          disabledOpacity: style.disabledOpacity,
          builder: (context, state) => TweenAnimationBuilder<double>(
            // The state crossfade: fill blooms in from the swatch's own hue,
            // the outline melts into it, the check grows with it.
            tween: Tween(end: value ? 1.0 : 0.0),
            duration: theme.motion.fast,
            curve: theme.motion.move,
            builder: (context, presence, _) {
              // Each state's fill stands in for the other's absence, at zero
              // alpha, so the bloom passes through the right hue.
              final fill = Color.lerp(
                style.unchecked.fill ??
                    style.checked.fill?.withValues(alpha: 0),
                style.checked.fill ??
                    style.unchecked.fill?.withValues(alpha: 0),
                presence,
              );
              // Booleans can't lerp: the dominant state carries them.
              final dress = presence < 0.5 ? style.unchecked : style.checked;
              return SizedBox(
                width: style.size,
                height: style.size,
                child: Surface.custom(
                  style: SurfaceStyle(
                    foreground: Color.lerp(
                      style.unchecked.foreground,
                      style.checked.foreground,
                      presence,
                    )!,
                    fill: state.wash == null || fill == null
                        ? (state.wash ?? fill)
                        : Color.alphaBlend(state.wash!, fill),
                    border: Color.lerp(
                      style.unchecked.border,
                      style.checked.border,
                      presence,
                    ),
                    dashed: dress.dashed,
                    striped: dress.striped,
                    radius: style.checked.radius,
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: presence,
                      child: Opacity(
                        opacity: presence,
                        child: Icon(
                          theme.icons.confirm,
                          size: style.size * 0.7,
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
