import 'dart:async';

import 'package:tomeui/tomeui.dart';

/// The pointer, pinned: what a [NumberField]'s scrub needs from the
/// platform and nothing more.
///
/// Tome draws the scrub but doesn't own the pointer; that belongs to the
/// window system, and pinning it is a platform plugin's job. This seam
/// keeps the two apart. The toolkit talks only to [PointerLock.instance],
/// and by default that is a [NoPointerLock]: [lock] answers null, and a
/// scrub hides the cursor for the drag instead — the pointer still moves
/// underneath, and reappears wherever it got to.
///
/// A desktop app installs a real lock before [runApp]; one backed by the
/// `pointer_lock` plugin is the shape of it:
///
/// ```dart
/// void main() {
///   PointerLock.instance = PluginPointerLock();
///   runApp(const App());
/// }
/// ```
abstract class PointerLock {
  const PointerLock();

  /// The lock the toolkit talks to. [NoPointerLock] until an app installs
  /// one.
  static PointerLock instance = const NoPointerLock();

  /// Pin the pointer where it is. The session's [PointerLockSession.deltas]
  /// carry its movement until [PointerLockSession.release], which puts the
  /// cursor back where it was pinned. Null means the platform can't — the
  /// caller falls back to reading the pointer as it moves.
  Future<PointerLockSession?> lock();
}

/// One pinned stretch of pointer movement.
abstract class PointerLockSession {
  const PointerLockSession();

  /// Movement since the last event, in logical pixels.
  Stream<Offset> get deltas;

  /// Let the pointer go, back where it was pinned.
  Future<void> release();
}

/// The absence of a lock, worn where none exists.
class NoPointerLock extends PointerLock {
  const NoPointerLock();

  @override
  Future<PointerLockSession?> lock() async => null;
}
