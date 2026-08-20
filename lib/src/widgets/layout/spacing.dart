import 'package:flutter/rendering.dart';
import 'package:tomeui/tomeui.dart';

/// A gap off the [Space] scale, as a widget.
///
/// Row and Column have a `spacing` parameter and don't need this. A
/// ListView, a Stack, and a sliver don't, and this is what stands in for
/// the parameter they're missing:
///
/// ```dart
/// ListView(children: [Header(), Spacing(SpaceStep.x6), Body()])
/// ```
///
/// It measures along whichever axis it finds itself on — the direction of
/// an enclosing flex, or failing that whichever way the incoming
/// constraints leave room to grow — and takes no width or height across
/// it, so a gap never stretches the layout it sits in. Say [axis] outright
/// where neither answer would be right.
class Spacing extends StatelessWidget {
  const Spacing(this.step, {this.axis, super.key});

  final SpaceStep step;

  /// The axis to measure along, when the surroundings shouldn't decide it.
  final Axis? axis;

  @override
  Widget build(BuildContext context) {
    final space = (ThemeProvider.maybeOf(context) ?? const Theme()).space;
    return _Gap(extent: space.resolve(step), axis: axis);
  }
}

class _Gap extends LeafRenderObjectWidget {
  const _Gap({required this.extent, this.axis});

  final double extent;
  final Axis? axis;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGap(extent, axis);

  @override
  void updateRenderObject(BuildContext context, _RenderGap renderObject) {
    renderObject
      ..extent = extent
      ..axis = axis;
  }
}

class _RenderGap extends RenderBox {
  _RenderGap(this._extent, this._axis);

  double _extent;
  set extent(double value) {
    if (value == _extent) return;
    _extent = value;
    markNeedsLayout();
  }

  Axis? _axis;
  set axis(Axis? value) {
    if (value == _axis) return;
    _axis = value;
    markNeedsLayout();
  }

  /// The axis the gap knows about without measuring: what it was told, or
  /// the direction of the flex it sits in. Null means the surroundings
  /// haven't said, and only the constraints can answer.
  Axis? get _declared {
    if (_axis != null) return _axis;
    final parent = this.parent;
    return parent is RenderFlex ? parent.direction : null;
  }

  /// The axis to measure along. Failing a [_declared] one, the way the
  /// constraints leave open — a list hands its children a tight width and
  /// all the height they ask for, and that's the axis worth filling.
  Axis get _direction {
    final declared = _declared;
    if (declared != null) return declared;
    if (!constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
      return Axis.horizontal;
    }
    return Axis.vertical;
  }

  @override
  void performLayout() {
    size = constraints.constrain(
      _direction == Axis.vertical ? Size(0, _extent) : Size(_extent, 0),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _declared == Axis.horizontal ? _extent : 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      computeMinIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _declared == Axis.vertical ? _extent : 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);
}
