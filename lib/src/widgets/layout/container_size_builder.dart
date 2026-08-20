import 'package:tomeui/tomeui.dart';

/// How much room a slot actually has, and what that width would be called.
class ContainerSize {
  const ContainerSize({
    required this.constraints,
    required this.breakpoint,
  });

  /// What the parent offered, verbatim — including an infinity, when the
  /// slot sits in something that scrolls that way.
  final BoxConstraints constraints;

  /// The band [width] falls in, by the theme's [Breakpoints] — the same
  /// names [BreakpointBuilder] uses, asked of this slot rather than of the
  /// window.
  final Breakpoint breakpoint;

  /// The room across, or infinity where there's no bound to speak of.
  double get width => constraints.maxWidth;

  /// The room down, or infinity in a vertically scrolling parent.
  double get height => constraints.maxHeight;

  bool get isBoundedWidth => constraints.hasBoundedWidth;
  bool get isBoundedHeight => constraints.hasBoundedHeight;
}

/// Builds against the space this widget was handed.
///
/// A [LayoutBuilder] that speaks the theme's vocabulary: the same
/// [Breakpoint] names as [BreakpointBuilder], resolved against the slot's
/// own width rather than the window's. A card that has to work in a sidebar
/// and in a page body asks this one — the window is wide either way; the
/// card is not.
///
/// ```dart
/// ContainerSizeBuilder(
///   builder: (context, size) => size.width < 320
///       ? Column(children: slots)
///       : Row(children: slots),
/// )
/// ```
class ContainerSizeBuilder extends StatelessWidget {
  const ContainerSizeBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, ContainerSize size) builder;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    return LayoutBuilder(
      builder: (context, constraints) => builder(
        context,
        ContainerSize(
          constraints: constraints,
          // An unbounded slot is as roomy as it gets: there is nothing
          // squeezing the layout, so nothing to fold up for.
          breakpoint: theme.breakpoints.at(
            constraints.hasBoundedWidth
                ? constraints.maxWidth
                : theme.breakpoints.expanded,
          ),
        ),
      ),
    );
  }
}
