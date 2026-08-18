import 'package:tomeui/tomeui.dart';

import '../src/story.dart';

/// The Tokens pseudo-group: previews of the theme's raw material, one story
/// per token family. Everything reads the ambient theme, so the App tab's
/// changes show up here live.
StoryGroup tokenStories() => StoryGroup(
  name: 'Tokens',
  stories: [
    Story(name: 'Colors', builder: _colors),
    Story(name: 'Typography', builder: _typography),
    Story(name: 'Spacing', builder: _spacing),
    Story(name: 'Radii', builder: _radii),
    Story(name: 'Shadows', builder: _shadows),
    Story(name: 'Strokes', builder: _strokes),
    Story(name: 'Opacities', builder: _opacities),
  ],
);

const _rampStops = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950];

Widget _page(List<Widget> children) => SingleChildScrollView(
  padding: const EdgeInsets.all(24),
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  ),
);

/// A quiet annotation under a sample.
Widget _caption(Theme theme, String text) => Text(
  text,
  style: theme.typography.caption.copyWith(
    color: theme.palette.text.withValues(alpha: theme.opacities.secondary),
  ),
);

Widget _colors(BuildContext context) {
  final theme = ThemeProvider.of(context);
  final palette = theme.palette;
  return _page([
    // The stop ruler the ramps below line up under.
    Row(
      children: [
        for (final stop in _rampStops)
          Expanded(child: Center(child: _caption(theme, '$stop'))),
      ],
    ),
    SizedBox(height: theme.space.x2),
    for (final role in SemanticSwatch.values) ...[
      _caption(theme, role.name),
      SizedBox(height: theme.space.x1),
      ClipRRect(
        borderRadius: theme.radii.small,
        child: Row(
          children: [
            for (final stop in _rampStops)
              Expanded(
                child: Container(height: 36, color: palette.of(role)[stop]),
              ),
          ],
        ),
      ),
      SizedBox(height: theme.space.x3),
    ],
    SizedBox(height: theme.space.x2),
    _caption(theme, 'derived roles'),
    SizedBox(height: theme.space.x1),
    Wrap(
      spacing: theme.space.x2,
      runSpacing: theme.space.x2,
      children: [
        for (final (name, color) in [
          ('background', palette.background),
          ('surface', palette.surface),
          ('text', palette.text),
          ('divider', palette.divider),
          ('onPrimary', palette.onPrimary),
        ])
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: theme.radii.small,
                  border: Border.all(
                    color: palette.divider,
                    width: theme.strokes.hairline,
                  ),
                ),
              ),
              SizedBox(height: theme.space.x1),
              _caption(theme, name),
            ],
          ),
      ],
    ),
  ]);
}

Widget _typography(BuildContext context) {
  final theme = ThemeProvider.of(context);
  final styles = theme.typography;
  return _page([
    for (final (name, style) in [
      ('display', styles.display),
      ('headline', styles.headline),
      ('title', styles.title),
      ('subtitle', styles.subtitle),
      ('body', styles.body),
      ('bodySmall', styles.bodySmall),
      ('label', styles.label),
      ('caption', styles.caption),
      ('code', styles.code),
    ]) ...[
      Text('The quick brown fox jumps over the lazy dog', style: style),
      SizedBox(height: theme.space.x1),
      _caption(
        theme,
        '$name — ${style.fontSize}px · w${style.fontWeight!.value} · '
        '${style.height}× leading',
      ),
      SizedBox(height: theme.space.x4),
    ],
  ]);
}

Widget _spacing(BuildContext context) {
  final theme = ThemeProvider.of(context);
  final space = theme.space;
  final bar = theme.widgets.surface.resolve().fill!;
  return _page([
    for (final (name, value) in [
      ('x1', space.x1),
      ('x2', space.x2),
      ('x3', space.x3),
      ('x4', space.x4),
      ('x5', space.x5),
      ('x6', space.x6),
      ('x8', space.x8),
      ('x10', space.x10),
      ('x12', space.x12),
      ('x16', space.x16),
    ]) ...[
      Row(
        children: [
          SizedBox(width: 48, child: _caption(theme, name)),
          Container(
            width: value,
            height: 16,
            decoration: BoxDecoration(
              color: bar,
              borderRadius: theme.radii.none,
            ),
          ),
          SizedBox(width: theme.space.x2),
          _caption(theme, '${value.toStringAsFixed(0)}px'),
        ],
      ),
      SizedBox(height: theme.space.x2),
    ],
  ]);
}

Widget _radii(BuildContext context) {
  final theme = ThemeProvider.of(context);
  final radii = theme.radii;
  final style = theme.widgets.surface.resolve(
    SemanticSwatch.primary,
    SurfaceVariant.soft,
  );
  return _page([
    Wrap(
      spacing: theme.space.x3,
      runSpacing: theme.space.x3,
      children: [
        for (final (name, radius) in [
          ('none', radii.none),
          ('small', radii.small),
          ('medium', radii.medium),
          ('large', radii.large),
          ('extraLarge', radii.extraLarge),
          ('full', radii.full),
        ])
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 56,
                decoration: BoxDecoration(
                  color: style.fill,
                  borderRadius: radius,
                  border: Border.all(
                    color: theme.palette.divider,
                    width: theme.strokes.hairline,
                  ),
                ),
              ),
              SizedBox(height: theme.space.x1),
              _caption(theme, name),
            ],
          ),
      ],
    ),
  ]);
}

Widget _shadows(BuildContext context) {
  final theme = ThemeProvider.of(context);
  return _page([
    // The token doc means it: shadows whisper on dark surfaces. Flip the
    // App tab to light to see them speak.
    Wrap(
      spacing: theme.space.x6,
      runSpacing: theme.space.x6,
      children: [
        for (final (name, shadow) in [
          ('low', theme.shadows.low),
          ('medium', theme.shadows.medium),
          ('high', theme.shadows.high),
        ])
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.palette.surface,
                  borderRadius: theme.radii.medium,
                  boxShadow: shadow,
                ),
              ),
              SizedBox(height: theme.space.x2),
              _caption(theme, name),
            ],
          ),
      ],
    ),
  ]);
}

Widget _strokes(BuildContext context) {
  final theme = ThemeProvider.of(context);
  final accent = theme.widgets.surface.resolve().fill!;
  return _page([
    for (final (name, width, color) in [
      ('hairline', theme.strokes.hairline, theme.palette.divider),
      ('focus', theme.strokes.focus, accent),
    ]) ...[
      Row(
        children: [
          SizedBox(width: 64, child: _caption(theme, name)),
          Expanded(child: Container(height: width, color: color)),
          SizedBox(width: theme.space.x2),
          _caption(theme, '${width.toStringAsFixed(0)}px'),
        ],
      ),
      SizedBox(height: theme.space.x4),
    ],
  ]);
}

Widget _opacities(BuildContext context) {
  final theme = ThemeProvider.of(context);
  final opacities = theme.opacities;
  final text = theme.palette.text;
  return _page([
    _caption(theme, 'emphasis — foreground colour, stepped down'),
    SizedBox(height: theme.space.x2),
    for (final (name, value) in [
      ('primary', 1.0),
      ('secondary', opacities.secondary),
      ('tertiary', opacities.tertiary),
      ('disabled', opacities.disabled),
    ]) ...[
      Text(
        '$name — the quick brown fox (${value.toStringAsFixed(2)})',
        style: TextStyle(color: text.withValues(alpha: value)),
      ),
      SizedBox(height: theme.space.x2),
    ],
    SizedBox(height: theme.space.x4),
    _caption(theme, 'overlays — foreground over a surface'),
    SizedBox(height: theme.space.x2),
    Wrap(
      spacing: theme.space.x2,
      runSpacing: theme.space.x2,
      children: [
        for (final (name, value) in [
          ('hover', opacities.hover),
          ('pressed', opacities.pressed),
          ('focus', opacities.focus),
          ('dragged', opacities.dragged),
          ('divider', opacities.divider),
          ('scrim', opacities.scrim),
        ])
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.palette.surface,
                  borderRadius: theme.radii.small,
                  border: Border.all(
                    color: theme.palette.divider,
                    width: theme.strokes.hairline,
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  color: text.withValues(alpha: value),
                  borderRadius: theme.radii.small,
                ),
              ),
              SizedBox(height: theme.space.x1),
              _caption(theme, '$name ${value.toStringAsFixed(2)}'),
            ],
          ),
      ],
    ),
  ]);
}
