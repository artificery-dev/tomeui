import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../stories/stories.dart';
import 'story.dart';
import 'theme_config.dart';
import 'widgets/inspector.dart';
import 'widgets/platform_controls.dart';
import 'widgets/platform_widget.dart';
import 'widgets/story_canvas.dart';
import 'widgets/story_list.dart';

/// The playground's three columns: stories, canvas, inspector.
class PlaygroundShell extends StatefulWidget {
  const PlaygroundShell({required this.config, super.key});

  /// Owned by [PlaygroundApp], which also feeds its brightness to the
  /// platform chrome.
  final ThemeConfig config;

  @override
  State<PlaygroundShell> createState() => _PlaygroundShellState();
}

class _PlaygroundShellState extends State<PlaygroundShell> {
  final List<StoryCategory> _categories = buildStories();

  late Story _selected = _categories.first.allStories.first;
  // Categories start open and groups closed: the catalogue reads as a
  // shelved list of widgets first, and their stories only when you ask.
  late final Set<String> _expanded = {
    for (final category in _categories) category.name,
  };
  int _tab = 0;

  @override
  void dispose() {
    for (final category in _categories) {
      for (final story in category.allStories) {
        for (final knob in story.knobs) {
          knob.dispose();
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider = platformDivider(context);
    final body = Row(
      children: [
        SizedBox(
          width: 240,
          child: StoryList(
            categories: _categories,
            selected: _selected,
            expanded: _expanded,
            onSelect: (story) => setState(() => _selected = story),
            onToggle: (key) => setState(
              () => _expanded.contains(key)
                  ? _expanded.remove(key)
                  : _expanded.add(key),
            ),
          ),
        ),
        Container(width: 1, color: divider),
        Expanded(child: StoryCanvas(story: _selected, config: widget.config)),
        Container(width: 1, color: divider),
        SizedBox(
          width: 320,
          child: Inspector(
            story: _selected,
            config: widget.config,
            tab: _tab,
            onTab: (tab) => setState(() => _tab = tab),
          ),
        ),
      ],
    );

    return PlatformWidget(
      cupertino: (_) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Tome Playground'),
        ),
        child: SafeArea(child: body),
      ),
      material: (_) => Scaffold(
        appBar: AppBar(title: const Text('Tome Playground')),
        body: body,
      ),
    );
  }
}
