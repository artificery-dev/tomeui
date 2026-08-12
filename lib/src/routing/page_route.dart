import 'package:tomeui/tomeui.dart';

/// The system's page transition: a short fade with a slight rise, on the
/// motion tokens. What `Navigator.push` gets when a route is built by
/// [TomeApp], and what to reach for when pushing one by hand.
class TomePageRoute<T> extends PageRouteBuilder<T> {
  TomePageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
         transitionDuration: Motion.standard,
         reverseTransitionDuration: Motion.standard,
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: _transition,
       );

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: Motion.enter,
      reverseCurve: Motion.exit,
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
