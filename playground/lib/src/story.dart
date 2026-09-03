import 'package:flutter/widgets.dart';

import 'knob.dart';

/// One named preview of a widget: a builder plus the knobs that steer it.
class Story {
  Story({required this.name, required this.builder, this.knobs = const []});

  final String name;

  /// The inputs the Widget tab offers for this story. The builder closes
  /// over these and reads their values on every rebuild.
  final List<Knob<Object?>> knobs;

  final WidgetBuilder builder;

  /// Fires whenever any knob changes — what the canvas listens to.
  Listenable get listenable => Listenable.merge(knobs);
}

/// Every story a widget has, under the widget's name. One story renders as
/// a single row in the story list; more than one becomes a collapsible
/// group.
class StoryGroup {
  const StoryGroup({required this.name, required this.stories});

  final String name;
  final List<Story> stories;
}

/// A shelf of the catalog: the groups that belong together, named the way
/// `package:tomeui` shelves the widgets themselves. Groups sit in
/// alphabetical order within their category.
class StoryCategory {
  const StoryCategory({
    required this.name,
    this.stories = const [],
    this.groups = const [],
  });

  final String name;

  /// Stories belonging to the category itself rather than to any one widget
  /// — the theme's token previews, say. They sit above the groups, where a
  /// widget's row would.
  final List<Story> stories;

  final List<StoryGroup> groups;

  /// Everything under this shelf, loose stories first — what the shell walks
  /// to pick an opening story and to dispose the knobs.
  Iterable<Story> get allStories sync* {
    yield* stories;
    for (final group in groups) {
      yield* group.stories;
    }
  }
}
