import 'package:tomeui/tomeui.dart';

import '../knob.dart';
import '../story.dart';
import 'token_stories.dart';

/// Everything the playground knows how to preview.
List<StoryGroup> buildStories() => [
  tokenStories(),
  StoryGroup(name: 'Surface', stories: [_surfaceGallery()]),
  StoryGroup(name: 'Button', stories: [_button()]),
  StoryGroup(name: 'Checkbox', stories: [_checkbox()]),
  StoryGroup(name: 'Radio', stories: [_radio()]),
  StoryGroup(
    name: 'Switch',
    stories: [_switchStandalone(), _switchGrouped()],
  ),
  StoryGroup(name: 'Popover', stories: [_popover()]),
  StoryGroup(name: 'Select', stories: [_select(), _selectScrolling()]),
  StoryGroup(name: 'TextField', stories: [_textField(), _textFieldLong()]),
  StoryGroup(
    name: 'Text',
    stories: [_typeScale(), _semanticText(), _kicker()],
  ),
  StoryGroup(name: 'Link', stories: [_link()]),
  StoryGroup(name: 'CodeText', stories: [_codeText()]),
  StoryGroup(name: 'Menu', stories: [_menu(), _contextMenu()]),
  StoryGroup(name: 'Tooltip', stories: [_tooltip()]),
  StoryGroup(name: 'Placeholder', stories: [_placeholder()]),
];

Story _checkbox() {
  final checked = BoolKnob('Checked', true);
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.solid,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Checkbox',
    knobs: [checked, variant, swatch, disabled],
    // The value knob is two-way: clicking the canvas checkbox moves the
    // switch in the panel, and vice versa.
    builder: (_) => Checkbox(
      value: checked.value,
      onChanged: disabled.value ? null : (value) => checked.value = value,
      label: const Text('Ship the biscuit ration'),
      variant: variant.value,
      swatch: swatch.value,
    ),
  );
}

Story _radio() {
  const options = ['Hardtack', 'Salt pork', 'Grog'];
  final chosen = ListKnob<String>(
    'Chosen',
    options.first,
    options: options,
  );
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.solid,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Radio',
    knobs: [chosen, variant, swatch, disabled],
    // The knob is the group's value, so the panel and the canvas are two
    // views of one choice.
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return RadioGroup<String>(
        value: chosen.value,
        onChanged: disabled.value ? null : (value) => chosen.value = value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final option in options)
              Padding(
                padding: EdgeInsets.only(bottom: theme.space.x3),
                child: RadioButton(
                  value: option,
                  label: Text(option),
                  variant: variant.value,
                  swatch: swatch.value,
                ),
              ),
          ],
        ),
      );
    },
  );
}

Story _switchStandalone() {
  final on = BoolKnob('On', true);
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.solid,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Standalone',
    knobs: [on, variant, swatch, disabled],
    // The lambda's type is spelled out because a ternary gives inference
    // nothing to read T from on the null branch.
    builder: (_) => Switch(
      value: on.value,
      onChanged: disabled.value ? null : (bool value) => on.value = value,
      label: const Text('Light the lantern'),
      variant: variant.value,
      swatch: swatch.value,
    ),
  );
}

/// The same widget, exclusive: a SwitchGroup above makes each switch one of
/// several rather than its own yes or no.
Story _switchGrouped() {
  const watches = ['Morning', 'Forenoon', 'Dog'];
  final chosen = ListKnob<String>('On watch', watches.first, options: watches);
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.solid,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'In a group',
    knobs: [chosen, variant, swatch, disabled],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return SwitchGroup<String>(
        value: chosen.value,
        onChanged: disabled.value ? null : (value) => chosen.value = value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final watch in watches)
              Padding(
                padding: EdgeInsets.only(bottom: theme.space.x3),
                child: Switch(
                  value: watch,
                  label: Text(watch),
                  variant: variant.value,
                  swatch: swatch.value,
                ),
              ),
          ],
        ),
      );
    },
  );
}

const _watches = ['Morning', 'Forenoon', 'Afternoon', 'Dog', 'First'];

Story _select() {
  final chosen = ListKnob<String?>(
    'Value',
    null,
    options: [null, ..._watches],
    describe: (option) => option ?? 'nothing',
  );
  final side = ListKnob<PopoverSide>(
    'Side',
    PopoverSide.bottom,
    options: PopoverSide.values,
    describe: (option) => option.name,
  );
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.outline,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Select',
    knobs: [chosen, side, variant, swatch, disabled],
    builder: (_) => Select<String>(
      value: chosen.value,
      side: side.value,
      variant: variant.value,
      swatch: swatch.value,
      placeholder: const Text('Pick a watch'),
      onChanged: disabled.value
          ? null
          : (String value) => chosen.value = value,
      options: [
        for (final watch in _watches)
          SelectOption(value: watch, label: Text(watch)),
      ],
    ),
  );
}

/// Proof the open list follows its trigger: scroll the canvas with the list
/// down, and the panel rides along until the trigger leaves the view.
Story _selectScrolling() {
  final chosen = ListKnob<String?>(
    'Value',
    _watches.first,
    options: [null, ..._watches],
    describe: (option) => option ?? 'nothing',
  );

  return Story(
    name: 'In a scroll view',
    knobs: [chosen],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      // Placeholders hug their child under a ListView's loose constraints,
      // so the fillers say how tall they are — enough of them to actually
      // push the select up and off the top.
      Widget filler(int n) => Padding(
        padding: EdgeInsets.only(bottom: theme.space.x4),
        child: SizedBox(
          height: 180,
          child: Placeholder(child: Text('Filler $n')),
        ),
      );

      return ListView(
        padding: EdgeInsets.all(theme.space.x6),
        children: [
          for (var i = 1; i <= 3; i++) filler(i),
          Select<String>(
            value: chosen.value,
            placeholder: const Text('Pick a watch'),
            onChanged: (String value) => chosen.value = value,
            options: [
              for (final watch in _watches)
                SelectOption(value: watch, label: Text(watch)),
            ],
          ),
          SizedBox(height: theme.space.x4),
          for (var i = 4; i <= 9; i++) filler(i),
        ],
      );
    },
  );
}

Story _popover() {
  final open = BoolKnob('Open', true);
  final side = ListKnob<PopoverSide>(
    'Side',
    PopoverSide.bottom,
    options: PopoverSide.values,
    describe: (option) => option.name,
  );
  final align = ListKnob<PopoverAlign>(
    'Align',
    PopoverAlign.center,
    options: PopoverAlign.values,
    describe: (option) => option.name,
  );
  final barrier = BoolKnob('Barrier', true);

  return Story(
    name: 'Popover',
    knobs: [open, side, align, barrier],
    // Drag the canvas story near an edge to watch it flip and slide.
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return Popover(
        open: open.value,
        side: side.value,
        align: align.value,
        barrier: barrier.value,
        onDismiss: () => open.value = false,
        anchor: Button(
          onPressed: () => open.value = !open.value,
          center: const Text('Options'),
        ),
        content: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anchored, and kept on screen.'),
            SizedBox(height: theme.space.x2),
            Text(
              'Escape or a tap outside asks to close.',
              style: theme.typography.bodySmall,
            ),
          ],
        ),
      );
    },
  );
}

Story _tooltip() {
  final side = ListKnob<PopoverSide>(
    'Side',
    PopoverSide.top,
    options: PopoverSide.values,
    describe: (option) => option.name,
  );
  final align = ListKnob<PopoverAlign>(
    'Align',
    PopoverAlign.center,
    options: PopoverAlign.values,
    describe: (option) => option.name,
  );
  final message = StringKnob('Message', 'Weigh anchor and make sail');

  return Story(
    name: 'Tooltip',
    knobs: [side, align, message],
    builder: (context) => Tooltip(
      side: side.value,
      align: align.value,
      message: Text(message.value),
      child: Button(onPressed: () {}, center: const Text('Hover me')),
    ),
  );
}

Story _button() {
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.solid,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final label = StringKnob('Label', 'Save changes');
  final leading = BoolKnob('Leading icon', false);
  final disabled = BoolKnob('Disabled', false);

  return Story(
    name: 'Button',
    knobs: [variant, swatch, label, leading, disabled],
    builder: (context) => Button(
      onPressed: disabled.value ? null : () {},
      variant: variant.value,
      swatch: swatch.value,
      leading: leading.value
          ? Icon(ThemeProvider.of(context).icons.info)
          : null,
      center: Text(label.value),
    ),
  );
}

Story _surfaceGallery() => Story(
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

Story _placeholder() {
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.neutral,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final label = StringKnob('Label', 'Drop here');
  final bounded = BoolKnob('Fill a 320×200 box', true);
  final padding = DoubleKnob('Padding', 12, max: 48);

  return Story(
    name: 'Placeholder',
    knobs: [swatch, label, bounded, padding],
    builder: (_) {
      final placeholder = Placeholder(
        swatch: swatch.value,
        padding: EdgeInsets.all(padding.value),
        child: Text(label.value),
      );
      // Bounded shows the tight-constraints fill; unbounded shows the hug.
      return bounded.value
          ? SizedBox(width: 320, height: 200, child: placeholder)
          : placeholder;
    },
  );
}

/// The whole scale at once, in the order it steps down — the fastest way to
/// see whether a swapped [Typography] still reads as one system.
Story _typeScale() => Story(
  name: 'The scale',
  builder: (context) {
    final theme = ThemeProvider.of(context);
    Widget row(String role, Widget sample) => Padding(
      padding: EdgeInsets.only(bottom: theme.space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KickerText(role),
          SizedBox(height: theme.space.x1),
          sample,
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(theme.space.x6),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.sizes.contentNarrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            row('display', const DisplayText('Weigh anchor')),
            row('headline', const HeadlineText('Weigh anchor')),
            row('title', const TitleText('Weigh anchor')),
            row('subtitle', const SubtitleText('Weigh anchor')),
            row('body', const BodyText('Weigh anchor, and make sail.')),
            row(
              'bodySmall',
              const BodyText.small('Weigh anchor, and make sail.'),
            ),
            row('label', const LabelText('Weigh anchor')),
            row('caption', const CaptionText('Logged at eight bells')),
            row('code', const CodeText('flutter pub add tomeui')),
          ],
        ),
      ),
    );
  },
);

/// One line, every dial: the role it wears, how loudly, and on what.
Story _semanticText() {
  final role = ListKnob<TextRole>(
    'Role',
    TextRole.body,
    options: TextRole.values,
    describe: (option) => option.name,
  );
  final emphasis = ListKnob<TextEmphasis>(
    'Emphasis',
    TextEmphasis.full,
    options: TextEmphasis.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch?>(
    'Swatch',
    null,
    options: [null, ...SemanticSwatch.values],
    describe: (option) => option?.name ?? 'inherit the surface',
  );
  final variant = ListKnob<SurfaceVariant>(
    'On a surface',
    SurfaceVariant.ghost,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final words = StringKnob('Words', 'Everything aboard, counted.');

  return Story(
    name: 'One line',
    knobs: [role, emphasis, swatch, variant, words],
    // Sat on a surface deliberately: the point of the category is that
    // uncoloured text takes whatever the surface underneath it speaks.
    builder: (context) => Surface(
      variant: variant.value,
      padding: EdgeInsets.all(ThemeProvider.of(context).space.x4),
      child: _RoleText(
        words.value,
        role: role.value,
        emphasis: emphasis.value,
        swatch: swatch.value,
      ),
    ),
  );
}

/// The knob panel needs one widget that can wear any role; the app-facing
/// API is the named widgets — [BodyText], [TitleText], and the rest.
class _RoleText extends SemanticText {
  const _RoleText(
    super.data, {
    required super.role,
    super.emphasis,
    super.swatch,
  });
}

Story _kicker() {
  final label = StringKnob('Label', 'Danger zone');
  final emphasis = ListKnob<TextEmphasis>(
    'Emphasis',
    TextEmphasis.secondary,
    options: TextEmphasis.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'Kicker',
    knobs: [label, emphasis],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KickerText(label.value, emphasis: emphasis.value),
          SizedBox(height: theme.space.x2),
          const BodyText('What the kicker introduces.'),
        ],
      );
    },
  );
}

Story _link() {
  final role = ListKnob<TextRole>(
    'Role',
    TextRole.body,
    options: TextRole.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );
  final underline = ListKnob<LinkUnderline>(
    'Underline',
    LinkUnderline.hover,
    options: LinkUnderline.values,
    describe: (option) => option.name,
  );
  final external = BoolKnob('External', false);
  final disabled = BoolKnob('Disabled', false);
  final words = StringKnob('Words', 'the manifest');

  return Story(
    name: 'Link',
    knobs: [role, swatch, underline, external, disabled, words],
    builder: (context) {
      final theme = ThemeProvider.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Link(
            words.value,
            role: role.value,
            swatch: swatch.value,
            underline: underline.value,
            external: external.value,
            onPressed: disabled.value ? null : () {},
          ),
          SizedBox(height: theme.space.x4),
          // Beside its own size of body text, to check it sits on the line.
          const BodyText('A link takes the type of the words around it.'),
        ],
      );
    },
  );
}

Story _codeText() {
  final code = StringKnob('Code', 'flutter pub add tomeui');
  final copyable = BoolKnob('Copyable', true);
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.neutral,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'CodeText',
    knobs: [code, copyable, swatch],
    builder: (_) => CodeText(
      code.value,
      copyable: copyable.value,
      swatch: swatch.value,
    ),
  );
}

/// The entries a menu is made of, in one list: a section label, items with
/// icons and shortcut hints, a separator, a disabled row, and a dangerous
/// one wearing the error swatch.
List<MenuEntry> _menuEntries(BuildContext context, {required bool disabled}) {
  final icons = ThemeProvider.of(context).icons;
  return [
    const MenuSection(Text('Manifest')),
    MenuItem(
      label: const Text('Duplicate'),
      leading: Icon(icons.copy),
      trailing: const Text('⌘D'),
      onPressed: () {},
    ),
    MenuItem(
      label: const Text('Rename'),
      leading: Icon(icons.edit),
      onPressed: disabled ? null : () {},
    ),
    const MenuSeparator(),
    MenuItem(
      label: const Text('Delete'),
      leading: Icon(icons.delete),
      trailing: const Text('⌫'),
      swatch: SemanticSwatch.error,
      onPressed: () {},
    ),
  ];
}

Story _menu() {
  final open = BoolKnob('Open', true);
  final side = ListKnob<PopoverSide>(
    'Side',
    PopoverSide.bottom,
    options: PopoverSide.values,
    describe: (option) => option.name,
  );
  final align = ListKnob<PopoverAlign>(
    'Align',
    PopoverAlign.start,
    options: PopoverAlign.values,
    describe: (option) => option.name,
  );
  final disabled = BoolKnob('Disable Rename', false);

  return Story(
    name: 'Menu',
    knobs: [open, side, align, disabled],
    // The arrows walk it, Enter takes the row, Escape leaves — with the
    // canvas focused, none of that needs the mouse.
    builder: (context) => Menu(
      open: open.value,
      side: side.value,
      align: align.value,
      onDismiss: () => open.value = false,
      entries: _menuEntries(context, disabled: disabled.value),
      anchor: Button(
        onPressed: () => open.value = !open.value,
        center: const Text('Actions'),
      ),
    ),
  );
}

/// Right-click the panel — or long-press it on a touch screen — and the
/// menu opens at the pointer rather than at the panel's edge.
Story _contextMenu() => Story(
  name: 'On right-click',
  builder: (context) => SizedBox(
    width: 360,
    height: 220,
    child: ContextMenu(
      entries: _menuEntries(context, disabled: false),
      child: const Placeholder(child: Text('Right-click me')),
    ),
  ),
);

Story _textField() {
  final label = StringKnob('Label', 'Port of call');
  final placeholder = StringKnob('Placeholder', 'Valparaíso');
  final helper = StringKnob('Helper', 'Where the cargo leaves the ship.');
  final error = StringKnob('Error', '');
  final leading = BoolKnob('Leading icon', false);
  final obscure = BoolKnob('Obscured', false);
  final disabled = BoolKnob('Disabled', false);
  final variant = ListKnob<SurfaceVariant>(
    'Variant',
    SurfaceVariant.outline,
    options: SurfaceVariant.values,
    describe: (option) => option.name,
  );
  final swatch = ListKnob<SemanticSwatch>(
    'Swatch',
    SemanticSwatch.primary,
    options: SemanticSwatch.values,
    describe: (option) => option.name,
  );

  return Story(
    name: 'TextField',
    knobs: [
      label,
      placeholder,
      helper,
      error,
      leading,
      obscure,
      disabled,
      variant,
      swatch,
    ],
    // Type in it: the field owns its own text unless handed a controller.
    builder: (context) => SizedBox(
      width: 320,
      child: TextField(
        label: label.value.isEmpty ? null : Text(label.value),
        placeholder: placeholder.value.isEmpty
            ? null
            : Text(placeholder.value),
        helper: helper.value.isEmpty ? null : Text(helper.value),
        // Anything in the error knob turns the whole field, box and all.
        error: error.value.isEmpty ? null : Text(error.value),
        leading: leading.value
            ? Icon(ThemeProvider.of(context).icons.search)
            : null,
        obscureText: obscure.value,
        enabled: !disabled.value,
        variant: variant.value,
        swatch: swatch.value,
      ),
    ),
  );
}

/// The multi-line shape: the box grows with the text instead of scrolling
/// it past a fixed height.
Story _textFieldLong() {
  final lines = DoubleKnob('Min lines', 3, min: 1, max: 8);

  return Story(
    name: 'Multi-line',
    knobs: [lines],
    builder: (_) => SizedBox(
      width: 360,
      child: TextField(
        label: const Text('Log entry'),
        placeholder: const Text('Eight bells, wind freshening…'),
        minLines: lines.value.round(),
        maxLines: null,
      ),
    ),
  );
}
