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
