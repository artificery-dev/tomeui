import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../story.dart';
import 'platform_controls.dart';

/// The leading column: every widget's stories. A widget with one story is a
/// single row; more than one becomes a collapsible group.
class StoryList extends StatelessWidget {
  const StoryList({
    required this.groups,
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
    super.key,
  });

  final List<StoryGroup> groups;
  final Story selected;
  final Set<String> expanded;
  final ValueChanged<Story> onSelect;

  /// Collapses or expands the named group.
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (final group in groups)
        if (group.stories.length == 1)
          PlatformListTile(
            label: group.name,
            selected: identical(selected, group.stories.single),
            onTap: () => onSelect(group.stories.single),
          )
        else ...[
          PlatformListTile(
            label: group.name,
            trailing: _Chevron(open: expanded.contains(group.name)),
            onTap: () => onToggle(group.name),
          ),
          if (expanded.contains(group.name))
            for (final story in group.stories)
              PlatformListTile(
                label: story.name,
                indented: true,
                selected: identical(selected, story),
                onTap: () => onSelect(story),
              ),
        ],
    ],
  );
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final cupertino = Platform.isIOS || Platform.isMacOS;
    return Icon(
      open
          ? (cupertino ? CupertinoIcons.chevron_down : Icons.expand_more)
          : (cupertino ? CupertinoIcons.chevron_right : Icons.chevron_right),
      size: cupertino ? 16 : 20,
    );
  }
}
