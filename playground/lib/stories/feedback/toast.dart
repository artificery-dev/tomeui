import 'package:tomeui/tomeui.dart';

import '../../src/knob.dart';
import '../../src/story.dart';

StoryGroup toastStories() => StoryGroup(name: 'Toast', stories: [_toast()]);

/// The story owns a [Toaster] of its own so the toasts land on the canvas
/// rather than over the whole playground.
Story _toast() {
  final message = StringKnob('Message', 'Manifest signed');
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.success,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final action = BoolKnob('Action', false);
  final dismissible = BoolKnob('Close button', true);
  final position = ListKnob<ToastPosition>(
    'Position',
    ToastPosition.bottomTrailing,
    options: ToastPosition.values,
    describe: (option) => option.name,
  );
  final undone = StringKnob('Last undo', '—');

  return Story(
    name: 'Toast',
    knobs: [message, swatch, action, dismissible, position, undone],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return Toaster(
        style: theme.widgets.toast.resolve().copyWith(
          position: position.value,
        ),
        child: Builder(
          builder: (context) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Button(
                  onPressed: () => showToast(
                    context,
                    message: Text(message.value),
                    swatch: swatch.value,
                    dismissible: dismissible.value,
                    action: action.value
                        ? (context, dismiss) => Button(
                            onPressed: () {
                              undone.value = message.value;
                              dismiss();
                            },
                            variant: SurfaceVariant.ghost,
                            swatch: SemanticSwatch.neutral,
                            center: const Text('Undo'),
                          )
                        : null,
                  ),
                  center: const Text('Say something'),
                ),
                const Spacing(SpaceStep.x4),
                // Press it four times: three show, the fourth waits.
                CaptionText('undone: ${undone.value}'),
              ],
            ),
          ),
        ),
      );
    },
  );
}
