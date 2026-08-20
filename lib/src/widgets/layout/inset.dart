import 'package:tomeui/tomeui.dart';

/// Padding that only speaks the [Space] scale.
///
/// `Inset.all(SpaceStep.x4)` where Flutter would say
/// `Padding(padding: EdgeInsets.all(16))` — the difference being that
/// off-scale padding is unrepresentable rather than merely discouraged, and
/// that a theme with a denser scale re-inks every inset in the app without
/// touching a call site.
///
/// The insets are directional: [start] and [end] follow the reading
/// direction, so a right-to-left locale mirrors without a second layout.
class Inset extends StatelessWidget {
  /// The same step on all four sides.
  const Inset.all(SpaceStep step, {this.child, super.key})
    : start = step,
      top = step,
      end = step,
      bottom = step;

  const Inset.symmetric({
    SpaceStep horizontal = SpaceStep.none,
    SpaceStep vertical = SpaceStep.none,
    this.child,
    super.key,
  }) : start = horizontal,
       end = horizontal,
       top = vertical,
       bottom = vertical;

  const Inset.only({
    this.start = SpaceStep.none,
    this.top = SpaceStep.none,
    this.end = SpaceStep.none,
    this.bottom = SpaceStep.none,
    this.child,
    super.key,
  });

  /// The leading edge — left in a left-to-right locale.
  final SpaceStep start;

  final SpaceStep top;

  /// The trailing edge — right in a left-to-right locale.
  final SpaceStep end;

  final SpaceStep bottom;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final space = (ThemeProvider.maybeOf(context) ?? const Theme()).space;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: space.resolve(start),
        top: space.resolve(top),
        end: space.resolve(end),
        bottom: space.resolve(bottom),
      ),
      child: child,
    );
  }
}
