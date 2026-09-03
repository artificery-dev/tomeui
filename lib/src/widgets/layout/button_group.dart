import 'package:flutter/rendering.dart';
import 'package:tomeui/tomeui.dart';

/// A run of buttons that reads as one control.
///
/// The buttons abut: the corners on the group's outside stay rounded, the
/// ones facing a neighbor go square, and the hairline where two of them
/// meet is drawn once rather than twice. Each button keeps its own
/// [SurfaceVariant], [SemanticSwatch], and `onPressed` — a group is a shape,
/// not a choice, which is what separates it from a [SegmentedControl].
///
/// ```dart
/// ButtonGroup(
///   children: [
///     Button(onPressed: cut, center: const Text('Cut')),
///     Button(onPressed: copy, center: const Text('Copy')),
///     Button(onPressed: paste, center: const Text('Paste')),
///   ],
/// )
/// ```
///
/// [Axis.vertical] stacks the run instead, rounding the top and bottom of
/// the column.
class ButtonGroup extends StatelessWidget {
  const ButtonGroup({
    required this.children,
    this.axis = Axis.horizontal,
    super.key,
  });

  /// The buttons, in reading order. Anything that honors
  /// [ButtonGroupSlot] takes the shaping; anything else simply sits in the
  /// run.
  final List<Widget> children;

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    // In build, not the constructor: a list's length isn't a constant
    // expression, and `const ButtonGroup(...)` is worth keeping.
    assert(children.isNotEmpty, 'A button group needs buttons.');
    final theme = ThemeProvider.maybeOf(context) ?? const Theme();
    final last = children.length - 1;

    return Semantics(
      container: true,
      child: _Abut(
        direction: axis,
        // One hairline of overlap: where two outlined buttons meet, the
        // later one's edge lands on the earlier one's instead of beside it.
        overlap: theme.strokes.hairline,
        children: [
          for (final (index, child) in children.indexed)
            ButtonGroupSlot(
              axis: axis,
              first: index == 0,
              last: index == last,
              child: child,
            ),
        ],
      ),
    );
  }
}

/// What a [ButtonGroup] tells the button in one of its slots: which of that
/// button's corners are the group's outside, and which are interior seams
/// to square off.
///
/// A [Button] asks for the nearest one and reshapes itself, then hands its
/// own contents a [ButtonGroupSlot.solo] so a button nested deeper inside
/// isn't shaped by a group it doesn't belong to.
class ButtonGroupSlot extends InheritedWidget {
  const ButtonGroupSlot({
    required this.axis,
    required this.first,
    required this.last,
    required super.child,
    super.key,
  });

  /// A slot that shapes nothing — what a widget provides below itself once
  /// it has taken the shaping it was offered.
  const ButtonGroupSlot.solo({required super.child, super.key})
    : axis = Axis.horizontal,
      first = true,
      last = true;

  /// The direction the run travels.
  final Axis axis;

  /// Whether this is the first slot in the run, and so keeps the corners
  /// at the run's start.
  final bool first;

  /// Whether this is the last slot, keeping the corners at the run's end.
  final bool last;

  static ButtonGroupSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ButtonGroupSlot>();

  /// [radius] with the corners that face a neighbor squared off.
  BorderRadius shape(BorderRadius radius, TextDirection direction) {
    // The only slot in its run is a button like any other.
    if (first && last) return radius;

    if (axis == Axis.vertical) {
      return BorderRadius.only(
        topLeft: first ? radius.topLeft : Radius.zero,
        topRight: first ? radius.topRight : Radius.zero,
        bottomLeft: last ? radius.bottomLeft : Radius.zero,
        bottomRight: last ? radius.bottomRight : Radius.zero,
      );
    }

    final startKept = direction == TextDirection.rtl ? last : first;
    final endKept = direction == TextDirection.rtl ? first : last;
    return BorderRadius.only(
      topLeft: startKept ? radius.topLeft : Radius.zero,
      bottomLeft: startKept ? radius.bottomLeft : Radius.zero,
      topRight: endKept ? radius.topRight : Radius.zero,
      bottomRight: endKept ? radius.bottomRight : Radius.zero,
    );
  }

  @override
  bool updateShouldNotify(ButtonGroupSlot oldWidget) =>
      oldWidget.axis != axis ||
      oldWidget.first != first ||
      oldWidget.last != last;
}

/// Lays its children in a run, each one overlapping the last by [overlap]
/// so a shared edge is drawn once. Sizes to the run, and never stretches a
/// child across it.
class _Abut extends MultiChildRenderObjectWidget {
  const _Abut({
    required this.direction,
    required this.overlap,
    required super.children,
  });

  final Axis direction;
  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAbut(direction, overlap);

  @override
  void updateRenderObject(BuildContext context, _RenderAbut renderObject) {
    renderObject
      ..direction = direction
      ..overlap = overlap;
  }
}

class _AbutParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderAbut extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AbutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AbutParentData> {
  _RenderAbut(this._direction, this._overlap);

  Axis _direction;
  set direction(Axis value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  double _overlap;
  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  bool get _horizontal => _direction == Axis.horizontal;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _AbutParentData) {
      child.parentData = _AbutParentData();
    }
  }

  double _main(Size size) => _horizontal ? size.width : size.height;
  double _cross(Size size) => _horizontal ? size.height : size.width;

  @override
  void performLayout() {
    // Loose along the run, and no wider across it than the group itself:
    // the children keep their own sizes, the way buttons do.
    final childConstraints = _horizontal
        ? BoxConstraints(maxHeight: constraints.maxHeight)
        : BoxConstraints(maxWidth: constraints.maxWidth);

    var main = 0.0;
    var cross = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      cross = cross > _cross(child.size) ? cross : _cross(child.size);
      child = childAfter(child);
    }

    child = firstChild;
    while (child != null) {
      final data = child.parentData! as _AbutParentData;
      final centerd = (cross - _cross(child.size)) / 2;
      data.offset = _horizontal ? Offset(main, centerd) : Offset(centerd, main);
      main += _main(child.size);
      if (childAfter(child) != null) main -= _overlap;
      child = childAfter(child);
    }

    size = constraints.constrain(
      _horizontal ? Size(main, cross) : Size(cross, main),
    );
  }

  /// The run's own extent: every child, less an overlap per seam.
  double _mainIntrinsic(double Function(RenderBox child) measure) {
    var total = 0.0;
    var child = firstChild;
    while (child != null) {
      total += measure(child);
      if (childAfter(child) != null) total -= _overlap;
      child = childAfter(child);
    }
    return total;
  }

  double _crossIntrinsic(double Function(RenderBox child) measure) {
    var largest = 0.0;
    var child = firstChild;
    while (child != null) {
      final measured = measure(child);
      largest = largest > measured ? largest : measured;
      child = childAfter(child);
    }
    return largest;
  }

  @override
  double computeMinIntrinsicWidth(double height) => _horizontal
      ? _mainIntrinsic((child) => child.getMinIntrinsicWidth(height))
      : _crossIntrinsic((child) => child.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) => _horizontal
      ? _mainIntrinsic((child) => child.getMaxIntrinsicWidth(height))
      : _crossIntrinsic((child) => child.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) => _horizontal
      ? _crossIntrinsic((child) => child.getMinIntrinsicHeight(width))
      : _mainIntrinsic((child) => child.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) => _horizontal
      ? _crossIntrinsic((child) => child.getMaxIntrinsicHeight(width))
      : _mainIntrinsic((child) => child.getMaxIntrinsicHeight(width));

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
