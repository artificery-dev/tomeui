# Changelog

## 0.2.0

- Adopt a shared version and automated releases for all TomeUI libraries.
- Update the core TomeUI dependency to `^0.2.0`.

## 0.1.0

- Moved into the tomeui repository as `clickwheel/` and renamed
  `tomeui_clickwheel` (was `tomeui_click_wheel`, beside its consumer).
- `ClickWheelInput` claims the wheel's keys at its focus scope, so the
  framework's own shortcuts above the navigator no longer hear them a
  second time. A physical press of the center used to raise two
  `ActivateIntent`s (one from the global ear, one from `WidgetsApp`'s
  Enter shortcut on the focused list), which pushed every screen twice and
  took two presses of back to leave.
- The package exists: `ClickWheelInput` (one wrapper turning the hardware's
  keys into `JogIntent` / `ActivateIntent` / `WheelBackIntent` /
  `MediaIntent` / `VolumeIntent`, with tap-counted and held `PowerPress`
  chords and cupertino scroll physics installed app-wide), and `WheelList`
  (wheel-native selection over one scroll engine, in a fixed shape for
  menus and a lazy `.builder` shape for libraries, with edge-bounce).
  Jogs walk widget focus by default; a focused `WheelList` consumes them.
