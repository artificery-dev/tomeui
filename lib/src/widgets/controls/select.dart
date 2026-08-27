import 'dart:math' as math;

import 'package:tomeui/tomeui.dart';

import '../foundation/list_walk.dart';

/// One answer a [Select] offers.
@immutable
class SelectOption<T> {
  const SelectOption({
    required this.value,
    required this.label,
    this.leading,
    this.enabled = true,
  });

  /// What choosing this row means.
  final T value;

  /// How the row reads, open or closed — the trigger shows the chosen
  /// option's own label.
  final Widget label;

  /// An icon or swatch ahead of the label.
  final Widget? leading;

  final bool enabled;
}

/// One of several, chosen from a list that isn't there until you ask.
///
/// The split the plan calls for: the trigger is a control — a [Button] in
/// everything but name, with the chosen option's label in it — and the
/// floating list is a [Popover], which is what makes it flip, stay on
/// screen, and follow its anchor when the page scrolls.
///
/// Controlled, like the rest: choosing reports through [onChanged] and
/// paints nothing until the caller says so. A null [value] shows
/// [placeholder]; a null [onChanged] disables the whole control.
///
/// ```dart
/// Select<Watch>(
///   value: watch,
///   onChanged: (value) => setState(() => watch = value),
///   placeholder: const Text('Pick a watch'),
///   options: [
///     for (final w in Watch.values)
///       SelectOption(value: w, label: Text(w.name)),
///   ],
/// )
/// ```
class Select<T> extends StatefulWidget {
  const Select({
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
    this.side = PopoverSide.bottom,
    this.align = PopoverAlign.start,
    this.variant = SurfaceVariant.outline,
    this.swatch = SemanticSwatch.primary,
    this.style,
    super.key,
  });

  /// The current answer, or null for none yet.
  final T? value;

  final List<SelectOption<T>> options;

  /// Called with the chosen value. Null disables the control.
  final ValueChanged<T>? onChanged;

  /// What the trigger says when [value] is null.
  final Widget? placeholder;

  final PopoverSide side;
  final PopoverAlign align;

  final SurfaceVariant variant;

  /// The meaning the trigger and the chosen row wear.
  final SemanticSwatch swatch;

  /// The style to paint, bypassing the theme.
  final SelectStyle? style;

  @override
  State<Select<T>> createState() => _SelectState<T>();
}

class _SelectState<T> extends State<Select<T>> {
  bool _open = false;

  void _openList() {
    if (widget.onChanged == null) return;
    setState(() => _open = true);
  }

  void _close() {
    if (_open) setState(() => _open = false);
  }

  void _choose(int index) {
    final option = widget.options[index];
    if (!option.enabled) return;
    _close();
    widget.onChanged?.call(option.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final style =
        widget.style ??
        theme.widgets.select.resolve(widget.swatch, widget.variant);
    final enabled = widget.onChanged != null;
    final chosen = widget.options
        .where((option) => option.value == widget.value)
        .firstOrNull;

    final label = chosen != null
        ? chosen.label
        : DefaultTextStyle.merge(
            style: style.placeholder,
            child: widget.placeholder ?? const SizedBox.shrink(),
          );

    return Popover(
      open: _open,
      side: widget.side,
      align: widget.align,
      onDismiss: _close,
      // The list walks itself with the arrow keys, so it holds the
      // keyboard; Escape still carries up to the popover.
      takeFocus: false,
      // The list is never narrower than the control it drops from.
      style: theme.widgets.popover.resolve().copyWith(
        maxWidth: double.infinity,
      ),
      anchor: Button.custom(
        onPressed: enabled ? () => _open ? _close() : _openList() : null,
        style: style.trigger,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Every answer rides along invisibly, so the trigger is as
            // wide as its widest option and choosing never resizes it.
            Flexible(
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  for (final option in widget.options)
                    Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: option.label,
                    ),
                  if (widget.placeholder != null)
                    Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: widget.placeholder!,
                    ),
                  label,
                ],
              ),
            ),
            SizedBox(width: style.trigger.gap),
            Icon(theme.icons.chevronDown, size: theme.sizes.iconSmall),
          ],
        ),
      ),
      content: (context, anchor) => _list(context, theme, style, anchor),
    );
  }

  /// The open list: the walk owns the highlight and the keys, the rows
  /// stay this widget's business.
  Widget _list(
    BuildContext context,
    Theme theme,
    SelectStyle style,
    Rect anchor,
  ) => ListWalk(
    length: widget.options.length,
    enabledAt: (index) => widget.options[index].enabled,
    // Opens on the current answer, or on the first row that could be one.
    initial: widget.options.indexWhere((o) => o.value == widget.value),
    onActivate: _choose,
    builder: (context, highlight, highlightTo) => ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: anchor.width,
        maxWidth: math.max(anchor.width, theme.sizes.dialog),
        maxHeight: style.maxListHeight,
      ),
      // As wide as the widest row and no wider — without saying so, the
      // stretched column would take the whole allowance instead.
      child: IntrinsicWidth(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.options.length; i++)
                _Option(
                  option: widget.options[i],
                  style: style,
                  chosen: widget.options[i].value == widget.value,
                  highlighted: i == highlight,
                  tick: theme.icons.confirm,
                  onHover: () => highlightTo(i),
                  onTap: () => _choose(i),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// One row of an open [Select]: the label, and the tick that marks the
/// answer.
class _Option<T> extends StatelessWidget {
  const _Option({
    required this.option,
    required this.style,
    required this.chosen,
    required this.highlighted,
    required this.tick,
    required this.onHover,
    required this.onTap,
  });

  final SelectOption<T> option;
  final SelectStyle style;
  final bool chosen;
  final bool highlighted;
  final IconData tick;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    // The answer is marked in the swatch; the keyboard's place is a wash on
    // top, so a highlighted answer still reads as the answer.
    final background = chosen
        ? (highlighted
              ? Color.alphaBlend(style.highlight, style.selected)
              : style.selected)
        : (highlighted ? style.highlight : null);

    return ListWalkRow(
      enabled: option.enabled,
      background: background,
      radius: style.optionRadius,
      padding: style.optionPadding,
      onHover: onHover,
      onTap: onTap,
      child: Row(
        children: [
          if (option.leading != null) ...[
            option.leading!,
            SizedBox(width: style.optionGap),
          ],
          Expanded(child: option.label),
          SizedBox(width: style.optionGap),
          Opacity(
            // Always laid out, so choosing doesn't shuffle the rows.
            opacity: chosen ? 1 : 0,
            child: Icon(tick, size: theme.sizes.iconSmall),
          ),
        ],
      ),
    );
  }
}
