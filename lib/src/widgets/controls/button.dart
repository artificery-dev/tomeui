import 'package:tomeui/tomeui.dart';

import '../foundation/interactive.dart';

/// A clickable [Surface].
///
/// Wears the same grammar as the surface it's made of — a [SemanticSwatch]
/// in a [SurfaceVariant] — and adds what a control needs: hover and pressed
/// washes in its own foreground colour, a focus ring in the swatch's full
/// voice, keyboard activation, and a disabled state when [onPressed] is
/// null. The interaction machinery lives in the shared [Interactive] core.
///
/// Three slots: [leading], [center], [trailing] — an icon, the label,
/// a shortcut hint. [Button.custom] takes a single child and a resolved
/// [ButtonStyle] instead, for custom everything.
class Button extends StatelessWidget {
  const Button({
    required this.onPressed,
    required this.center,
    this.leading,
    this.trailing,
    this.variant = SurfaceVariant.solid,
    this.swatch = SemanticSwatch.primary,
    super.key,
  }) : style = null;

  /// Custom everything: paints [style] exactly as given, resolving nothing,
  /// with [child] as the only slot.
  const Button.custom({
    required this.onPressed,
    required ButtonStyle this.style,
    required Widget child,
    super.key,
  }) : center = child,
       leading = null,
       trailing = null,
       variant = SurfaceVariant.solid,
       swatch = SemanticSwatch.primary;

  /// What pressing does. Null disables the button: it dims, ignores the
  /// pointer, and leaves the focus order.
  final VoidCallback? onPressed;

  final Widget center;
  final Widget? leading;
  final Widget? trailing;

  final SurfaceVariant variant;

  /// The meaning to wear — the palette says which colour that is.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme — set only by [Button.custom].
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.button.resolve(swatch, variant);
    final enabled = onPressed != null;

    // A button in a run shares its edges: the corners facing a neighbour go
    // square, and the rest of the shape is its own.
    final slot = ButtonGroupSlot.maybeOf(context);
    final surface = slot == null
        ? style.surface
        : style.surface.copyWith(
            radius: slot.shape(
              style.surface.radius,
              Directionality.maybeOf(context) ?? TextDirection.ltr,
            ),
          );

    final content = DefaultTextStyle.merge(
      style: style.textStyle,
      // Whatever the slot said has been said: a button nested in this one's
      // slots belongs to no group.
      child: ButtonGroupSlot.solo(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, SizedBox(width: style.gap)],
            // Loose, so a squeezed button squeezes its centre rather than
            // overflowing: the glyphs keep their size and the label yields.
            // A plain child here would take unbounded width from the row,
            // and anything inside that wanted to shrink couldn't.
            Flexible(child: center),
            if (trailing != null) ...[SizedBox(width: style.gap), trailing!],
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: Interactive(
        onActivate: onPressed,
        ring: style.ring,
        ringRadius: surface.radius,
        hover: style.hover,
        pressed: style.pressed,
        lift: style.lift,
        disabledOpacity: style.disabledOpacity,
        // Washes land on the fill, so a fill-less variant (ghost, outline)
        // grows one the moment it's touched.
        builder: (context, state) => SizedBox(
          height: style.height,
          child: Surface.custom(
            // Built whole rather than copyWith'd: a fill-less variant's
            // fill has to stay null-able under a transparent wash.
            style: SurfaceStyle(
              foreground: surface.foreground,
              fill: state.wash == null
                  ? surface.fill
                  : surface.fill == null
                  ? state.wash
                  : Color.alphaBlend(state.wash!, surface.fill!),
              border: surface.border,
              dashed: surface.dashed,
              striped: surface.striped,
              radius: surface.radius,
            ),
            padding: style.padding,
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );
  }
}
