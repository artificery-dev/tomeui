# Tome UI

A Flutter UI toolkit built directly on the widgets layer, standalone from
material and cupertino.

The only Flutter surface it depends on is `flutter/widgets.dart`, which it
re-exports, so a single import covers both the toolkit and the widgets layer
beneath it:

```dart
import 'package:tomeui/tomeui.dart';
```

Requires Flutter 3.44 or newer and Dart 3.12.2 or newer.

## Installation

```sh
flutter pub add tomeui
```

Optional companion packages:

- [tomeui_desktop](https://pub.dev/packages/tomeui_desktop): native desktop
  window controls through `window_manager`.
- [tomeui_clickwheel](https://pub.dev/packages/tomeui_clickwheel): click-wheel
  input, focus navigation, and wheel-driven lists and grids.

## Usage

```dart
import 'package:tomeui/tomeui.dart';

void main() {
  runApp(const TomeApp(
    home: Scaffold(body: Center(child: Text('Hello, TomeUI'))),
  ));
}
```

Explore the widgets in the
[playground](https://github.com/artificery-dev/tomeui/tree/main/playground).

## Development

Recipes are in the `Justfile`:

```
just bootstrap   # resolve dependencies for the whole workspace
just analyze     # analyze the Dart sources
just test        # run the toolkit, clickwheel, and playground tests
just check       # resolve, analyze, and test
```

From the dart-packages workspace root, prefix with the package name:
`just tomeui test`.

The repository is a Dart workspace. Companion packages resolve `tomeui` locally
during development and from pub.dev when installed by consumers.

## Publishing

GitHub Actions validates pull requests and publishes shared version bumps merged
into `main` using a single `vX.Y.Z` tag. All three libraries use the same version
and publish together, in dependency order.
The commands below remain available for local validation and manual publishing.

Update all three package versions to the same stable `X.Y.Z`, update matching
dependency constraints and all three changelogs, then
commit the release changes before publishing. Each publish task resolves,
analyzes, and tests the workspace first, then publishes the committed files
from a temporary copy. Git and tar must be available on PATH.

```sh
just publish all --dry-run  # validate archives without uploading
just publish all --force   # publish tomeui, then desktop, then clickwheel
```

The playground is never published. Each child package is excluded from the
root package archive and published separately.

To resume an interrupted manual release, select a remaining package:

```sh
just publish desktop --force
just publish clickwheel --force
```

`tomeui`, `tomeui_desktop`, and `tomeui_clickwheel` are also accepted as package
selectors. Existing pub.dev versions must be bumped before publishing again.
Omit `--force` for pub's interactive confirmation. Pub uses your configured
Google account and prompts for authentication if needed.

To choose a Flutter SDK explicitly:

```sh
just --set flutter /path/to/flutter/bin/flutter publish all --dry-run
```

## License

TomeUI, including its desktop and clickwheel packages, is licensed under the
[MIT License](LICENSE), copyright © 2026 Chris Hendrickson.

Bundled fonts retain their own licenses: [Recursive (OFL 1.1)](fonts/Recursive-OFL.txt)
and [Symbols Nerd Font Mono and its component icon sets](fonts/SymbolsNerdFont-LICENSE.txt).
