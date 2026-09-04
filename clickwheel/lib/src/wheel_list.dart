import 'dart:async';

import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;
import 'package:tomeui/tomeui.dart';

import 'intents.dart';

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
    this.initialIndex = 0,
    this.initialTopRow = 0,
    this.autofocus = false,
    this.wrap = false,
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
    this.initialIndex = 0,
    this.initialTopRow = 0,
    this.autofocus = false,
    this.wrap = false,
    super.key,
  });

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
  const WheelRowDress({
    required this.selected,
    required this.child,
    super.key,
  });

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

  late final _controller = ScrollController(
    initialScrollOffset: _offsetOf(widget.initialTopRow),
  );

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
    _restTimer?.cancel();
    _band.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// One visible page of rows, floored to a whole row so a page leap lands
  /// square. Where the rows differ it is counted from the selected one -
  /// a page down from a tall row is fewer rows than a page down from a
  /// short one, which is what "a page" means on screen.
  int get _rowsPerPage {
    if (!_controller.hasClients) return 1;
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
  double get _viewport => _controller.hasClients
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
      _controller.hasClients && _controller.position.maxScrollExtent > 0;

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
    return RawScrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: barThickness,
      radius: const Radius.circular(barThickness / 2),
      minThumbLength: widget.itemExtent,
      thumbColor: theme.palette.text.withValues(alpha: 0.55),
      trackColor: theme.palette.divider.withValues(alpha: 0.4),
      trackBorderColor: const Color(0x00000000),
      child: list,
    );
  }

  void _jog(JogIntent intent) {
    if (widget.itemCount == 0) return;
    final step = intent.page ? intent.amount * _rowsPerPage : intent.amount;
    final last = widget.itemCount - 1;
    final wrapping = widget.wrap && !intent.page && last > 0;
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
    _reveal();
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
  void _reveal() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final top = _offsetOf(_index);
    final bottom = top + _extentOf(_index);
    double? target;
    if (top < position.pixels) {
      target = top;
    } else if (bottom > position.pixels + position.viewportDimension) {
      target = bottom - position.viewportDimension;
    }
    if (target != null) {
      _controller.jumpTo(target.clamp(0, position.maxScrollExtent));
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
            if (widget.itemCount > 0) widget.onActivate?.call(_index);
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: widget.autofocus,
        debugLabel: 'WheelList',
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            // The band paints as a translation over a list clipped to its own
            // box: the overscroll never becomes a real scroll position, so it
            // slides the rows past the edge and shows the ground behind them
            // without the viewport ever scrolling past its extent.
            return ClipRect(
              child: AnimatedBuilder(
                animation: _band,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -_band.value),
                  child: child,
                ),
                child: LayoutBuilder(
                  // Whether the rows outrun the box is known from the
                  // box, before the list has ever been laid out.
                  builder: (context, constraints) => _scrollbar(
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
                            : (constraints.maxHeight - _extentBelowTopRow)
                                  .clamp(0.0, double.infinity),
                      ),
                      // The cupertino feel, unconditionally, for whatever
                      // the viewport itself scrolls: detent jogs land
                      // exactly (jumps), a fling would ride a spring. The
                      // overscroll past an edge is the band's, above -
                      // nothing here springs against it.
                      physics: const BouncingScrollPhysics(
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
                        return widget.itemBuilder(context, index, selected);
                      },
                    ),
                    // The rows past the top row: a list whose only give
                    // is its scrolled-off head has nothing to show a bar
                    // for.
                    _extentBelowTopRow > constraints.maxHeight + 0.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
