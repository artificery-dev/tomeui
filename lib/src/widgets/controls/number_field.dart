import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

/// A number you can drag as well as type.
///
/// A [TextField] with a scrub on top, the way a 3D tool's fields work:
/// press and drag sideways and the value slides with the pointer,
/// [step] per pixel (a tenth of that with Shift held); click without
/// dragging and the box opens for typing, with the number selected. Enter
/// or leaving the box commits; Escape puts the old value back.
///
/// While scrubbing the pointer is pinned through [PointerLock], so a long
/// drag never runs off the field or the window, and the cursor returns to
/// where it was pressed. Without a lock installed the cursor is hidden for
/// the drag instead.
///
/// ```dart
/// NumberField(
///   value: spacing,
///   min: 2,
///   max: 256,
///   suffix: const Text('px'),
///   onChanged: (value) => setState(() => spacing = value),
/// )
/// ```
class NumberField extends StatefulWidget {
  const NumberField({
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.decimals = 0,
    this.label,
    this.suffix,
    this.enabled = true,
    this.variant = SurfaceVariant.outline,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  }) : assert(step > 0, 'step must be positive'),
       assert(decimals >= 0, 'decimals must not be negative');

  final double value;

  /// Called with every change — each pixel of a scrub, and a typed value
  /// on commit. Null disables the field.
  final ValueChanged<double>? onChanged;

  /// Clamps for both scrubbing and typing. Null is unbounded.
  final double? min;
  final double? max;

  /// How far one pixel of drag moves the value.
  final double step;

  /// Digits after the point, for display and for rounding what's typed.
  final int decimals;

  /// The words above the box.
  final Widget? label;

  /// A unit after the number: `px`, `%`, `°`.
  final Widget? suffix;

  final bool enabled;
  final SurfaceVariant variant;
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final TextFieldStyle? style;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'NumberField');

  /// Open for typing. Until then the box only shows the number and the
  /// pointer scrubs it.
  bool _editing = false;

  /// The scrub in progress, if any.
  _Scrub? _scrub;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _controller.text = _format(widget.value);
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing &&
        (widget.value != oldWidget.value ||
            widget.decimals != oldWidget.decimals)) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _scrub?.cancel();
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) => value.toStringAsFixed(widget.decimals);

  double _clamp(double value) {
    var v = value;
    if (widget.min case final min?) v = v < min ? min : v;
    if (widget.max case final max?) v = v > max ? max : v;
    return v;
  }

  void _report(double value) {
    final next = _clamp(value);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  // Typing.

  void _open() {
    setState(() => _editing = true);
    _focus.requestFocus();
    // The whole number, so typing replaces it.
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed != null) {
      final rounded = double.parse(parsed.toStringAsFixed(widget.decimals));
      _report(rounded);
    }
    _close();
  }

  void _revert() {
    _close();
  }

  void _close() {
    if (!mounted) return;
    setState(() {
      _editing = false;
      // Whatever was typed, the box shows what the value *is*.
      _controller.text = _format(widget.value);
    });
    if (_focus.hasFocus) _focus.unfocus();
  }

  void _focusChanged() {
    if (!_focus.hasFocus && _editing) _commit();
  }

  // Scrubbing.

  void _pointerDown(PointerDownEvent event) {
    if (!_enabled || _editing || event.buttons != kPrimaryMouseButton) return;
    _scrub = _Scrub(start: widget.value, pointer: event.pointer);
    // Ask for the pin; until it answers (if it answers) raw movement
    // drives the value, so the first pixels are never lost.
    unawaited(_pin(_scrub!));
  }

  Future<void> _pin(_Scrub scrub) async {
    final session = await PointerLock.instance.lock();
    if (session == null) return;
    if (_scrub != scrub) {
      // Released before the lock arrived.
      await session.release();
      return;
    }
    scrub.session = session;
    scrub.subscription = session.deltas.listen((delta) => _slide(delta.dx));
    if (mounted) setState(() {});
  }

  void _pointerMove(PointerMoveEvent event) {
    final scrub = _scrub;
    if (scrub == null || scrub.pointer != event.pointer) return;
    // Once pinned, the platform reports movement; the raw stream stops
    // meaning anything.
    if (scrub.session == null) _slide(event.delta.dx);
  }

  void _slide(double dx) {
    final scrub = _scrub;
    if (scrub == null) return;
    scrub.travel += dx;
    final fine = HardwareKeyboard.instance.isShiftPressed;
    scrub.value += dx * widget.step * (fine ? 0.1 : 1);
    if (scrub.travel.abs() >= kTouchSlop) scrub.moved = true;
    if (scrub.moved) {
      final value = double.parse(scrub.value.toStringAsFixed(widget.decimals));
      _report(value);
    }
  }

  void _pointerUp(PointerEvent event) {
    final scrub = _scrub;
    if (scrub == null || scrub.pointer != event.pointer) return;
    _scrub = null;
    unawaited(scrub.cancel());
    if (event is PointerCancelEvent) return;
    if (scrub.moved) {
      if (mounted) setState(() {});
    } else {
      _open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _controller,
      focusNode: _focus,
      label: widget.label,
      trailing: widget.suffix,
      enabled: _enabled,
      readOnly: !_editing,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _commit(),
      variant: widget.variant,
      swatch: widget.swatch,
      style: widget.style,
    );

    if (_editing) {
      return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _revert},
        child: field,
      );
    }

    // Closed: the pointer belongs to the scrub, not the text. The field
    // underneath keeps its dress and its label and never sees the press.
    final pinned = _scrub?.session != null;
    return Semantics(
      slider: true,
      value: _format(widget.value),
      child: MouseRegion(
        cursor: !_enabled
            ? MouseCursor.defer
            : _scrub != null && (pinned || _scrub!.moved)
            ? SystemMouseCursors.none
            : SystemMouseCursors.resizeLeftRight,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _pointerDown,
          onPointerMove: _pointerMove,
          onPointerUp: _pointerUp,
          onPointerCancel: _pointerUp,
          child: IgnorePointer(child: field),
        ),
      ),
    );
  }
}

/// One press-and-drag on the number.
class _Scrub {
  _Scrub({required this.start, required this.pointer}) : value = start;

  final double start;
  final int pointer;

  /// The unrounded running value, so a fine step accumulates rather than
  /// being rounded away each pixel.
  double value;

  /// Pointer travel so far, to tell a click from a drag.
  double travel = 0;
  bool moved = false;

  PointerLockSession? session;
  StreamSubscription<Offset>? subscription;

  Future<void> cancel() async {
    // Let go first: the release is what the reader sees (the cursor comes
    // back), and the platform's stream ends with it.
    final session = this.session;
    final subscription = this.subscription;
    this.session = null;
    this.subscription = null;
    await session?.release();
    await subscription?.cancel();
  }
}
