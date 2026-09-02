import 'package:tomeui/tomeui.dart';

import 'intents.dart';

/// A grid the wheel drives, read the way a page is: left to right along a
/// row, then down to the next.
///
/// The same model as [WheelList] - one focus node, one selected index, the
/// wheel moving it and the centre button activating it - laid out in
/// [columns]. A detent moves one cell along; the fast-spin tier
/// ([JogIntent.page]) moves a whole row. The selected cell wears the
/// primary as a rounded outline, its glyph and words in the same colour -
/// the cursor as a frame rather than the bar a list's row wears. Rows
/// share one [cellExtent]; the width is the grid's share.
///
/// ```dart
/// WheelGrid(
///   columns: 3,
///   cellExtent: 58,
///   onActivate: open,
///   children: [for (final app in apps) AppTile(app)],
/// )
/// ```
class WheelGrid extends StatefulWidget {
  const WheelGrid({
    required this.children,
    required this.columns,
    required this.cellExtent,
    this.onActivate,
    this.onSelectionChanged,
    this.initialIndex = 0,
    this.autofocus = false,
    super.key,
  }) : assert(columns > 0);

  final List<Widget> children;

  /// Cells across.
  final int columns;

  /// One height for every row of cells.
  final double cellExtent;

  /// The centre button, spoken to the selected index.
  final ValueChanged<int>? onActivate;

  /// The wheel moved the selection. Not the activation.
  final ValueChanged<int>? onSelectionChanged;

  final int initialIndex;

  /// Take focus on appearing.
  final bool autofocus;

  @override
  State<WheelGrid> createState() => _WheelGridState();
}

class _WheelGridState extends State<WheelGrid> {
  late int _index = widget.children.isEmpty
      ? 0
      : widget.initialIndex.clamp(0, widget.children.length - 1);
  final _controller = ScrollController();

  int get _count => widget.children.length;

  @override
  void didUpdateWidget(WheelGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_count > 0 && _index >= _count) _index = _count - 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jog(JogIntent intent) {
    if (_count == 0) return;
    // A detent is a cell, a page-tier detent a row: reading order either
    // way, so the last cell of a row leads to the first of the next.
    final step = intent.page ? intent.amount * widget.columns : intent.amount;
    final next = (_index + step).clamp(0, _count - 1);
    if (next == _index) return;
    setState(() => _index = next);
    _reveal();
    widget.onSelectionChanged?.call(next);
  }

  /// Keep the selected row on screen, scrolling the least that shows it.
  void _reveal() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final top = (_index ~/ widget.columns) * widget.cellExtent;
    final bottom = top + widget.cellExtent;
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
            if (_count > 0) widget.onActivate?.call(_index);
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: widget.autofocus,
        debugLabel: 'WheelGrid',
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return GridView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.columns,
                mainAxisExtent: widget.cellExtent,
              ),
              itemCount: _count,
              itemBuilder: (context, index) => _DressedCell(
                selected: focused && index == _index,
                child: widget.children[index],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The selection dress: a rounded plate of the primary under the cell,
/// inset a little so neighbouring plates never touch, and the cell's
/// glyph and words in the primary's contrast colour.
class _DressedCell extends StatelessWidget {
  const _DressedCell({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!selected) return child;
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    return Padding(
      padding: EdgeInsets.all(theme.space.x1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.palette.primary.s500,
          borderRadius: theme.radii.medium,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: theme.palette.onPrimary),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: theme.palette.onPrimary),
            child: child,
          ),
        ),
      ),
    );
  }
}
