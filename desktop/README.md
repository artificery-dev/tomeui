# TomeUI Desktop

Native window controls for [TomeUI](https://pub.dev/packages/tomeui), backed by
`window_manager`. Supports Linux, macOS, and Windows.

## Installation

```sh
flutter pub add tomeui tomeui_desktop
```

## Usage

Install the window adapter before claiming the window and starting the app:

```dart
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_desktop/tomeui_desktop.dart';

Future<void> main() async {
  installWindowShell();
  await TitleBar.claimWindow();
  runApp(const TomeApp(
    home: Scaffold(body: Center(child: Text('Hello, TomeUI'))),
  ));
}
```

TomeUI's `TitleBar` uses the installed adapter for dragging and window controls.
Applications that do not need native desktop window management can depend on
`tomeui` alone.

## License

[MIT](LICENSE), copyright © 2026 Chris Hendrickson.
