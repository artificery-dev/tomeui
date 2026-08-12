import 'package:tomeui/tomeui.dart';

class ThemeProvider extends InheritedWidget {
  const ThemeProvider({super.key, required this.theme, required super.child});

  final Theme theme;

  static Theme of(BuildContext context) => maybeOf(context)!;

  static Theme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()?.theme;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return true;
  }
}
