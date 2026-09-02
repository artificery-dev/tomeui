import 'dart:async';

import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;
import 'package:tomeui/tomeui.dart';

import 'intents.dart';

/// How a [WheelList] row is drawn: the item at [index], told whether it is
/// the selected one. The list draws no chrome of its own around the row -
/// selection dress belongs to the row, which knows what it contains.
typedef WheelRowBuilder =
    Widget Function(BuildContext context, int index, bool selected);

/// A list the wheel drives.
///
/// Focus traversal walks *widgets*, which serves a screenful of controls
/// but not a library of ten thousand songs: a lazy list's unbuilt rows
/// aren't there to focus. So a [WheelList] holds focus as a single node and
/// owns a selected *index* instead. Jogs move the index, the viewport
/// follows, the selected row is painted selected, and the centre button
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
/// they make jump-to-index exact arithmetic at any length.
class WheelList extends StatefulWidget {
  /// The fixed shape: [children] given whole and unaware of the wheel. The
  /// list dresses the selected row itself - the primary bar an iPod puts
  /// under the cursor - so a main menu is just its rows.
  WheelList({
    required List<Widget> children,
    required this.itemExtent,
    this.onActivate,
    this.onSelectionChanged,
    this.initialIndex = 0,
    this.autofocus = false,
    super.key,
  }) : itemCount = children.length,
       itemBuilder = ((context, index, selected) =>
           _DressedRow(selected: selected, child: children[index]));

  /// The lazy shape: rows built on demand, told their selection.
  const WheelList.builder({
    required this.itemCount,
    required this.itemBuilder,
    required this.itemExtent,
    this.onActivate,
    this.onSelectionChanged,
    this.initialIndex = 0,
    this.autofocus = false,
    super.key,
  });

  final int itemCount;
  final WheelRowBuilder itemBuilder;

  /// One height for every row.
  final double itemExtent;

  /// The centre button, spoken to the selected index.
  final ValueChanged<int>? onActivate;

  /// The wheel moved the selection - for a preview pane, a scrubber, a
  /// sound. Not the activation.
  final ValueChanged<int>? onSelectionChanged;

  final int initialIndex;

  /// Take focus on appearing - on a device that is only a wheel, the list
  /// a screen exists for should.
  final bool autofocus;

  @override
  State<WheelList> createState() => _WheelListState();
}

/// The default selection dress for the fixed shape: the primary bar under
/// the cursor row, its text answering in the primary's contrast colour.
/// Builder rows skip this and dress themselves - a song row knows whether
/// its subtitle should dim.
class _DressedRow extends StatelessWidget {
  const _DressedRow({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    if (!selected) return child;
    return ColoredBox(
      color: theme.palette.primary.s500,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.palette.onPrimary),
        child: child,
      ),
    );
  }
}

class _WheelListState extends State<WheelList>
    with SingleTickerProviderStateMixin {
  late int _index = widget.initialIndex.clamp(0, widget.itemCount - 1);
  final _controller = ScrollController();

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
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _band.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// One visible page of rows, floored to a whole row so a page leap lands
  /// square.
  int get _rowsPerPage {
    if (!_controller.hasClients) return 1;
    final pixels = _controller.position.viewportDimension;
    return (pixels / widget.itemExtent).floor().clamp(1, widget.itemCount);
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
    final next = (_index + step).clamp(0, widget.itemCount - 1);
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
    final top = _index * widget.itemExtent;
    final bottom = top + widget.itemExtent;
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
                      // The cupertino feel, unconditionally, for whatever
                      // the viewport itself scrolls: detent jogs land
                      // exactly (jumps), a fling would ride a spring. The
                      // overscroll past an edge is the band's, above -
                      // nothing here springs against it.
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemExtent: widget.itemExtent,
                      itemCount: widget.itemCount,
                      itemBuilder: (context, index) {
                        final selected = focused && index == _index;
                        return widget.itemBuilder(context, index, selected);
                      },
                    ),
                    widget.itemCount * widget.itemExtent >
                        constraints.maxHeight + 0.5,
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
