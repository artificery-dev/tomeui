import 'package:flutter/widgets.dart';
import 'package:tomeui/tomeui.dart' as tome;

import '../knob.dart';
import '../story.dart';
import '../theme_config.dart';
import 'platform_controls.dart';

/// The trailing column: a Widget tab of knobs for the current story, and an
/// App tab of global theme controls.
class Inspector extends StatelessWidget {
  const Inspector({
    required this.story,
    required this.config,
    required this.tab,
    required this.onTab,
    super.key,
  });

  final Story story;
  final ThemeConfig config;
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([config, story.listenable]),
    builder: (context, _) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: PlatformTabSwitch(
            labels: const ['Widget', 'App'],
            index: tab,
            onChanged: onTab,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: tab == 0 ? _knobRows(context) : _appRows(context),
          ),
        ),
      ],
    ),
  );

  List<Widget> _knobRows(BuildContext context) {
    if (story.knobs.isEmpty) {
      return const [Text('This story has no knobs.')];
    }
    return [for (final knob in story.knobs) _KnobRow(knob, key: ObjectKey(knob))];
  }

  List<Widget> _appRows(BuildContext context) => [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Text('Dark mode')),
          PlatformSwitch(
            value: config.brightness == Brightness.dark,
            onChanged: (dark) => config.brightness = dark
                ? Brightness.dark
                : Brightness.light,
          ),
        ],
      ),
    ),
    for (final role in tome.SemanticSwatch.values)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role.name),
            const SizedBox(height: 2),
            PlatformDropdown<String>(
              items: namedSwatches.keys.toList(),
              value: _swatchName(config[role]),
              onChanged: (name) => config.setSwatch(role, namedSwatches[name]!),
              itemBuilder: (context, name) => Row(
                children: [
                  _SwatchChip(swatch: namedSwatches[name]!),
                  const SizedBox(width: 8),
                  Text(name),
                ],
              ),
            ),
          ],
        ),
      ),
  ];

  /// The display name of a configured swatch — always one of
  /// [namedSwatches], since that's all the dropdowns offer.
  String _swatchName(tome.Swatch swatch) => namedSwatches.entries
      .firstWhere((entry) => entry.value == swatch)
      .key;
}

/// One knob, rendered as the control its type calls for.
class _KnobRow extends StatelessWidget {
  const _KnobRow(this.knob, {super.key});

  final Knob<Object?> knob;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: switch (knob) {
      BoolKnob knob => Row(
        children: [
          Expanded(child: Text(knob.label)),
          PlatformSwitch(
            value: knob.value,
            onChanged: (value) => knob.value = value,
          ),
        ],
      ),
      DoubleKnob knob => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(knob.label)),
              Text(knob.value.toStringAsFixed(0)),
            ],
          ),
          PlatformSlider(
            value: knob.value,
            min: knob.min,
            max: knob.max,
            onChanged: (value) => knob.value = value,
          ),
        ],
      ),
      StringKnob knob => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(knob.label),
          const SizedBox(height: 6),
          PlatformTextField(
            value: knob.value,
            onChanged: (value) => knob.value = value,
          ),
        ],
      ),
      ListKnob<Object?> knob => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(knob.label),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in knob.options)
                _Pill(
                  label: knob.describeOption(option),
                  selected: knob.value == option,
                  onTap: () => knob.value = option,
                ),
            ],
          ),
        ],
      ),
    },
  );
}

/// A tappable choice in a select knob.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = platformAccent(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accent : null,
          border: Border.all(color: selected ? accent : platformDivider(context)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: selected
              ? TextStyle(color: tome.Swatch.zinc.s0)
              : DefaultTextStyle.of(context).style,
        ),
      ),
    );
  }
}

/// The colour sample beside a swatch's name in the App tab's dropdowns.
class _SwatchChip extends StatelessWidget {
  const _SwatchChip({required this.swatch});

  final tome.Swatch swatch;

  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: swatch.s500,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: platformDivider(context)),
    ),
  );
}
