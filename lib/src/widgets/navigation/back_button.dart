import 'package:tomeui/tomeui.dart';

/// The way back, when there is one.
///
/// Pops the nearest [Navigator], and draws nothing at all when that
/// navigator has nothing to pop — a back button on the first page of an app
/// is a button that lies. Put it in a [TitleBar]'s leading slot and it
/// appears and disappears with the stack:
///
/// ```dart
/// TitleBar(leading: const [BackButton()], title: Text(page.name))
/// ```
///
/// There is no forward twin: a [Navigator] keeps what you came from, not
/// where you were going, so an app that wants forward keeps that history
/// itself.
class BackButton extends StatelessWidget {
  const BackButton({
    this.onPressed,
    this.icon,
    this.label,
    this.variant = SurfaceVariant.ghost,
    this.swatch = SemanticSwatch.neutral,
    super.key,
  });

  /// Going back, when popping isn't what this means. Null pops the nearest
  /// navigator — and a button given one of these shows even where there's
  /// nothing to pop, since the caller has said what back means.
  final VoidCallback? onPressed;

  /// The glyph. Null takes the theme's [Icons.back].
  final IconData? icon;

  /// Words beside the glyph, for a bar with room for them. The screen
  /// reader hears [Labels.back] either way.
  final Widget? label;

  final SurfaceVariant variant;
  final SemanticSwatch swatch;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final navigator = Navigator.maybeOf(context);
    final canPop = navigator?.canPop() ?? false;
    if (onPressed == null && !canPop) return const SizedBox.shrink();

    return Semantics(
      label: theme.labels.back,
      child: Button(
        onPressed: onPressed ?? () => navigator!.maybePop(),
        variant: variant,
        swatch: swatch,
        leading: label == null ? null : Icon(icon ?? theme.icons.back),
        center: label ?? Icon(icon ?? theme.icons.back),
      ),
    );
  }
}
