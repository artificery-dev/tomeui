import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup sheetStories() => StoryGroup(name: 'Sheet', stories: [_sheet()]);

const _orders = ['Name', 'Date', 'Tonnage'];

/// Bring it in from an edge and throw it back: the bottom sheet takes a
/// downward fling, the side ones don't — there's nothing to throw them at.
Story _sheet() {
  final side = ListKnob<SheetSide>(
    'Side',
    SheetSide.bottom,
    options: SheetSide.values,
    describe: (option) => switch (option) {
      SheetSide.bottom => 'bottom — the phone’s',
      SheetSide.leading => 'leading',
      SheetSide.trailing => 'trailing — the desktop’s',
    },
  );
  final draggable = BoolKnob('Throwable', true);
  final dismissible = BoolKnob('Dismissible', true);
  final chosen = ListKnob<String>('Sorted by', _orders.first, options: _orders);

  return Story(
    name: 'Sheet',
    knobs: [side, draggable, dismissible, chosen],
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: Placeholder(child: BodyText('sorted by ${chosen.value}')),
        ),
        Center(
          child: Builder(
            builder: (context) => Button(
              onPressed: () => showSheet<String>(
                context,
                side: side.value,
                draggable: draggable.value,
                barrierDismissible: dismissible.value,
                builder: (context) => Sheet(
                  side: side.value,
                  title: const Text('Sort by'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final order in _orders) ...[
                        Button(
                          onPressed: () {
                            chosen.value = order;
                            Navigator.of(context).pop(order);
                          },
                          variant: order == chosen.value
                              ? SurfaceVariant.soft
                              : SurfaceVariant.ghost,
                          swatch: order == chosen.value
                              ? SemanticSwatch.primary
                              : SemanticSwatch.neutral,
                          center: Text(order),
                        ),
                        const Spacing(SpaceStep.x1),
                      ],
                    ],
                  ),
                ),
              ),
              center: const Text('Open the sheet'),
            ),
          ),
        ),
      ],
    ),
  );
}
