import 'package:tomeui/tomeui.dart';

/// The root of a Tome application: [WidgetsApp] dressed by a [Theme].
///
/// This is the stand-in for `MaterialApp` — navigation, localizations, title,
/// and restoration come from [WidgetsApp]; the theme, the page background,
/// the default text style, and the default icon look come from [Theme].
/// Everything below it can ask [ThemeProvider.of] for tokens and never name
/// a color.
///
/// Two constructors, matching [WidgetsApp]: the default takes [home], the
/// pages map, and friends; [TomeApp.router] takes a [routerConfig] instead.
class TomeApp extends StatelessWidget {
  const TomeApp({
    this.theme = const Theme(),
    this.title = '',
    this.onGenerateTitle,
    this.home,
    this.routes = const {},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorKey,
    this.navigatorObservers = const [],
    this.builder,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales = const [Locale('en', 'US')],
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.debugShowCheckedModeBanner = true,
    super.key,
  }) : routerConfig = null;

  const TomeApp.router({
    required this.routerConfig,
    this.theme = const Theme(),
    this.title = '',
    this.onGenerateTitle,
    this.builder,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales = const [Locale('en', 'US')],
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.debugShowCheckedModeBanner = true,
    super.key,
  }) : home = null,
       routes = const {},
       initialRoute = null,
       onGenerateRoute = null,
       onUnknownRoute = null,
       navigatorKey = null,
       navigatorObservers = const [];

  final Theme theme;

  final String title;
  final GenerateAppTitle? onGenerateTitle;

  final Widget? home;
  final Map<String, WidgetBuilder> routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final RouteFactory? onUnknownRoute;
  final GlobalKey<NavigatorState>? navigatorKey;
  final List<NavigatorObserver> navigatorObservers;

  /// Router-mode navigation — a `go_router` config drops straight in.
  final RouterConfig<Object>? routerConfig;

  final TransitionBuilder? builder;

  final Locale? locale;
  final Iterable<LocalizationsDelegate<Object?>>? localizationsDelegates;
  final Iterable<Locale> supportedLocales;

  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;
  final bool debugShowCheckedModeBanner;

  /// The chrome around every route: the page background and the resting icon
  /// look. Outside the caller's [builder], so what a builder inserts is
  /// already themed; inside [WidgetsApp], whose `textStyle` handles text.
  Widget _dress(BuildContext context, Widget? child) {
    final dressed = IconTheme(
      data: IconThemeData(color: theme.palette.text, size: theme.sizes.icon),
      child: ColoredBox(
        color: theme.palette.background,
        child: child ?? const SizedBox.shrink(),
      ),
    );
    return builder == null ? dressed : builder!(context, dressed);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = theme.typography.body.copyWith(color: theme.palette.text);

    final app = routerConfig != null
        ? WidgetsApp.router(
            routerConfig: routerConfig,
            title: title,
            onGenerateTitle: onGenerateTitle,
            // What the OS shows around the app — the task switcher card.
            color: theme.palette.primary.s400,
            textStyle: textStyle,
            builder: _dress,
            locale: locale,
            localizationsDelegates: localizationsDelegates,
            supportedLocales: supportedLocales,
            shortcuts: shortcuts,
            actions: actions,
            restorationScopeId: restorationScopeId,
            debugShowCheckedModeBanner: debugShowCheckedModeBanner,
          )
        : WidgetsApp(
            home: home,
            routes: routes,
            initialRoute: initialRoute,
            onGenerateRoute: onGenerateRoute,
            onUnknownRoute: onUnknownRoute,
            navigatorKey: navigatorKey,
            navigatorObservers: navigatorObservers,
            pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder b) =>
                TomePageRoute<T>(
                  settings: settings,
                  builder: b,
                  motion: theme.motion,
                ),
            title: title,
            onGenerateTitle: onGenerateTitle,
            color: theme.palette.primary.s400,
            textStyle: textStyle,
            builder: _dress,
            locale: locale,
            localizationsDelegates: localizationsDelegates,
            supportedLocales: supportedLocales,
            shortcuts: shortcuts,
            actions: actions,
            restorationScopeId: restorationScopeId,
            debugShowCheckedModeBanner: debugShowCheckedModeBanner,
          );

    return ThemeProvider(theme: theme, child: app);
  }
}
