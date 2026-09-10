import 'dart:async';

import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;
import 'package:tomeui/tomeui.dart';

import 'intents.dart';

/// Enables speed-sensitive scrolling for long lists beneath the app input.
class WheelAcceleration extends InheritedWidget {
  const WheelAcceleration({
    required this.enabled,
    this.surfaceBuilder,
    this.letterEntry = WheelList.letterEntry,
    this.letterIdle = WheelList.accelerationIdle,
    required super.child,
    super.key,
  });
  final bool enabled;

  /// How long the wheel must keep turning one way, in an ordered list,
  /// before the letters open.
  final Duration letterEntry;

  /// How long the letters stay open after the wheel goes still.
  final Duration letterIdle;

  static WheelAcceleration? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WheelAcceleration>();

  /// Dresses the letter overlay using the host app’s surface treatment.
  final Widget Function(BuildContext context, Widget child)? surfaceBuilder;
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WheelAcceleration>()
          ?.enabled ??
      false;
  @override
  bool updateShouldNotify(WheelAcceleration oldWidget) =>
      enabled != oldWidget.enabled ||
      surfaceBuilder != oldWidget.surfaceBuilder ||
      letterEntry != oldWidget.letterEntry ||
      letterIdle != oldWidget.letterIdle;
}

/// How a [WheelList] row is drawn: the item at [index], told whether it is
/// the selected one. The list draws no chrome of its own around the row -
/// selection dress belongs to the row, which knows what it contains.
typedef WheelRowBuilder =
    Widget Function(BuildContext context, int index, bool selected);

/// How tall the row at [index] is, for the lists whose rows are not all
/// the same height. See [WheelList.extentOf].
typedef WheelExtentBuilder = double Function(int index);

/// A list the wheel drives.
///
/// Focus traversal walks *widgets*, which serves a screenful of controls
/// but not a library of ten thousand songs: a lazy list's unbuilt rows
/// aren't there to focus. So a [WheelList] holds focus as a single node and
/// owns a selected *index* instead. Jogs move the index, the viewport
/// follows, the selected row is painted selected, and the center button
/// activates it ([onActivate]). The fast-spin tier ([JogIntent.page])
/// leaps by a visible page.
///
/// Two shapes, one model, like [ListView]:
///
/// ```dart
/// // The main menu: a handful of rows, given whole.
/// WheelList(
///   itemExtent: 40,
///   onActivate: open,
///   children: [for (final e in entries) MenuRow(e)],
/// )
///
/// // The library: thousands, built as the wheel reaches them.
/// WheelList.builder(
///   itemExtent: 40,
///   itemCount: songs.length,
///   itemBuilder: (context, index, selected) =>
///       SongRow(songs[index], selected: selected),
///   onActivate: play,
/// )
/// ```
///
/// Rows share one [itemExtent]: uniform rows are the wheel's rhythm, and
/// they make jump-to-index exact arithmetic at any length. A list whose
/// rows genuinely differ - a settings list where a slider tile carries a
/// track and a switch tile does not - gives [extentOf] instead, and pays
/// for it with a prefix sum over the rows rather than a multiplication.
class WheelList extends StatefulWidget {
  /// The fixed shape: [children] given whole and unaware of the wheel. The
  /// list dresses the selected row itself - a subtle wash of the primary
  /// under the cursor, the words in the primary's voice - so a main menu
  /// is just its rows.
  WheelList({
    required List<Widget> children,
    required this.itemExtent,
    this.onActivate,
    this.onSelectionChanged,
    this.extentOf,
    this.sectionOf,
    this.initialIndex = 0,
    this.initialTopRow = 0,
    this.autofocus = false,
    this.wrap = false,
    this.scrollPhysics,
    super.key,
  }) : itemCount = children.length,
       itemBuilder = ((context, index, selected) =>
           WheelRowDress(selected: selected, child: children[index]));

  /// The lazy shape: rows built on demand, told their selection.
  const WheelList.builder({
    required this.itemCount,
    required this.itemBuilder,
    required this.itemExtent,
    this.onActivate,
    this.onSelectionChanged,
    this.extentOf,
    this.sectionOf,
    this.initialIndex = 0,
    this.initialTopRow = 0,
    this.autofocus = false,
    this.wrap = false,
    this.scrollPhysics,
    super.key,
  });

  /// A section label for alphabetically ordered rows. Null rows are skipped
  /// by section navigation (for example, Back and Options above file names).
  final String? Function(int index)? sectionOf;

  static const bandKey = ValueKey('WheelList.band');

  /// The bar along the foot of the letters that shows the time left.
  static const lettersClockKey = ValueKey('WheelList.letters.clock');
  static const accelerationMinimum = 30;
  static const accelerationIdle = Duration(seconds: 1);
  static const accelerationEntry = Duration(milliseconds: 500);
  static const letterEntry = Duration(milliseconds: 600);
  static const modeTransition = Duration(milliseconds: 180);

  final int itemCount;
  final WheelRowBuilder itemBuilder;

  /// One height for every row - and, where [extentOf] is given, the
  /// nominal one: the scrollbar's shortest thumb, and the fallback before
  /// the rows are known.
  final double itemExtent;

  /// A height per row, for a list whose rows differ. Null means every row
  /// is [itemExtent], which is the common case and the cheaper one.
  ///
  /// It is called for every row on the way to any offset, so it must be
  /// cheap and it must not change its answer without the list being told:
  /// give a new function (or a new [itemCount]) and the offsets are
  /// recomputed, and nothing else invalidates them.
  final WheelExtentBuilder? extentOf;

  /// The center button, spoken to the selected index.
  final ValueChanged<int>? onActivate;

  /// The wheel moved the selection - for a preview pane, a scrubber, a
  /// sound. Not the activation.
  final ValueChanged<int>? onSelectionChanged;

  /// Whether a detent past the last row comes back to the first.
  ///
  /// Only a detent: a fast spin still stops at the end, because a page
  /// that wrapped would carry the selection somewhere nobody was
  /// looking, and the stretch at the edge is how a list says it has run
  /// out. A list of one row never wraps - there is nowhere to go.
  final bool wrap;

  /// Override gesture scrolling when an enclosing viewport owns the scroll.
  final ScrollPhysics? scrollPhysics;

  /// The selected row on entry. The initial viewport reveals this row before
  /// the first frame is painted, including when row heights differ.
  final int initialIndex;

  /// The row at the top of the viewport to begin with. Rows above it start
  /// scrolled off, and a jog up onto one brings it down into view - a way
  /// to keep a column's Back and its options a detent away without their
  /// taking the first screen. Clamped to what the list can scroll.
  final int initialTopRow;

  /// Take focus on appearing - on a device that is only a wheel, the list
  /// a screen exists for should.
  final bool autofocus;

  @override
  State<WheelList> createState() => _WheelListState();
}

/// The default selection dress for the fixed shape: [SurfaceVariant.soft]
/// in the primary swatch under the cursor row - a wash inside its own ring,
/// with the primary as the voice, so the row's words and glyphs answer in
/// the primary's color rather than the row turning into a bar of it.
///
/// Soft rather than subtle, which is the quieter neighbour: at subtle the
/// wash is the swatch's darkest stop in the dark and its lightest in the
/// light, and the cursor came out barely a shade off the page it sits on -
/// the row was being marked mostly by hue.
///
/// The fixed shape puts this on every row for you. A builder row dresses
/// itself - a song row knows whether its subtitle should dim, and a
/// picker row may want a card instead - and a builder row that wants
/// nothing more than the ordinary cursor wraps itself in this rather than
/// working the resolver out again. It carries the [WheelRowSelection] its
/// children read either way, so a row wrapped in it need not also be
/// wrapped in that.
class WheelRowDress extends StatelessWidget {
  const WheelRowDress({required this.selected, required this.child, super.key});

  final bool selected;
  final Widget child;

  /// The room a row keeps at the viewport's edges.
  ///
  /// Every row, not only the dressed one: a row that moved sideways as
  /// the cursor arrived on it would make the list step under the eye
  /// following it. The box appears; the words stay where they were.
  static EdgeInsets insetOf(Theme theme) =>
      EdgeInsets.symmetric(horizontal: theme.space.x2);

  /// The corners a dressed row wears: the small radius rather than the
  /// surface's own, since a cursor walking a list reads as a bar with its
  /// corners taken off and not as a pill.
  ///
  /// Anything else that marks a row - a trail's mark in a column browser,
  /// say - takes these too. It is the same box in another color, and two
  /// boxes of different shapes on one screen read as two ideas.
  static BorderRadius radiusOf(Theme theme) => theme.radii.small;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final inset = insetOf(theme);
    if (!selected) {
      return WheelRowSelection(
        selected: false,
        child: Padding(padding: inset, child: child),
      );
    }
    final dress = theme.widgets.surface.resolve(
      SemanticSwatch.primary,
      SurfaceVariant.soft,
    );
    // The whole surface: its wash and the ring it keeps around itself,
    // held off the viewport's edges, so it is a mark *on* the list rather
    // than the list changing color from edge to edge.
    return WheelRowSelection(
      selected: true,
      child: Padding(
        padding: inset,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dress.fill,
            border: dress.border == null
                ? null
                : Border.all(
                    color: dress.border!,
                    width: theme.strokes.hairline,
                  ),
            borderRadius: radiusOf(theme),
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: dress.foreground),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: dress.foreground),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether the row around this widget is the one the wheel is on.
///
/// The list dresses the selected row itself, so most rows never need to
/// ask. The ones that do are the rows that *behave* differently under the
/// cursor rather than only looking different - a name too long for its
/// line that scrolls while it is being read, a preview that only plays
/// where the wheel is.
///
/// Present around every row of the fixed shape. A row built by
/// [WheelList.builder] is told its selection outright, and can put one of
/// these around whatever needs to know.
class WheelRowSelection extends InheritedWidget {
  const WheelRowSelection({
    required this.selected,
    required super.child,
    super.key,
  });

  final bool selected;

  /// Whether the enclosing row is selected. False where there is no row -
  /// a tile on a page of its own is not under a cursor.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WheelRowSelection>()
          ?.selected ??
      false;

  @override
  bool updateShouldNotify(WheelRowSelection oldWidget) =>
      oldWidget.selected != selected;
}

class _WheelListState extends State<WheelList>
    with SingleTickerProviderStateMixin {
  late int _index = widget.initialIndex.clamp(0, widget.itemCount - 1);

  /// Where every row starts, and where the last one ends: `_offsets[i]` is
  /// the top of row `i` and `_offsets[itemCount]` is the whole list's
  /// height. Null while the rows are uniform, where the same answers are a
  /// multiplication away and an array would be a waste.
  List<double>? _offsets;

  late final ScrollController _controller;
  bool _controllerReady = false;

  /// Layout supplies the viewport before the scroll position is attached, so
  /// opening on a saved selection never paints the top and then jumps away.
  void _initializeScroll(double viewport) {
    if (_controllerReady) return;
    var offset = _offsetOf(widget.initialTopRow);
    if (widget.itemCount > 0) {
      final top = _offsetOf(_index);
      final bottom = top + _extentOf(_index);
      if (top < offset || bottom - top > viewport) {
        offset = top;
      } else if (bottom > offset + viewport) {
        offset = bottom - viewport;
      }
    }
    final padding = widget.initialTopRow == 0
        ? 0.0
        : (viewport - _extentBelowTopRow).clamp(0.0, double.infinity);
    final maximum = (_totalExtent + padding - viewport).clamp(
      0.0,
      double.infinity,
    );
    _controller = ScrollController(
      initialScrollOffset: offset.clamp(0.0, maximum),
    );
    _controllerReady = true;
  }

  /// The height of row [index].
  double _extentOf(int index) =>
      widget.extentOf?.call(index) ?? widget.itemExtent;

  /// The top of row [index], and - at `itemCount` - the bottom of the last.
  double _offsetOf(int index) {
    final offsets = _offsets;
    if (offsets == null) return index * widget.itemExtent;
    return offsets[index.clamp(0, offsets.length - 1)];
  }

  /// Every row's height, from the top down. Cheap enough to do outright:
  /// these are the lists short enough to have rows of their own shapes.
  void _measure() {
    if (widget.extentOf == null) {
      _offsets = null;
      return;
    }
    final offsets = List<double>.filled(widget.itemCount + 1, 0);
    for (var i = 0; i < widget.itemCount; i++) {
      offsets[i + 1] = offsets[i] + widget.extentOf!(i);
    }
    _offsets = offsets;
  }

  /// The whole list's height.
  double get _totalExtent => _offsetOf(widget.itemCount);

  /// The height of the rows from [WheelList.initialTopRow] down: what the
  /// list can fill without scrolling its head away.
  double get _extentBelowTopRow =>
      _totalExtent - _offsetOf(widget.initialTopRow);

  @override
  void initState() {
    super.initState();
    _measure();
    _readSections();
  }

  /// The overscroll rubber band, owned outright: [_band]'s value is how far
  /// the list is pulled past its edge, in logical pixels and signed the way a
  /// scroll offset is (positive past the bottom). We drive it ourselves and
  /// paint it as a translation, so the list never actually scrolls past its
  /// extent - the bouncing physics get nothing to spring against, which is the
  /// spring that used to fight each fresh jog and jitter.
  late final AnimationController _band = AnimationController.unbounded(
    vsync: this,
  );

  /// Set while the band is stretched; fires once the wheel goes still and lets
  /// the band go. Each further detent pushes it back, so an overscroll held by
  /// winding stays out until the winding actually stops.
  Timer? _restTimer;

  /// The band snaps home on this spring, critically damped (ratio 1) so it
  /// settles onto the edge without an overshoot that would itself read as a
  /// twitch.
  static final SpringDescription _settleSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 220, ratio: 1);

  /// How long the wheel must be still before the band lets go: comfortably
  /// longer than the gap between detents at a fast wind, so winding holds it
  /// out, and short enough that the release still feels immediate.
  static const Duration _restDelay = Duration(milliseconds: 110);

  @override
  void didUpdateWidget(WheelList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount ||
        widget.sectionOf != oldWidget.sectionOf) {
      _readSections();
      if (widget.itemCount != oldWidget.itemCount) _resetAcceleration();
    }
    if (widget.itemCount != oldWidget.itemCount && widget.itemCount > 0) {
      _index = _index.clamp(0, widget.itemCount - 1);
    }
    if (widget.itemCount != oldWidget.itemCount ||
        widget.extentOf != oldWidget.extentOf ||
        widget.itemExtent != oldWidget.itemExtent) {
      _measure();
    }
  }

  @override
  void dispose() {
    _resetAcceleration();
    _restTimer?.cancel();
    _band.dispose();
    if (_controllerReady) _controller.dispose();
    super.dispose();
  }

  /// One visible page of rows, floored to a whole row so a page leap lands
  /// square. Where the rows differ it is counted from the selected one -
  /// a page down from a tall row is fewer rows than a page down from a
  /// short one, which is what "a page" means on screen.
  int get _rowsPerPage {
    if (!_controllerReady || !_controller.hasClients) return 1;
    final pixels = _controller.position.viewportDimension;
    if (_offsets == null) {
      return (pixels / widget.itemExtent).floor().clamp(1, widget.itemCount);
    }
    var rows = 0;
    var filled = 0.0;
    for (var i = _index; i < widget.itemCount; i++) {
      filled += _extentOf(i);
      if (filled > pixels) break;
      rows++;
    }
    return rows.clamp(1, widget.itemCount);
  }

  /// The scroll axis's visible extent - the panel height a screen is laid out
  /// for, and the honest measure of how much give it can spare. Falls back to
  /// a few rows for the moment before the list is attached.
  double get _viewport => _controllerReady && _controller.hasClients
      ? _controller.position.viewportDimension
      : widget.itemExtent * 3;

  /// How far the band can stretch: a quarter of the panel of give. This is a
  /// fraction of the screen, not of a row - the panels the wheel drives are
  /// small, and a couple of rows of overscroll would be most of one. Past this
  /// the impulse below rounds to almost nothing, so winding on at the edge
  /// asymptotes here and visibly stops instead of sliding the list away.
  double get _overscrollLimit => _viewport * 0.25;

  /// The first detent-past-the-edge's push. Every later one gets only the
  /// fraction of this that the room left allows, so the band stiffens as it
  /// fills and each detent moves it less than the one before.
  double get _overscrollImpulse => _viewport * 0.07;

  bool get _stretched => _band.value.abs() > 0.5;

  /// Whether the list has anywhere to scroll: only a list longer than its
  /// viewport gets the rubber band. A list that fits is simply at its end
  /// - the last row is right there - and stretching it would say there is
  /// more when there is not.
  bool get _scrolls =>
      _controllerReady &&
      _controller.hasClients &&
      _controller.position.maxScrollExtent > 0;

  /// The bar's width, in logical pixels: thin, a stroke beside the rows.
  static const double barThickness = 2;

  /// The scrollbar: a track the height of the list and a thumb as long as
  /// the share of the list that is on screen - and never shorter than a
  /// row, so a library of ten thousand songs still has a thumb to see.
  /// Always there on a list that scrolls, and not there at all on one
  /// that does not: a bar on a list that fits would say there is more.
  Widget _scrollbar(BuildContext context, Widget list, bool scrolls) {
    if (!scrolls) return list;
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final thumb = theme.widgets.surface.resolve(
      SemanticSwatch.primary,
      SurfaceVariant.solid,
    );
    return RawScrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: barThickness,
      radius: const Radius.circular(barThickness / 2),
      minThumbLength: widget.itemExtent,
      thumbColor: thumb.fill,
      trackColor: theme.palette.divider.withValues(alpha: 0.4),
      trackBorderColor: const Color(0x00000000),
      child: list,
    );
  }

  Timer? _paceTimer;
  Timer? _entryTimer;
  bool _sustained = false;
  Timer? _accelerationTimer;
  int _burst = 0;
  int _direction = 0;
  bool _accelerated = false;
  bool _accelerationEnabled = false;
  bool _managedAcceleration = false;
  List<(String, int)> _sections = [];
  int? _letterSection;
  int? _gestureSection;
  bool get _letters => _accelerated && _sections.length > 1;

  /// The letters' timings, from [WheelAcceleration] or the defaults.
  Duration _letterEntry = WheelList.letterEntry;
  Duration _letterIdle = WheelList.accelerationIdle;

  /// Counts the wheel's words while the letters are up: each restarts the
  /// clock the overlay draws, and a new key restarts its animation.
  int _letterClock = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _accelerationEnabled = WheelAcceleration.of(context);
    final acceleration = WheelAcceleration.maybeOf(context);
    _letterEntry = acceleration?.letterEntry ?? WheelList.letterEntry;
    _letterIdle = acceleration?.letterIdle ?? WheelList.accelerationIdle;
    _managedAcceleration =
        context.getInheritedWidgetOfExactType<WheelAcceleration>() != null;
    if (!_accelerationEnabled) _resetAcceleration();
  }

  void _resetAcceleration() {
    _paceTimer?.cancel();
    _entryTimer?.cancel();
    _sustained = false;
    _accelerationTimer?.cancel();
    _burst = 0;
    _direction = 0;
    _accelerated = false;
    _letterSection = null;
    _gestureSection = null;
  }

  void _dismissAcceleration() {
    final section = _letterSection;
    final next = section == null ? _index : _sections[section].$2;
    _resetAcceleration();
    if (next != _index) {
      _index = next;
      widget.onSelectionChanged?.call(next);
    }
    if (section != null && _controllerReady && _controller.hasClients) {
      _controller.jumpTo(
        _offsetOf(next).clamp(0.0, _controller.position.maxScrollExtent),
      );
    }
  }

  void _readSections() {
    final sections = <(String, int)>[];
    final sectionOf = widget.sectionOf;
    if (sectionOf != null) {
      for (var i = 0; i < widget.itemCount; i++) {
        final label = sectionOf(i);
        if (label != null && (sections.isEmpty || sections.last.$1 != label)) {
          sections.add((label, i));
        }
      }
    }
    _sections = sections;
  }

  int get _sectionIndex {
    if (_letterSection != null) return _letterSection!;
    var section = 0;
    for (var i = 0; i < _sections.length; i++) {
      if (_sections[i].$2 > _index) break;
      section = i;
    }
    return section;
  }

  void _jog(JogIntent intent) {
    if (widget.itemCount == 0 || intent.amount == 0) return;
    final enabled =
        _accelerationEnabled &&
        widget.itemCount >= WheelList.accelerationMinimum;
    var fast = false;
    if (enabled) {
      final ordered = _sections.length > 1;
      // Letter browsing measures the whole gesture, including slow detents.
      // An idle pause or direction change starts its duration over.
      final restart = ordered
          ? _accelerationTimer?.isActive != true ||
                _direction != intent.amount.sign
          : _paceTimer?.isActive != true || _direction != intent.amount.sign;
      if (restart && !_letters) {
        _gestureSection = _sectionIndex;
        _burst = 0;
        _sustained = false;
        _entryTimer?.cancel();
        _entryTimer = Timer(
          ordered ? _letterEntry : WheelList.accelerationEntry,
          () {
            _sustained = true;
          },
        );
      }
      _direction = intent.amount.sign;
      _burst += intent.amount.abs();
      // Letter browsing stays latched until idle, even on slow or reversed turns.
      fast =
          _letters || (_sustained && (ordered || intent.page || _burst >= 4));
      _paceTimer?.cancel();
      _paceTimer = Timer(Duration(milliseconds: fast ? 160 : 90), () {});
      _accelerationTimer?.cancel();
      _accelerationTimer = Timer(
        ordered ? _letterIdle : WheelList.accelerationIdle,
        () {
          if (mounted) setState(_dismissAcceleration);
        },
      );
      _letterClock++;
    }
    final enteringLetters = !_accelerated && fast && _sections.length > 1;
    if (_accelerated != fast) setState(() => _accelerated = fast);
    if (enteringLetters) {
      // Keep the letter where this gesture began. The detent that opens the
      // picker must not also skip a letter after scrolling through rows.
      setState(() => _letterSection = _gestureSection ?? _sectionIndex);
      if (_stretched) _release();
      return;
    }
    if (_letters) {
      final section = (_sectionIndex + intent.amount).clamp(
        0,
        _sections.length - 1,
      );
      setState(() => _letterSection = section);
      if (_stretched) _release();
      return;
    }
    final multiplier = fast
        ? _rowsPerPage * (_burst >= 10 ? 2 : 1)
        : intent.page && !_managedAcceleration
        ? _rowsPerPage
        : 1;
    final step = intent.amount * multiplier;
    final last = widget.itemCount - 1;
    final wrapping = widget.wrap && !fast && !intent.page && last > 0;
    final int next;
    if (wrapping && _index + step < 0) {
      next = last;
    } else if (wrapping && _index + step > last) {
      next = 0;
    } else {
      next = (_index + step).clamp(0, last);
    }
    if (next == _index) {
      _stretch(step.sign);
      return;
    }
    setState(() => _index = next);
    _reveal(animate: fast);
    if (_stretched) _release();
    widget.onSelectionChanged?.call(next);
  }

  /// Already at an edge and still jogging that way: stretch the band further,
  /// by less the further it is already out, so a detent near [_overscrollLimit]
  /// barely moves it and the band stiffens to a halt. This replaces the old
  /// jump-past-the-extent, which the physics sprang straight back - the next
  /// detent landing mid-spring was the jitter. Nothing springs here; the band
  /// only grows, and only until the wheel goes still.
  void _stretch(int direction) {
    if (direction == 0 || !_scrolls) return;
    _band.stop();
    _restTimer?.cancel();
    final room = (_overscrollLimit - _band.value.abs()) / _overscrollLimit;
    if (room > 0) _band.value += _overscrollImpulse * room * direction;
    _restTimer = Timer(_restDelay, _release);
  }

  /// Let the band snap home. One spring on the one controller that held the
  /// stretch, so there is never a second animation to fight it - not when the
  /// wheel stops, not when a jog the other way resumes the list under it.
  void _release() {
    _restTimer?.cancel();
    if (_stretched) {
      _band.animateWith(SpringSimulation(_settleSpring, _band.value, 0, 0));
    } else {
      _band.value = 0;
    }
  }

  /// Keep the selection on screen: scroll the least distance that shows the
  /// whole row, the way a scrolled focus behaves.
  void _reveal({bool animate = false}) {
    if (!_controllerReady || !_controller.hasClients) return;
    final position = _controller.position;
    if (!animate && position.isScrollingNotifier.value) {
      _controller.jumpTo(position.pixels);
    }
    final top = _offsetOf(_index);
    final bottom = top + _extentOf(_index);
    double? target;
    if (top < position.pixels) {
      target = top;
    } else if (bottom > position.pixels + position.viewportDimension) {
      target = bottom - position.viewportDimension;
    }
    if (target != null) {
      final offset = target.clamp(0.0, position.maxScrollExtent);
      if (animate) {
        unawaited(
          _controller.animateTo(
            offset,
            duration: WheelList.modeTransition,
            curve: Curves.easeOutCubic,
          ),
        );
      } else {
        _controller.jumpTo(offset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        JogIntent: CallbackAction<JogIntent>(
          onInvoke: (intent) {
            _jog(intent);
            return null;
          },
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (_letters) {
              setState(_dismissAcceleration);
            } else if (widget.itemCount > 0) {
              widget.onActivate?.call(_index);
            }
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: widget.autofocus,
        debugLabel: 'WheelList',
        onFocusChange: (focused) {
          if (!focused && mounted) setState(_resetAcceleration);
        },
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            // The band paints as a translation over a list clipped to its own
            // box: the overscroll never becomes a real scroll position, so it
            // slides the rows past the edge and shows the ground behind them
            // without the viewport ever scrolling past its extent.
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _letters ? 0.92 : 1,
                  duration: WheelList.modeTransition,
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _letters ? 0.18 : 1,
                    duration: WheelList.modeTransition,
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: _band,
                        builder: (context, child) => Transform.translate(
                          key: WheelList.bandKey,
                          offset: Offset(0, -_band.value),
                          child: child,
                        ),
                        child: LayoutBuilder(
                          // Whether the rows outrun the box is known from the
                          // box, before the list has ever been laid out.
                          builder: (context, constraints) {
                            _initializeScroll(constraints.maxHeight);
                            return _scrollbar(
                              context,
                              ListView.builder(
                                controller: _controller,
                                // Room under the last row, when rows start scrolled
                                // off: the rows from [initialTopRow] must be able
                                // to fill the box on their own, or a short list
                                // could not scroll its top rows away at all.
                                padding: EdgeInsets.only(
                                  bottom: widget.initialTopRow == 0
                                      ? 0
                                      : (constraints.maxHeight -
                                                _extentBelowTopRow)
                                            .clamp(0.0, double.infinity),
                                ),
                                // The cupertino feel, unconditionally, for whatever
                                // the viewport itself scrolls: detent jogs land
                                // exactly (jumps), a fling would ride a spring. The
                                // overscroll past an edge is the band's, above -
                                // nothing here springs against it.
                                physics:
                                    widget.scrollPhysics ??
                                    const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                // One or the other: the framework takes a fixed
                                // extent or a builder for it, never both.
                                itemExtent: widget.extentOf == null
                                    ? widget.itemExtent
                                    : null,
                                itemExtentBuilder: widget.extentOf == null
                                    ? null
                                    : (index, _) => _extentOf(index),
                                itemCount: widget.itemCount,
                                itemBuilder: (context, index) {
                                  final selected = focused && index == _index;
                                  return widget.itemBuilder(
                                    context,
                                    index,
                                    selected,
                                  );
                                },
                              ),
                              // The rows past the top row: a list whose only give
                              // is its scrolled-off head has nothing to show a bar
                              // for.
                              _extentBelowTopRow > constraints.maxHeight + 0.5,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: WheelList.modeTransition,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.85, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                    child: _letters
                        ? _letterOverlay(context)
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _letterOverlay(BuildContext context) {
    final theme = ThemeProvider.of(context);
    final section = _sectionIndex;
    final primary = theme.widgets.surface
        .resolve(SemanticSwatch.primary, SurfaceVariant.soft)
        .foreground;
    final largeSize = (theme.typography.display.fontSize ?? 20) * 2.4;
    final smallSize = (theme.typography.caption.fontSize ?? 12) * 1.4;
    final rowHeight = largeSize * 1.2;
    final letters = SizedBox(
      width: largeSize * 2.5,
      height: rowHeight * 3,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: section.toDouble(), end: section.toDouble()),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          builder: (context, position, _) => Stack(
            children: [
              for (var i = 0; i < _sections.length; i++)
                if ((i - position).abs() < 2)
                  Positioned(
                    key: ValueKey(('letter', i)),
                    top: (1 + i - position) * rowHeight,
                    left: 0,
                    right: 0,
                    height: rowHeight,
                    child: Center(
                      child: Text(
                        _sections[i].$1,
                        style: theme.typography.display.copyWith(
                          color: Color.lerp(
                            DefaultTextStyle.of(context).style.color,
                            primary,
                            (1 - (i - position).abs()).clamp(0.0, 1.0),
                          ),
                          fontSize:
                              smallSize +
                              (largeSize - smallSize) *
                                  (1 - (i - position).abs()).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
    // The time left before the letters go, along the foot: a bar that
    // drains over the idle time and fills again at every word from the
    // wheel. The clock in the key restarts the tween.
    // As wide as the letters: the column sits in a FittedBox, which gives
    // it no width of its own to take a fraction of.
    final clock = SizedBox(
      width: largeSize * 2.5,
      height: theme.strokes.hairline * 3,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(('WheelList.letters.clock', _letterClock)),
          tween: Tween(begin: 1.0, end: 0.0),
          duration: _letterIdle,
          builder: (context, remaining, _) => FractionallySizedBox(
            key: WheelList.lettersClockKey,
            widthFactor: remaining,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(theme.strokes.hairline),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        theme.space.x4,
        theme.space.x4,
        theme.space.x4,
        theme.space.x2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          letters,
          SizedBox(height: theme.space.x2),
          clock,
        ],
      ),
    );
    final surfaceBuilder = context
        .dependOnInheritedWidgetOfExactType<WheelAcceleration>()
        ?.surfaceBuilder;
    return Center(
      key: const ValueKey('WheelList.letters'),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child:
            surfaceBuilder?.call(context, content) ??
            Surface(swatch: SemanticSwatch.neutral, child: content),
      ),
    );
  }
}
