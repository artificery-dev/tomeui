# tomeui.
#
# This package stands alone, and is also consumed as a submodule of the
# dart-packages workspace. Run it either way:
#
#   just test              # from a standalone clone
#   just tomeui test       # from the dart-packages workspace root
#
# Recipes here run with the working directory set to this package, so paths
# are relative to it.

fvm_flutter := source_directory() / '..' / '..' / '.fvm/flutter_sdk/bin/flutter'

# Prefer the workspace's fvm-pinned SDK when this package sits inside it;
# fall back to whatever `flutter` is on PATH for a standalone clone.
flutter := if path_exists(fvm_flutter) == "true" { fvm_flutter } else { "flutter" }

default:
  @just --list

# Resolve Flutter dependencies. Run once after cloning.
bootstrap:
  @{{flutter}} pub get

# Analyze the Dart sources
analyze:
  @{{flutter}} analyze

# The widget test suite
test:
  @{{flutter}} test
