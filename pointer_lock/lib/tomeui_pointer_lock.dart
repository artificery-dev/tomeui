/// The pinned pointer behind Tome UI.
///
/// Tome itself never touches a platform channel; a [NumberField]'s scrub
/// talks to [PointerLock.instance], which is a [NoPointerLock] until
/// something better is installed. This package is the something better —
/// one call in `main` pins the pointer for every scrub:
///
/// ```dart
/// void main() {
///   installPointerLock();
///   runApp(const App());
/// }
/// ```
///
/// Linux only, and Wayland only, for now: the lock is the
/// `pointer-constraints` protocol, which holds the pointer where it is,
/// streams its movement through `relative-pointer`, and honours a position
/// hint on release so the cursor comes back to where it was pressed. Under
/// X11, or where the compositor lacks the protocols, [lock] answers null
/// and the field falls back to hiding the cursor for the drag.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

/// Install the native [PointerLock] as the one Tome talks to. Call before
/// [runApp]; idempotent, and a no-op off Linux.
void installPointerLock() {
  if (defaultTargetPlatform != TargetPlatform.linux || kIsWeb) return;
  if (PointerLock.instance is! WaylandPointerLock) {
    PointerLock.instance = const WaylandPointerLock();
  }
}

/// [PointerLock] over the `tomeui_pointer_lock` native plugin.
class WaylandPointerLock extends PointerLock {
  const WaylandPointerLock();

  static const MethodChannel _methods = MethodChannel('tomeui_pointer_lock');
  static const EventChannel _events = EventChannel(
    'tomeui_pointer_lock/events',
  );

  @override
  Future<PointerLockSession?> lock() async {
    // Listen before locking: the first movement after the pin is as real
    // as any other.
    final session = _WaylandSession(_events.receiveBroadcastStream());
    final locked = await _methods.invokeMethod<bool>('lock') ?? false;
    if (!locked) {
      await session._stop();
      return null;
    }
    return session;
  }
}

class _WaylandSession extends PointerLockSession {
  _WaylandSession(Stream<dynamic> events) {
    _subscription = events.listen(
      _onEvent,
      onError: _deltas.addError,
      onDone: _deltas.close,
    );
  }

  final StreamController<Offset> _deltas = StreamController<Offset>();
  late final StreamSubscription<dynamic> _subscription;
  bool _released = false;

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    switch (event['type']) {
      case 'motion':
        _deltas.add(
          Offset((event['dx'] as num).toDouble(), (event['dy'] as num).toDouble()),
        );
      case 'unlocked':
        // The compositor let go (focus moved, say). The session is over
        // whether or not the field has released it.
        unawaited(_stop());
    }
  }

  @override
  Stream<Offset> get deltas => _deltas.stream;

  @override
  Future<void> release() async {
    if (_released) return;
    _released = true;
    await WaylandPointerLock._methods.invokeMethod<void>('unlock');
    await _stop();
  }

  Future<void> _stop() async {
    _released = true;
    await _subscription.cancel();
    if (!_deltas.isClosed) await _deltas.close();
  }
}
