import 'package:tomeui/tomeui.dart';

/// The resolved values a [Divider] draws. The choosing happened in
/// [DividerResolver], at `theme.widgets.divider`.
@immutable
class DividerStyle {
  const DividerStyle({required this.color, this.thickness = 1});

  /// The line's colour at full strength — a faded divider reaches it only
  /// at its middle.
  final Color color;

  final double thickness;

  DividerStyle copyWith({Color? color, double? thickness}) =>
      DividerStyle(color: color ?? this.color, thickness: thickness ?? this.thickness);

  @override
  bool operator ==(Object other) =>
      other is DividerStyle &&
      other.color == color &&
      other.thickness == thickness;

  @override
  int get hashCode => Object.hash(color, thickness);
}
