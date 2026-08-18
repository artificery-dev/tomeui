import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tomeui_playground/src/shell.dart';
import 'package:tomeui_playground/src/theme_config.dart';
import 'package:tomeui_playground/src/widgets/platform_widget.dart';

/// The playground app: platform-native chrome around the story shell. The
/// Tome theme under preview lives inside the canvas; the shell only borrows
/// its brightness, so the App tab's dark-mode toggle dims the chrome too.
class PlaygroundApp extends StatefulWidget {
  const PlaygroundApp({super.key});

  @override
  State<PlaygroundApp> createState() => _PlaygroundAppState();
}

class _PlaygroundAppState extends State<PlaygroundApp> {
  final ThemeConfig _config = ThemeConfig();

  @override
  void dispose() {
    _config.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _config,
    builder: (context, _) => PlatformWidget(
      cupertino: (_) => CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(brightness: _config.brightness),
        home: PlaygroundShell(config: _config),
      ),
      material: (_) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
        themeMode: _config.brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: PlaygroundShell(config: _config),
      ),
    ),
  );
}
