import 'dart:async';

import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;
import 'package:tomeui/tomeui.dart';

import 'intents.dart';

/// How heavy a [WheelRail] is to turn, how far its box may leave the track,
/// and how it settles.
///
/// The defaults are tuned for a thumb on a wheel of twenty detents: half a
/// revolution moves the box one option, or carries it off an end, so a
/// choice next to Power Off is never a flick away.
@immutable
class WheelRailPhysics {
  const WheelRailPhysics({
    this.weight = 10,
    this.give = 8,
    this.rest = const Duration(milliseconds: 250),
    this.snap = const SpringDescription(mass: 1, stiffness: 220, damping: 30),
  });

  /// Detents from one option to the next, or to push the box off an end
  /// and let go. The box creeps the same fraction of the way with every
  /// detent, so the weight is visible as well as felt - and the option
  /// changes half way, as the box's center crosses the line between the
  /// two, so that a rest just past it clicks onto the new side.
  final int weight;

  /// How far past the track's edge the box travels on its way to letting
  /// go, in logical pixels: it is this far out on the detent that
  /// releases. An owner sets it to the room it has - a card's padding.
  final double give;

  /// How long the wheel must be still before a box on its way somewhere
  /// springs back to the option it left, and the turn starts over.
  final Duration rest;

  /// The spring the box settles on. Critically damped by default, so it
  /// lands without an overshoot that would read as a twitch.
  final SpringDescription snap;

  WheelRailPhysics copyWith({
    int? weight,
    double? give,
    Duration? rest,
    SpringDescription? snap,
  }) => WheelRailPhysics(
    weight: weight ?? this.weight,
    give: give ?? this.give,
    rest: rest ?? this.rest,
    snap: snap ?? this.snap,
  );

  @override
  bool operator ==(Object other) =>
      other is WheelRailPhysics &&
      other.weight == weight &&
      other.give == give &&
      other.rest == rest &&
      other.snap == snap;

  @override
  int get hashCode => Object.hash(weight, give, rest, snap);
}

/// A hand on a [WheelRail], for an owner that drives it rather than
/// letting it listen for itself.
///
/// A rail inside a list cannot hold focus of its own - the list holds it,
/// and hands it on for a while ([InputCapture]) - so the words the rail
/// answers to arrive at the owner instead. This is how they get in:
///
/// ```dart
/// InputCapture(
///   active: captured,
///   onCapture: (intent) {
///     if (intent case JogIntent()) rail.jog(intent);
///   },
///   child: WheelRail(controller: rail, ...),
/// )
/// ```
///
/// A rail with a controller installs no focus and no actions of its own:
/// it is driven, and it draws.
class WheelRailController {
  _WheelRailState<Object?>? _rail;

  /// Whether a rail is listening to this controller right now.
  bool get attached => _rail != null;

  /// The wheel turned.
  void jog(JogIntent intent) => _rail?._jog(intent);

  /// The center button.
  void activate() => _rail?._activate();

  /// Walk the box one option, without the weight: what a media key does
  /// on the power dialog, where left and right step the rail.
  void step(int by) => _rail?._step(by);
}

/// A track of options the wheel drives, with a box that slides to the one
/// under the thumb.
///
/// The [SegmentedControl]'s shape - one trough, the options side by side,
/// an indicator that slides to the answer - given the wheel's grammar and
/// some weight. The box does not hop: every detent moves it a fraction of
/// the way to the next option, [WheelRailPhysics.weight] detents from one
/// to the next, and the option changes as the box's center crosses the
/// line between them. Stop anywhere and the box settles onto the side it
/// is on - so just past the line it clicks over, and short of it, back.
/// The center button activates the option under it ([onActivate]), and
/// the rail holds focus as one node, the way a [WheelList] does.
///
/// At either end the same turn carries the box out over the track's edge -
/// never further than [WheelRailPhysics.give] - and on the detent that
/// completes it the rail lets go: the box snaps home and [onRelease] says
/// which way the wheel was pushing, so whoever owns the screen can hand
/// focus on to what lies that way.
///
/// Controlled, like the segmented control: [value] is the option under the
/// box, [onChanged] is asked to move it, so the owner can put the box
/// where it likes when focus comes back to the rail.
///
/// ```dart
/// WheelRail<PowerCommand>(
///   value: command,
///   onChanged: (next) => setState(() => command = next),
///   onActivate: perform,
///   onRelease: (_) => closeButton.requestFocus(),
///   segments: const [
///     SegmentOption(value: PowerCommand.restart, label: Text('Restart')),
///     SegmentOption(value: PowerCommand.shutDown, label: Text('Power Off')),
///   ],
/// )
/// ```
class WheelRail<T> extends StatefulWidget {
  const WheelRail({
    required this.segments,
    required this.value,
    required this.onChanged,
    this.onActivate,
    this.onRelease,
    this.onMoved,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.lit = true,
    this.physics = const WheelRailPhysics(),
    this.variant = SurfaceVariant.solid,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  }) : assert(segments.length > 0, 'A wheel rail needs segments.');

  final List<SegmentOption<T>> segments;

  /// The option under the box, or null for none - in which case the first
  /// detent lands on the near end.
  final T? value;

  /// The wheel brought the box to another option.
  final ValueChanged<T> onChanged;

  /// The center button, spoken to the option under the box.
  final ValueChanged<T>? onActivate;

  /// The wheel carried the box off an end and the rail let go: +1 past the
  /// last option, -1 past the first. Null makes the rail hold on: the box
  /// goes out as far as the give and waits there.
  final ValueChanged<int>? onRelease;

  /// Where the box is, in options from the first - the index of [value]
  /// plus however far along it is toward the next - every time it moves,
  /// for a screen that moves with it.
  final ValueChanged<double>? onMoved;

  /// A hand on the rail, for an owner that drives it.
  ///
  /// Given one, the rail keeps no focus and no actions: the owner decides
  /// when the wheel is the rail's - a settings row that has been activated,
  /// a dialog that is up - and passes the words in. Without one the rail
  /// holds focus as a single node and listens for itself, the way a
  /// [WheelList] does.
  final WheelRailController? controller;

  /// The rail's focus, for an owner that needs to hand focus back to it.
  /// Ignored when a [controller] drives it.
  final FocusNode? focusNode;

  /// Take focus on appearing. Ignored when a [controller] drives it.
  final bool autofocus;

  /// Whether the box is lit: the mark that says the wheel is on this rail.
  ///
  /// A rail that listens for itself knows this from its focus. A driven
  /// one cannot - the focus is the owner's - so the owner says.
  final bool lit;

  final WheelRailPhysics physics;

  final SurfaceVariant variant;

  /// The meaning the box wears.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme. The rail dresses in the
  /// segmented control's clothes.
  final SegmentedControlStyle? style;

  @override
  State<WheelRail<T>> createState() => _WheelRailState<T>();
}

class _WheelRailState<T> extends State<WheelRail<T>>
    with SingleTickerProviderStateMixin {
  FocusNode? _ownNode;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'WheelRail'));

  /// How far the box is from the center of the option it is on, in
  /// detents, signed the way the wheel turns: positive toward the last
  /// option. Never as much as half a weight between options - past that
  /// the box is on the next one, and this counts from there - and never a
  /// whole weight off an end, at which the rail has let go.
  late final AnimationController _travel =
      AnimationController.unbounded(vsync: this)..addStatusListener((status) {
        // A spring stops within a tolerance of home, not at it: land the
        // box on the pixel once the simulation is done.
        if (status == AnimationStatus.completed) _travel.value = 0;
      });

  Timer? _restTimer;

  /// Set while a jog is being walked: the travel moves several times in
  /// the walk, against an index the owner has not seen yet, and only where
  /// it ends up is worth reporting.
  bool _walking = false;

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
    _travel.addListener(_report);
  }

  @override
  void didUpdateWidget(WheelRail<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _detach(oldWidget.controller);
      _attach(widget.controller);
    }
    // The owner moved the box - or agreed to the move this rail asked for,
    // in which case the travel is already spent.
    if (widget.value != oldWidget.value) {
      _settle();
      // After the frame: this is the middle of a build, and whoever hears
      // where the box is may well rebuild on it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _report();
      });
    }
  }

  void _report() {
    if (_walking) return;
    _reportAt(_selected);
  }

  /// Where the box is, counted from [index] - the owner's, or the one a
  /// walk has reached ahead of the owner.
  void _reportAt(int index) {
    final onMoved = widget.onMoved;
    if (onMoved == null) return;
    final from = index < 0 ? 0 : index;
    onMoved(from + _travel.value / widget.physics.weight);
  }

  @override
  void dispose() {
    _detach(widget.controller);
    _restTimer?.cancel();
    _travel.dispose();
    _ownNode?.dispose();
    super.dispose();
  }

  int get _selected =>
      widget.segments.indexWhere((segment) => segment.value == widget.value);

  int get _count => widget.segments.length;

  /// The next option [by] from [index] that can be landed on, or null at
  /// the end of the rail.
  int? _landing(int index, int by) {
    for (index += by; index >= 0 && index < _count; index += by) {
      if (widget.segments[index].enabled) return index;
    }
    return null;
  }

  /// Nothing chosen yet: the first detent lands on the near end.
  int? _nearEnd(int by) => _landing(by > 0 ? -1 : _count, by);

  void _attach(WheelRailController? controller) {
    controller?._rail = this as _WheelRailState<Object?>;
  }

  void _detach(WheelRailController? controller) {
    if (identical(controller?._rail, this)) controller!._rail = null;
  }

  /// One option along, without the wheel's weight: a media key on the
  /// power dialog, an arrow on a desk. Stops at the ends.
  void _step(int by) {
    if (by == 0) return;
    final index = _selected;
    final next = index < 0 ? _nearEnd(by) : _landing(index, by.sign);
    if (next == null) return;
    _settle();
    widget.onChanged(widget.segments[next].value);
  }

  void _jog(JogIntent intent) {
    // A fast spin is one detent: the weight is the point.
    final detents = intent.page ? intent.amount.sign : intent.amount;
    final direction = detents.sign;
    if (direction == 0) return;

    _travel.stop();
    _restTimer?.cancel();

    // Walked against a local index: the owner has not rebuilt between
    // detents, and a long turn may cross an option on its way.
    var index = _selected;
    var moved = false;
    if (index < 0) {
      final near = _nearEnd(direction);
      if (near == null) return;
      index = near;
      moved = true;
      _travel.value = 0;
    }

    final weight = widget.physics.weight.toDouble();
    _walking = true;
    try {
      _walk(detents, direction, index, moved, weight);
    } finally {
      _walking = false;
    }
  }

  void _walk(int detents, int direction, int index, bool moved, double weight) {
    for (var i = 0; i < detents.abs(); i++) {
      _travel.value += direction;
      // Which way the box is leaning now - not always the way the wheel
      // turns, once it has crossed onto a new option and is coming back.
      final leaning = _travel.value.sign.toInt();
      final next = leaning == 0 ? null : _landing(index, leaning);
      if (next != null) {
        // Between two options the line is half way: past it the box is
        // on the next one, and its travel is counted from there.
        if (_travel.value.abs() * 2 <= weight) continue;
        index = next;
        moved = true;
        _travel.value -= weight * leaning;
        continue;
      }
      // Off an end there is no line to cross, only the give to run out.
      if (widget.onRelease == null) {
        // Nobody to let go to: the box goes out as far as the give and
        // stays.
        _travel.value = _travel.value.clamp(-weight, weight);
        continue;
      }
      if (_travel.value.abs() < weight) continue;
      _travel.value = 0;
      if (moved) widget.onChanged(widget.segments[index].value);
      _reportAt(index);
      widget.onRelease!(leaning);
      return;
    }

    if (moved) widget.onChanged(widget.segments[index].value);
    // Once, where the walk ended, against the index it ended on.
    _reportAt(index);
    if (_travel.value != 0) _restTimer = Timer(widget.physics.rest, _settle);
  }

  /// Spring the box onto the option it is on.
  void _settle() {
    _restTimer?.cancel();
    if (_travel.value.abs() > 0.01) {
      _travel.animateWith(
        SpringSimulation(widget.physics.snap, _travel.value, 0, 0),
      );
    } else {
      _travel.value = 0;
    }
  }

  void _activate() {
    final index = _selected;
    if (index < 0) return;
    widget.onActivate?.call(widget.segments[index].value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style =
        widget.style ??
        theme.widgets.segmented.resolve(widget.swatch, widget.variant);
    final selected = _selected;

    // Driven from outside: no focus of its own to take, and no actions to
    // catch words that were never dispatched here. [lit] is the owner's to
    // say - it is the one that knows whether the wheel is here.
    if (widget.controller != null) {
      return Builder(
        builder: (context) => _track(theme, style, selected, widget.lit),
      );
    }

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
            _activate();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _focus,
        autofocus: widget.autofocus,
        child: Builder(
          builder: (context) =>
              _track(theme, style, selected, Focus.of(context).hasFocus),
        ),
      ),
    );
  }

  /// The trough, the options, and the box over them.
  Widget _track(
    Theme theme,
    SegmentedControlStyle style,
    int selected,
    bool lit,
  ) => Semantics(
    container: true,
    child: SizedBox(
      height: style.height,
      child: Surface.custom(
        style: style.track,
        padding: EdgeInsets.all(style.inset),
        // The box alone moves: the options stay put, and a turn past the
        // end carries the box out over the track's edge - so the stack
        // must not clip - and back.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: _box(theme, style, selected, lit)),
            Row(
              children: [
                for (var i = 0; i < _count; i++)
                  Expanded(child: _segment(theme, style, i, selected, lit)),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  /// The box, on its way. Between options it is [_travel]'s share of the
  /// way from the option it is on; off an end it is the same share of the
  /// give, in pixels.
  ///
  /// The box says two things at once, so it has two dresses. That the wheel
  /// is on this rail: filled, at the swatch's full voice. And, whether the
  /// wheel is here or not, which answer the rail is set to: the same shape
  /// in outline. It used to fade out altogether when focus went up to the
  /// list, which left a row that plainly had a setting on it saying nothing
  /// about what that setting was.
  ///
  /// Between the two it lerps rather than crossfades - one box moving and
  /// changing weight, not two boxes trading places.
  Widget _box(
    Theme theme,
    SegmentedControlStyle style,
    int selected,
    bool focused,
  ) {
    // Nothing chosen is the one state with no box: a rail whose stored
    // answer is no longer on offer should not point at an answer.
    if (selected < 0) return const SizedBox.shrink();
    final weight = widget.physics.weight;
    final indicator = style.indicator;
    // What the resting box is drawn in: what the lit one is *filled* with,
    // which is the one color on the rail that means "this one".
    final ink = indicator.fill ?? indicator.foreground;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: focused ? 1.0 : 0.0),
      duration: theme.motion.fast,
      curve: focused ? theme.motion.enter : theme.motion.exit,
      builder: (context, lit, _) => AnimatedBuilder(
        animation: _travel,
        child: Surface.custom(
          style: indicator.copyWith(
            fill: Color.lerp(ink.withValues(alpha: 0), indicator.fill, lit),
            // Lit, the fill carries it and the ring goes; at rest the ring
            // is the whole of the box.
            border: Color.lerp(ink, indicator.border, lit),
          ),
        ),
        builder: (context, child) {
          final share = _travel.value / weight;
          final direction = share.sign.toInt();
          final outward =
              direction != 0 && _landing(selected, direction) == null;
          final position = outward ? selected.toDouble() : selected + share;
          final offset = outward ? share * widget.physics.give : 0.0;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / _count,
              alignment: Alignment(
                _count == 1 ? 0 : -1 + 2 * position / (_count - 1),
                0,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _segment(
    Theme theme,
    SegmentedControlStyle style,
    int index,
    int selected,
    bool lit,
  ) {
    final segment = widget.segments[index];
    final chosen = index == selected;
    // The chosen segment is read against the box, so its words follow the
    // box's dress: the indicator's own foreground while the box is filled,
    // and the color the outline is drawn in once it is only an outline -
    // otherwise a label picked to read on a solid fill (white, commonly)
    // would be left standing on the bare track.
    final textStyle = chosen
        ? (lit
              ? style.selectedStyle
              : style.selectedStyle.copyWith(
                  color: style.indicator.fill ?? style.indicator.foreground,
                ))
        : style.unselectedStyle;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: chosen,
      enabled: segment.enabled,
      child: Opacity(
        opacity: segment.enabled ? 1 : style.disabledOpacity,
        child: Padding(
          padding: style.segmentPadding,
          child: Center(
            child: AnimatedDefaultTextStyle(
              style: textStyle,
              duration: theme.motion.fast,
              curve: theme.motion.move,
              child: IconTheme.merge(
                data: IconThemeData(
                  color: textStyle.color,
                  size: style.iconSize,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (segment.leading != null) ...[
                      segment.leading!,
                      SizedBox(width: style.gap),
                    ],
                    Flexible(child: segment.label),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
