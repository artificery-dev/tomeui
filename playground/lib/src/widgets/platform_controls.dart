import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'platform_widget.dart';

/// The ambient accent for playground chrome (selection pills, rings) —
/// resolved from whichever design language the shell is running in.
Color platformAccent(BuildContext context) => Platform.isIOS || Platform.isMacOS
    ? CupertinoTheme.of(context).primaryColor
    : Theme.of(context).colorScheme.primary;

/// The hairline between the shell's columns.
Color platformDivider(BuildContext context) => Platform.isIOS || Platform.isMacOS
    ? CupertinoColors.separator.resolveFrom(context)
    : Theme.of(context).dividerColor;

class PlatformSwitch extends StatelessWidget {
  const PlatformSwitch({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (_) => CupertinoSwitch(value: value, onChanged: onChanged),
    material: (_) => Switch(value: value, onChanged: onChanged),
  );
}

class PlatformSlider extends StatelessWidget {
  const PlatformSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (_) =>
        CupertinoSlider(value: value, min: min, max: max, onChanged: onChanged),
    material: (_) =>
        Slider(value: value, min: min, max: max, onChanged: onChanged),
  );
}

class PlatformTextField extends StatefulWidget {
  const PlatformTextField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<PlatformTextField> createState() => _PlatformTextFieldState();
}

class _PlatformTextFieldState extends State<PlatformTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (_) =>
        CupertinoTextField(controller: _controller, onChanged: widget.onChanged),
    material: (_) => TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
      ),
    ),
  );
}

/// One of a fixed list, chosen from a menu: Material's dropdown button, or
/// a Cupertino picker in a modal sheet.
class PlatformDropdown<T> extends StatelessWidget {
  const PlatformDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.itemBuilder,
    super.key,
  });

  final List<T> items;
  final T value;
  final ValueChanged<T> onChanged;

  /// How one option renders, both in the closed control and the open menu.
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) => PlatformWidget(
    material: (context) => DropdownButton<T>(
      value: value,
      isExpanded: true,
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: itemBuilder(context, item)),
      ],
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    ),
    cupertino: (context) => CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showPicker(context),
      child: Row(
        children: [
          Expanded(child: itemBuilder(context, value)),
          const Icon(CupertinoIcons.chevron_up_chevron_down, size: 16),
        ],
      ),
    ),
  );

  void _showPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            itemExtent: 32,
            scrollController: FixedExtentScrollController(
              initialItem: items.indexOf(value),
            ),
            onSelectedItemChanged: (index) => onChanged(items[index]),
            children: [
              for (final item in items)
                Center(child: itemBuilder(context, item)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Widget/App switch at the top of the inspector.
class PlatformTabSwitch extends StatelessWidget {
  const PlatformTabSwitch({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (_) => CupertinoSlidingSegmentedControl<int>(
      groupValue: index,
      children: {
        for (var i = 0; i < labels.length; i++) i: Text(labels[i]),
      },
      onValueChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
    material: (_) => SegmentedButton<int>(
      segments: [
        for (var i = 0; i < labels.length; i++)
          ButtonSegment(value: i, label: Text(labels[i])),
      ],
      selected: {index},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    ),
  );
}

/// A row in the story list: a story, or a category or group header with a
/// chevron.
class PlatformListTile extends StatelessWidget {
  const PlatformListTile({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.depth = 0,
    this.trailing,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  /// How far in the row sits: categories at 0, the widgets inside one at 1,
  /// and a widget's stories at 2.
  final int depth;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsetsDirectional.only(start: 16 + depth * 16, end: 16);
    return PlatformWidget(
      cupertino: (context) => CupertinoListTile(
        title: Text(label),
        padding: padding.add(const EdgeInsets.symmetric(vertical: 8)),
        backgroundColor: selected
            ? CupertinoColors.systemFill.resolveFrom(context)
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
      material: (_) => ListTile(
        title: Text(label),
        contentPadding: padding,
        dense: true,
        selected: selected,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
