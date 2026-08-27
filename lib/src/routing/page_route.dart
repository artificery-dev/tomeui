import 'package:tomeui/tomeui.dart';

/// The system's page transition: a short fade with a slight rise, on the
/// motion tokens. What `Navigator.push` gets when a route is built by
/// [TomeApp] — which passes the theme's [Motion] — and what to reach for
/// when pushing one by hand.
class TomePageRoute<T> extends PageRouteBuilder<T> {
  TomePageRoute({
    required WidgetBuilder builder,
    Motion motion = const Motion(),
    super.settings,
    super.fullscreenDialog,
  }) : super(
         transitionDuration: motion.standard,
         reverseTransitionDuration: motion.standard,
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) =>
             _transition(motion, animation, child),
       );

  static Widget _transition(
    Motion motion,
    Animation<double> animation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: motion.enter,
      // Flipped: see the note on `SheetRoute`.
      reverseCurve: motion.exit.flipped,
    );
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(eased),
        child: child,
      ),
    );
  }
}
