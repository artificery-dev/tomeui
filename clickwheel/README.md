# TomeUI Clickwheel

Click-wheel input and navigation for [TomeUI](https://pub.dev/packages/tomeui).
Turn wheel movement and button presses into focus navigation, media commands,
volume changes, and configurable tap and hold gestures.

## Installation

```sh
flutter pub add tomeui tomeui_clickwheel
```

## Usage

Wrap the app's content in `ClickWheelInput`. Use `WheelList` for lists whose
selection should follow the wheel:

```dart
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_clickwheel/tomeui_clickwheel.dart';

void main() {
  runApp(TomeApp(
    home: ClickWheelInput(
      child: Scaffold(
        body: WheelList(
          autofocus: true,
          itemExtent: 48,
          onActivate: (index) => debugPrint('Selected row $index'),
          children: const [Text('Albums'), Text('Artists'), Text('Settings')],
        ),
      ),
    ),
  ));
}
```

- `WheelList.builder` builds long lists lazily.
- `WheelGrid` and `WheelRail` provide grid and rail selection.
- `InputCapture` temporarily handles selected wheel commands.
- `ClickWheelController` drives input from an emulator or other controls.
- `WheelFeel` and `DarkInput` configure navigation and behavior while asleep.

## License

[MIT](LICENSE), copyright © 2026 Chris Hendrickson.
