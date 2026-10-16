## Unreleased

- First release: `installPointerLock()` puts a Wayland `pointer-constraints` + `relative-pointer` backed `PointerLock` behind every `NumberField` scrub. Linux only; X11 and other platforms fall back to the toolkit's cursor-hiding drag.
