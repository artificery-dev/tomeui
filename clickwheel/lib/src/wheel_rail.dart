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
    this.focusNode,
    this.autofocus = false,
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

  /// The rail's focus, for an owner that needs to hand focus back to it.
  final FocusNode? focusNode;

  /// Take focus on appearing.
  final bool autofocus;

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
    _travel.addListener(_report);
  }

  @override
  void didUpdateWidget(WheelRail<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
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
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return Semantics(
              container: true,
              child: SizedBox(
                height: style.height,
                child: Surface.custom(
                  style: style.track,
                  padding: EdgeInsets.all(style.inset),
                  // The box alone moves: the options stay put, and a turn
                  // past the end carries the box out over the track's edge
                  // - so the stack must not clip - and back.
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: _box(theme, style, selected, focused),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < _count; i++)
                            Expanded(
                              child: _segment(theme, style, i, selected),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The box, on its way. Between options it is [_travel]'s share of the
  /// way from the option it is on; off an end it is the same share of the
  /// give, in pixels. It is the wheel's mark, so it is there only while the wheel
  /// is on the rail: when focus has gone up to something else the box
  /// fades where it stands, and comes back there when the wheel returns.
  Widget _box(
    Theme theme,
    SegmentedControlStyle style,
    int selected,
    bool focused,
  ) {
    final showing = focused && selected >= 0;
    final weight = widget.physics.weight;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: showing ? 1.0 : 0.0),
      duration: theme.motion.fast,
      curve: showing ? theme.motion.enter : theme.motion.exit,
      builder: (context, presence, child) => presence == 0
          ? const SizedBox.shrink()
          : Opacity(
              opacity: presence,
              child: AnimatedBuilder(
                animation: _travel,
                child: child,
                builder: (context, child) {
                  final share = _travel.value / weight;
                  final direction = share.sign.toInt();
                  final index = selected < 0 ? 0 : selected;
                  final outward =
                      direction != 0 && _landing(index, direction) == null;
                  final position = outward ? index.toDouble() : index + share;
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
            ),
      child: Surface.custom(style: style.indicator),
    );
  }

  Widget _segment(
    Theme theme,
    SegmentedControlStyle style,
    int index,
    int selected,
  ) {
    final segment = widget.segments[index];
    final chosen = index == selected;
    final textStyle = chosen ? style.selectedStyle : style.unselectedStyle;

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
