import 'package:tomeui/tomeui.dart';

/// Builds against the window's width band.
///
/// The window, not the slot: this is the question a screen asks — "am I a
/// phone right now?" — and every widget that asks it gets the same answer,
/// which is what keeps a shell and the screens inside it from disagreeing
/// about which layout they're in. For the room a particular slot has, ask
/// [ContainerSizeBuilder] instead.
///
/// ```dart
/// BreakpointBuilder(
///   builder: (context, band) => band.atLeast(Breakpoint.expanded)
///       ? Row(children: [Rail(), Body()])
///       : Column(children: [Body(), Dock()]),
/// )
/// ```
///
/// The thresholds are the theme's [Breakpoints], so a theme with roomier
/// ideas moves every layout in the app at once.
class BreakpointBuilder extends StatelessWidget {
  const BreakpointBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, Breakpoint breakpoint) builder;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    return builder(context, theme.breakpoints.at(MediaQuery.sizeOf(context).width));
  }
}
