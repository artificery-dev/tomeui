import 'package:tomeui/tomeui.dart';

/// A box for something that isn't here yet — a drop target, an empty slot,
/// the space a feature will grow into.
///
/// Wears [SurfaceVariant.placeholder]: a dashed hairline over a diagonally
/// striped wash, [SemanticSwatch.neutral] unless told otherwise. Fills
/// whatever size its parent dictates and centers [child] in it; under loose
/// constraints it hugs the child instead — a placeholder never forces its
/// parent bigger.
///
/// Deliberately shadows Flutter's `Placeholder`; the barrel hides the
/// original.
class Placeholder extends StatelessWidget {
  const Placeholder({
    this.swatch = SemanticSwatch.neutral,
    this.padding,
    this.child,
    super.key,
  });

  /// The meaning to wear — neutral by default: absence is quiet.
  final SemanticSwatch swatch;

  final EdgeInsetsGeometry? padding;

  /// What stands in for the missing thing — a label, an icon. Centerd when
  /// the box is bigger than it.
  final Widget? child;

  @override
  Widget build(BuildContext context) => Surface(
    variant: SurfaceVariant.placeholder,
    swatch: swatch,
    padding: padding,
    // Factors of 1 size the box to the child when constraints are loose;
    // tight constraints win anyway, and then the child sits centerd. The
    // gap keeps the stripes from running behind the child.
    child: Center(
      widthFactor: 1,
      heightFactor: 1,
      child: child == null ? const SizedBox.shrink() : StripeGap(child: child),
    ),
  );
}
