import 'package:tomeui/tomeui.dart';

/// A hairline between two things.
///
/// Horizontal by default, filling whatever width it's given; [Axis.vertical]
/// makes it a rule down a row instead, filling the height. The color and
/// weight come from the theme (`theme.widgets.divider`), so every rule in
/// the app is the one line.
///
/// [fade] trades the flat line for one that reaches full strength in the
/// middle and dissolves at both ends — a separator that divides without
/// drawing a box, which is what a rule inside a card or between menu
/// sections usually wants.
class Divider extends StatelessWidget {
  const Divider({
    this.axis = Axis.horizontal,
    this.fade = false,
    this.indent = SpaceStep.none,
    this.endIndent = SpaceStep.none,
    this.style,
    super.key,
  });

  final Axis axis;

  /// Fade the line out towards both ends instead of stopping it flat.
  final bool fade;

  /// How far short of the start the line begins — the top of a vertical
  /// rule, the leading edge of a horizontal one.
  final SpaceStep indent;

  /// How far short of the end it stops.
  final SpaceStep endIndent;

  /// The line to draw, bypassing the theme.
  final DividerStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = this.style ?? theme.widgets.divider.resolve();
    final horizontal = axis == Axis.horizontal;

    return Padding(
      padding: horizontal
          ? EdgeInsetsDirectional.only(
              start: theme.space.resolve(indent),
              end: theme.space.resolve(endIndent),
            )
          : EdgeInsets.only(
              top: theme.space.resolve(indent),
              bottom: theme.space.resolve(endIndent),
            ),
      child: SizedBox(
        // The cross axis is the line's weight; along its run it takes
        // everything, which in a bounded parent is the parent's own extent.
        width: horizontal ? double.infinity : style.thickness,
        height: horizontal ? style.thickness : double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fade ? null : style.color,
            gradient: fade
                ? LinearGradient(
                    begin: horizontal
                        ? AlignmentDirectional.centerStart
                        : Alignment.topCenter,
                    end: horizontal
                        ? AlignmentDirectional.centerEnd
                        : Alignment.bottomCenter,
                    colors: [
                      style.color.withValues(alpha: 0),
                      style.color,
                      style.color.withValues(alpha: 0),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
