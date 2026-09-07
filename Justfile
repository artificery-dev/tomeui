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

# The widget test suites across the workspace
test:
  @{{flutter}} test
  @(cd clickwheel && {{flutter}} test)
  @(cd playground && {{flutter}} test)

# Require one shared stable version and release notes across the libraries
versions:
  @python3 tool/release.py check-version

# Resolve, analyze, and test before publishing
check: versions bootstrap analyze test

# Publish all libraries in dependency order, or select tomeui/desktop/clickwheel.
# Preview: just publish all --dry-run. Upload: just publish all --force.
publish package="all" *args: check
  #!/usr/bin/env bash
  set -euo pipefail
  case '{{package}}' in
    all) packages=(. desktop clickwheel) ;;
    tomeui) packages=(.) ;;
    desktop|tomeui_desktop) packages=(desktop) ;;
    clickwheel|tomeui_clickwheel) packages=(clickwheel) ;;
    *) echo 'Expected all, tomeui, desktop, or clickwheel.' >&2; exit 2 ;;
  esac
  if [[ -n "$(git status --porcelain)" ]]; then
    echo 'Commit or stash changes before publishing.' >&2
    exit 1
  fi
  # A Git-free copy prevents the root .pubignore from hiding child packages.
  release_dir="$(mktemp -d)"
  trap 'rm -rf "$release_dir"' EXIT
  git archive HEAD | tar -x -C "$release_dir"
  for directory in "${packages[@]}"; do
    (cd "$release_dir/$directory" && '{{flutter}}' pub publish {{args}})
  done

# Build the web playground for GitHub Pages; use / for a root-domain deployment.
playground-web base_href="/tomeui/": bootstrap
  @(cd playground && '{{flutter}}' build web --release --base-href '{{base_href}}')
