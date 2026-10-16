# TomeUI Pointer Lock

The pinned pointer behind [TomeUI](https://pub.dev/packages/tomeui)'s
`NumberField`: hold the cursor still while scrubbing, and put it back where
it was pressed on release. Linux (Wayland) today.

## Installation

```sh
flutter pub add tomeui tomeui_pointer_lock
```

## Usage

Install the lock before starting the app:

```dart
import 'package:tomeui/tomeui.dart';
import 'package:tomeui_pointer_lock/tomeui_pointer_lock.dart';

void main() {
  installPointerLock();
  runApp(const TomeApp(home: ...));
}
```

Every `NumberField` then pins the pointer for its drag. Off Linux, or under
X11, nothing is installed and the field hides the cursor for the drag
instead.

## How

The lock is the Wayland `pointer-constraints` protocol — the compositor
holds the pointer — with `relative-pointer` for movement and a cursor
position hint so the unlock lands the cursor on the press point. Bindings
are generated at build time by `wayland-scanner`, so building needs
`wayland-protocols` and `wayland-scanner` installed (they ship with every
Wayland desktop's development packages).

## License

[MIT](LICENSE), copyright © 2026 Chris Hendrickson.
