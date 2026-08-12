# Tome UI

A Flutter UI toolkit built directly on the widgets layer, standalone from
material and cupertino.

The only Flutter surface it depends on is `flutter/widgets.dart`, which it
re-exports, so a single import covers both the toolkit and the widgets layer
beneath it:

```dart
import 'package:tomeui/tomeui.dart';
```

## Development

Recipes are in the `Justfile`:

```
just bootstrap   # resolve dependencies
just analyze     # analyze the Dart sources
just test        # run the widget test suite
```

From the dart-packages workspace root, prefix with the package name:
`just tomeui test`.
