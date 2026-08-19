import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../story.dart';
import 'platform_controls.dart';

/// The leading column: the catalogue, category by category. A widget with
/// one story is a single row; more than one becomes a collapsible group.
class StoryList extends StatelessWidget {
  const StoryList({
    required this.categories,
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
    super.key,
  });

  final List<StoryCategory> categories;
  final Story selected;

  /// The keys of the open rows: a category's name, and `category/group` for
  /// a group inside one — qualified because a group may share its
  /// category's name.
  final Set<String> expanded;

  final ValueChanged<Story> onSelect;

  /// Collapses or expands the row with the given key.
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (final category in categories) ...[
        PlatformListTile(
          label: category.name,
          trailing: _Chevron(open: expanded.contains(category.name)),
          onTap: () => onToggle(category.name),
        ),
        if (expanded.contains(category.name)) ...[
          for (final story in category.stories)
            PlatformListTile(
              label: story.name,
              depth: 1,
              selected: identical(selected, story),
              onTap: () => onSelect(story),
            ),
          for (final group in category.groups) ..._group(category, group),
        ],
      ],
    ],
  );

  List<Widget> _group(StoryCategory category, StoryGroup group) {
    if (group.stories.length == 1) {
      final story = group.stories.single;
      return [
        PlatformListTile(
          label: group.name,
          depth: 1,
          selected: identical(selected, story),
          onTap: () => onSelect(story),
        ),
      ];
    }

    final key = '${category.name}/${group.name}';
    final open = expanded.contains(key);
    return [
      PlatformListTile(
        label: group.name,
        depth: 1,
        trailing: _Chevron(open: open),
        onTap: () => onToggle(key),
      ),
      if (open)
        for (final story in group.stories)
          PlatformListTile(
            label: story.name,
            depth: 2,
            selected: identical(selected, story),
            onTap: () => onSelect(story),
          ),
    ];
  }
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
