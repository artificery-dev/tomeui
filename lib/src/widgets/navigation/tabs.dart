import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:tomeui/tomeui.dart';

import '../foundation/focus_ring.dart';

/// One tab a [Tabs] strip offers.
class TabOption<T> {
  const TabOption({
    required this.value,
    required this.label,
    this.icon,
    this.onClose,
    this.enabled = true,
  });

  /// What choosing this tab means.
  final T value;

  final Widget label;

  /// A glyph ahead of the label — what a tab of documents usually leads
  /// with, since a name alone is slower to find than a name with a shape.
  final IconData? icon;

  /// Shutting this tab. Null is a tab that can't be shut, and grows no
  /// button for it.
  ///
  /// The button keeps its place whether or not it's showing, so a strip
  /// doesn't shuffle under the pointer as it crosses one tab to reach
  /// another.
  final VoidCallback? onClose;

  final bool enabled;
}

/// In-page tabs: switching views, not places.
///
/// A [Dock] takes you somewhere; a tab strip changes what the page you're
/// already on is showing. The tab you're on wears the swatch at full voice
/// and the rest the quietest surface there is; they sit shoulder to
/// shoulder, rounded at the top and square at the bottom, where the pane
/// they open onto begins.
///
/// [TabOption.onClose] grows a button that shows on the tab you're on and
/// on whichever one the pointer is over — the way an editor's do.
///
/// ```dart
/// Tabs<Pane>(
///   value: pane,
///   onChanged: (value) => setState(() => pane = value),
///   tabs: [
///     TabOption(value: Pane.log, label: const Text('Log')),
///     TabOption(value: Pane.crew, label: const Text('Crew')),
///   ],
/// )
/// ```
///
/// The strip scrolls sideways when the tabs outrun it — a tab is a word
/// worth reading, so it keeps its width rather than being squeezed — and
/// the chosen tab is scrolled into view when it changes.
///
/// One focus stop for the whole strip, like a radio group: the arrows move
/// the choice, Home and End take the ends, and disabled tabs are stepped
/// over rather than landed on.
class Tabs<T> extends StatefulWidget {
  const Tabs({
    required this.value,
    required this.onChanged,
    required this.tabs,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  });

  /// The tab being shown, or null when nothing is.
  final T? value;

  /// Called with a tab's value when it's chosen. Null disables the strip.
  final ValueChanged<T>? onChanged;

  final List<TabOption<T>> tabs;

  /// The meaning the indicator wears.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final TabsStyle? style;

  @override
  State<Tabs<T>> createState() => _TabsState<T>();
}

class _TabsState<T> extends State<Tabs<T>> {
  final ScrollController _scroll = ScrollController();
  List<GlobalKey> _keys = [];
  int? _hovered;
  int? _pressed;
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;

  int get _selected =>
      widget.tabs.indexWhere((tab) => tab.value == widget.value);

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didUpdateWidget(Tabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (widget.value != oldWidget.value) _reveal();
  }

  /// One key per tab, kept as long as the count holds — they're what
  /// [Scrollable.ensureVisible] needs to find a tab that has scrolled off.
  void _syncKeys() {
    if (_keys.length == widget.tabs.length) return;
    _keys = [for (var i = 0; i < widget.tabs.length; i++) GlobalKey()];
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Bring the chosen tab into view, after the frame that moved it.
  void _reveal() {
    final index = _selected;
    if (index < 0 || index >= _keys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keys[index].currentContext;
      if (context == null || !mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: (ThemeProvider.maybeOf(context) ?? const Theme()).motion.fast,
      );
    });
  }

  void _leave(int index) {
    if (_hovered == index) setState(() => _hovered = null);
  }

  void _choose(int index) {
    if (!_enabled || index < 0 || index >= widget.tabs.length) return;
    final tab = widget.tabs[index];
    if (!tab.enabled || tab.value == widget.value) return;
    widget.onChanged!(tab.value);
  }

  /// Moves the choice [by] tabs, stepping over disabled ones and stopping
  /// at the ends.
  void _step(int by) {
    if (!_enabled) return;
    final count = widget.tabs.length;
    var index = _selected < 0 ? (by > 0 ? -1 : count) : _selected;
    for (index += by; index >= 0 && index < count; index += by) {
      if (widget.tabs[index].enabled) {
        _choose(index);
        return;
      }
    }
  }

  void _toEnd({required bool last}) {
    if (!_enabled) return;
    final index = last
        ? widget.tabs.lastIndexWhere((tab) => tab.enabled)
        : widget.tabs.indexWhere((tab) => tab.enabled);
    if (index >= 0) _choose(index);
  }

  @override
  Widget build(BuildContext context) {
    // Asserted here rather than in the constructor: a list's length isn't a
    // constant expression, and a const tab strip is worth more than an
    // earlier complaint about an empty one.
    assert(widget.tabs.isNotEmpty, 'A tab strip needs tabs.');
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style ?? theme.widgets.tabs.resolve(widget.swatch);
    final selected = _selected;

    return Semantics(
      container: true,
      enabled: _enabled,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
          const SingleActivator(LogicalKeyboardKey.home): () =>
              _toEnd(last: false),
          const SingleActivator(LogicalKeyboardKey.end): () =>
              _toEnd(last: true),
        },
        child: FocusableActionDetector(
          enabled: _enabled,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          child: AnimatedOpacity(
            opacity: _enabled ? 1 : style.disabledOpacity,
            duration: theme.motion.fast,
            curve: theme.motion.move,
            child: SizedBox(
              height: style.height,
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: style.tabGap,
                  children: [
                    for (var i = 0; i < widget.tabs.length; i++)
                      _tab(theme, style, i, selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A wash lands *on* the fill, not instead of it — a fill-less variant
  /// grows one the moment it's touched, the way a ghost button does.
  static Color? _dress(Color? fill, Color? wash) => switch ((fill, wash)) {
    (final fill?, final wash?) => Color.alphaBlend(wash, fill),
    (final fill?, null) => fill,
    (null, final wash?) => wash,
    _ => null,
  };

  Widget _tab(Theme theme, TabsStyle style, int index, int selected) {
    final tab = widget.tabs[index];
    final live = _enabled && tab.enabled;
    final chosen = index == selected;
    final wash = !live
        ? null
        : _pressed == index
        ? style.pressed
        : _hovered == index
        ? style.hover
        : null;
    final textStyle = chosen ? style.selectedStyle : style.unselectedStyle;
    final surface = chosen ? style.selected : style.unselected;

    // A cross keeps its own box around the glyph, so a tab that has one
    // gives back half of that box on the trailing side. Otherwise the
    // padding is counted twice over and the cross sits adrift of the edge
    // it belongs to.
    final direction = Directionality.of(context);
    final pad = style.padding.resolve(direction);
    final trim = tab.onClose == null ? 0.0 : style.closeSize / 2;
    final padding = direction == TextDirection.rtl
        ? pad.copyWith(left: math.max(0, pad.left - trim))
        : pad.copyWith(right: math.max(0, pad.right - trim));

    return KeyedSubtree(
      key: _keys[index],
      child: Semantics(
        selected: chosen,
        enabled: live,
        inMutuallyExclusiveGroup: true,
        child: MouseRegion(
          cursor: live ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = index),
          onExit: (_) => _leave(index),
          child: GestureDetector(
            onTapDown: live ? (_) => setState(() => _pressed = index) : null,
            onTapCancel: live ? () => setState(() => _pressed = null) : null,
            onTap: live
                ? () {
                    setState(() => _pressed = null);
                    _choose(index);
                  }
                : null,
            child: AnimatedOpacity(
              opacity: tab.enabled ? 1 : style.disabledOpacity,
              duration: theme.motion.fast,
              curve: theme.motion.move,
              // The strip is one focus stop, so the ring goes round the tab
              // the arrows would move away from.
              child: FocusRing(
                visible: _focused && chosen && _enabled,
                color: style.ring,
                radius: style.radius,
                // Dressed in place rather than slid: tabs are as wide as
                // their words, so there is no one distance for a marker to
                // travel. The color crosses instead.
                child: AnimatedContainer(
                  duration: theme.motion.fast,
                  curve: theme.motion.move,
                  padding: padding,
                  decoration: BoxDecoration(
                    color: _dress(surface.fill, wash),
                    border: surface.border == null
                        ? null
                        : Border.all(
                            color: surface.border!,
                            width: theme.strokes.hairline,
                          ),
                    borderRadius: surface.radius,
                  ),
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
                          if (tab.icon != null) ...[
                            Icon(tab.icon),
                            SizedBox(width: style.gap),
                          ],
                          Center(child: tab.label),
                          if (tab.onClose != null) ...[
                            SizedBox(width: style.gap),
                            _Close(
                              style: style,
                              // Shown on the tab you're on and the one
                              // under the pointer; laid out either way, so
                              // the strip doesn't shuffle as the pointer
                              // crosses it.
                              showing: live && (chosen || _hovered == index),
                              color: textStyle.color,
                              duration: theme.motion.fast,
                              curve: theme.motion.move,
                              onPressed: live ? tab.onClose : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The button that shuts a tab: a cross that fades in rather than one that
/// appears, and holds its place whether or not it's showing.
class _Close extends StatefulWidget {
  const _Close({
    required this.style,
    required this.showing,
    required this.color,
    required this.duration,
    required this.curve,
    required this.onPressed,
  });

  final TabsStyle style;
  final bool showing;
  final Color? color;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onPressed;

  @override
  State<_Close> createState() => _CloseState();
}

class _CloseState extends State<_Close> {
  bool _over = false;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style = widget.style;

    return AnimatedOpacity(
      opacity: widget.showing ? 1 : 0,
      duration: widget.duration,
      curve: widget.curve,
      child: MouseRegion(
        onEnter: (_) => setState(() => _over = true),
        onExit: (_) => setState(() => _over = false),
        child: GestureDetector(
          // The tab underneath takes every press this one doesn't.
          onTap: widget.showing ? widget.onPressed : null,
          child: Semantics(
            button: true,
            label: theme.labels.dismiss,
            child: Container(
              width: style.closeSize,
              height: style.closeSize,
              decoration: BoxDecoration(
                color: _over && widget.showing ? style.hover : null,
                borderRadius: BorderRadius.all(theme.radii.small.topLeft),
              ),
              child: Icon(
                theme.icons.close,
                size: style.closeIconSize,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
