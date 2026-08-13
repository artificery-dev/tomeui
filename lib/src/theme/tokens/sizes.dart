import 'package:flutter/widgets.dart';

/// The fixed dimensions the system names.
///
/// Icon sizes, control heights, and the handful of content widths that keep
/// dialogs and reading columns the same shape on every screen.
@immutable
class Sizes {
  const Sizes({
    this.iconSmall = 13,
    this.icon = 16,
    this.iconLarge = 20,
    this.iconExtraLarge = 24,
    this.controlCompact = 28,
    this.control = 36,
    this.touchTarget = 44,
    this.dialog = 520,
    this.contentNarrow = 640,
    this.content = 840,
  });

  // Icons, sized to sit beside the type scale.
  final double iconSmall;
  final double icon;
  final double iconLarge;
  final double iconExtraLarge;

  // Control heights: text fields, buttons, selects.
  final double controlCompact;
  final double control;

  /// The minimum hit target on touch screens. A control may *draw* smaller
  /// than this, but what it responds to may not.
  final double touchTarget;

  // Content widths.
  final double dialog;

  /// A comfortable single reading column.
  final double contentNarrow;

  /// The widest a content region grows before it centres instead.
  final double content;

  Sizes copyWith({
    double? iconSmall,
    double? icon,
    double? iconLarge,
    double? iconExtraLarge,
    double? controlCompact,
    double? control,
    double? touchTarget,
    double? dialog,
    double? contentNarrow,
    double? content,
  }) => Sizes(
    iconSmall: iconSmall ?? this.iconSmall,
    icon: icon ?? this.icon,
    iconLarge: iconLarge ?? this.iconLarge,
    iconExtraLarge: iconExtraLarge ?? this.iconExtraLarge,
    controlCompact: controlCompact ?? this.controlCompact,
    control: control ?? this.control,
    touchTarget: touchTarget ?? this.touchTarget,
    dialog: dialog ?? this.dialog,
    contentNarrow: contentNarrow ?? this.contentNarrow,
    content: content ?? this.content,
  );

  @override
  bool operator ==(Object other) =>
      other is Sizes &&
      other.iconSmall == iconSmall &&
      other.icon == icon &&
      other.iconLarge == iconLarge &&
      other.iconExtraLarge == iconExtraLarge &&
      other.controlCompact == controlCompact &&
      other.control == control &&
      other.touchTarget == touchTarget &&
      other.dialog == dialog &&
      other.contentNarrow == contentNarrow &&
      other.content == content;

  @override
  int get hashCode => Object.hash(
    iconSmall,
    icon,
    iconLarge,
    iconExtraLarge,
    controlCompact,
    control,
    touchTarget,
    dialog,
    contentNarrow,
    content,
  );
}
