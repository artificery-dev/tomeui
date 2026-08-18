import 'package:tomeui/tomeui.dart';

import '../../src/story.dart';

/// Every variant against every swatch, so a palette change can be judged
/// as one grid rather than one widget at a time.
StoryGroup surfaceStories() =>
    StoryGroup(name: 'Surface', stories: [_gallery()]);

Story _gallery() => Story(
  name: 'Gallery',
  builder: (_) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final variant in SurfaceVariant.values) ...[
            Text(variant.name),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final swatch in SemanticSwatch.values)
                  // Fixed cells: a border is part of the box, not around
                  // it, so every variant lands on the same grid.
                  SizedBox(
                    width: 104,
                    height: 40,
                    child: Surface(
                      variant: variant,
                      swatch: swatch,
                      child: Center(child: Text(swatch.name)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    ),
  ),
);
